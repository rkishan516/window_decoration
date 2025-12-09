// Window Decoration Windows Plugin
// Native C++ implementation for frameless window support
// Handles WM_NCCALCSIZE to remove the black bar when title bar is hidden
// Handles WM_NCHITTEST to enable window resizing from edges and corners

#include <windows.h>
#include <windowsx.h>  // For GET_X_LPARAM, GET_Y_LPARAM
#include <dwmapi.h>
#include <commctrl.h>
#include <unordered_map>

#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "comctl32.lib")

// Per-window state
struct WindowState {
    WNDPROC originalWndProc;
    bool customFrameEnabled;
};

// Global state for multi-window support
static std::unordered_map<HWND, WindowState> g_window_states;
static HHOOK g_getmsg_hook = nullptr;
static int g_hook_ref_count = 0;
static bool g_was_on_resize_border = false;  // Track if we were on resize border

// Resize border width in pixels
static const int RESIZE_BORDER_WIDTH = 8;

// Get the resize frame thickness
static int GetResizeFrameThickness(HWND hwnd) {
    // SM_CXSIZEFRAME + SM_CXPADDEDBORDER gives us the resize border width
    int frame = GetSystemMetrics(SM_CXSIZEFRAME);
    int padding = GetSystemMetrics(SM_CXPADDEDBORDER);
    return frame + padding;
}

// Handle hit testing for resize borders
static LRESULT HandleNcHitTest(HWND hWnd, LPARAM lParam) {
    // Get mouse position in screen coordinates
    POINT mousePos = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };

    // Get window rect
    RECT windowRect;
    GetWindowRect(hWnd, &windowRect);

    // Check if window is maximized - no resize borders when maximized
    if (IsZoomed(hWnd)) {
        return HTCLIENT;
    }

    // Get the resize border thickness
    int borderWidth = GetResizeFrameThickness(hWnd);
    if (borderWidth < RESIZE_BORDER_WIDTH) {
        borderWidth = RESIZE_BORDER_WIDTH;
    }

    // Calculate positions relative to window
    int x = mousePos.x - windowRect.left;
    int y = mousePos.y - windowRect.top;
    int windowWidth = windowRect.right - windowRect.left;
    int windowHeight = windowRect.bottom - windowRect.top;

    // Check corners first (they take priority)
    // Use a larger corner zone for easier grabbing
    int cornerSize = borderWidth * 2;

    bool isLeft = x < borderWidth;
    bool isRight = x >= windowWidth - borderWidth;
    bool isTop = y < borderWidth;
    bool isBottom = y >= windowHeight - borderWidth;

    // Extended corner detection
    bool isNearLeft = x < cornerSize;
    bool isNearRight = x >= windowWidth - cornerSize;
    bool isNearTop = y < cornerSize;
    bool isNearBottom = y >= windowHeight - cornerSize;

    // Top-left corner
    if (isTop && isNearLeft) {
        return HTTOPLEFT;
    }
    if (isLeft && isNearTop) {
        return HTTOPLEFT;
    }
    // Top-right corner
    if (isTop && isNearRight) {
        return HTTOPRIGHT;
    }
    if (isRight && isNearTop) {
        return HTTOPRIGHT;
    }
    // Bottom-left corner
    if (isBottom && isNearLeft) {
        return HTBOTTOMLEFT;
    }
    if (isLeft && isNearBottom) {
        return HTBOTTOMLEFT;
    }
    // Bottom-right corner
    if (isBottom && isNearRight) {
        return HTBOTTOMRIGHT;
    }
    if (isRight && isNearBottom) {
        return HTBOTTOMRIGHT;
    }
    // Left edge
    if (isLeft) {
        return HTLEFT;
    }
    // Right edge
    if (isRight) {
        return HTRIGHT;
    }
    // Top edge
    if (isTop) {
        return HTTOP;
    }
    // Bottom edge
    if (isBottom) {
        return HTBOTTOM;
    }

    // Not on any border - client area
    return HTCLIENT;
}

// Get the DPI scale factor for the window
static double GetScaleFactor(HWND hwnd) {
    UINT dpi = GetDpiForWindow(hwnd);
    return static_cast<double>(dpi) / 96.0;
}

// Get the appropriate cursor for a hit test result
static HCURSOR GetCursorForHitTest(LRESULT hitTest) {
    switch (hitTest) {
        case HTLEFT:
        case HTRIGHT:
            return LoadCursor(nullptr, IDC_SIZEWE);
        case HTTOP:
        case HTBOTTOM:
            return LoadCursor(nullptr, IDC_SIZENS);
        case HTTOPLEFT:
        case HTBOTTOMRIGHT:
            return LoadCursor(nullptr, IDC_SIZENWSE);
        case HTTOPRIGHT:
        case HTBOTTOMLEFT:
            return LoadCursor(nullptr, IDC_SIZENESW);
        default:
            return nullptr;
    }
}

// Check if point is in resize border area (in screen coordinates)
static LRESULT HitTestResizeBorder(HWND hwnd, int screenX, int screenY) {
    if (IsZoomed(hwnd)) {
        return HTNOWHERE; // No resize when maximized
    }

    RECT windowRect;
    GetWindowRect(hwnd, &windowRect);

    int borderWidth = GetResizeFrameThickness(hwnd);
    if (borderWidth < RESIZE_BORDER_WIDTH) {
        borderWidth = RESIZE_BORDER_WIDTH;
    }

    int x = screenX - windowRect.left;
    int y = screenY - windowRect.top;
    int windowWidth = windowRect.right - windowRect.left;
    int windowHeight = windowRect.bottom - windowRect.top;

    bool isLeft = x < borderWidth;
    bool isRight = x >= windowWidth - borderWidth;
    bool isTop = y < borderWidth;
    bool isBottom = y >= windowHeight - borderWidth;

    // Corners
    if (isTop && isLeft) return HTTOPLEFT;
    if (isTop && isRight) return HTTOPRIGHT;
    if (isBottom && isLeft) return HTBOTTOMLEFT;
    if (isBottom && isRight) return HTBOTTOMRIGHT;

    // Edges
    if (isLeft) return HTLEFT;
    if (isRight) return HTRIGHT;
    if (isTop) return HTTOP;
    if (isBottom) return HTBOTTOM;

    return HTNOWHERE;
}

// Find the managed window for a given HWND (could be the window itself or its parent)
static HWND FindManagedWindow(HWND hwnd) {
    // Check if it's a managed window directly
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end() && it->second.customFrameEnabled) {
        return hwnd;
    }

    // Check if its parent is a managed window
    HWND parent = GetParent(hwnd);
    if (parent != nullptr) {
        auto parentIt = g_window_states.find(parent);
        if (parentIt != g_window_states.end() && parentIt->second.customFrameEnabled) {
            return parent;
        }
    }

    return nullptr;
}

// GetMessage hook to intercept messages before they're dispatched
LRESULT CALLBACK GetMsgProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0) {
        MSG* msg = reinterpret_cast<MSG*>(lParam);

        // Find which managed window this message belongs to
        HWND managedWindow = FindManagedWindow(msg->hwnd);

        if (managedWindow != nullptr) {
            // Handle cursor changes on mouse move
            if (msg->message == WM_MOUSEMOVE || msg->message == WM_NCMOUSEMOVE) {
                POINT pt;
                GetCursorPos(&pt);
                LRESULT hitTest = HitTestResizeBorder(managedWindow, pt.x, pt.y);

                if (hitTest != HTNOWHERE) {
                    // On resize border - show resize cursor
                    HCURSOR cursor = GetCursorForHitTest(hitTest);
                    if (cursor) {
                        SetCursor(cursor);
                    }
                    g_was_on_resize_border = true;
                } else if (g_was_on_resize_border) {
                    SetCursor(LoadCursor(nullptr, IDC_ARROW));
                    g_was_on_resize_border = false;
                }
            }

            // Handle mouse click to start resize
            if (msg->message == WM_LBUTTONDOWN) {
                POINT pt;
                GetCursorPos(&pt);
                LRESULT hitTest = HitTestResizeBorder(managedWindow, pt.x, pt.y);

                if (hitTest != HTNOWHERE) {
                    // Change the message to prevent Flutter from handling it
                    msg->message = WM_NULL;

                    // Start the resize operation
                    ReleaseCapture();
                    PostMessage(managedWindow, WM_NCLBUTTONDOWN, hitTest,
                               MAKELPARAM(pt.x, pt.y));
                }
            }
        }
    }

    return CallNextHookEx(g_getmsg_hook, nCode, wParam, lParam);
}

// Replacement window procedure that intercepts messages before Flutter's WndProc
LRESULT CALLBACK FramelessWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    // Look up this window's state
    auto it = g_window_states.find(hWnd);
    if (it == g_window_states.end()) {
        return DefWindowProc(hWnd, uMsg, wParam, lParam);
    }

    WindowState& state = it->second;

    if (state.customFrameEnabled) {
        // Handle WM_NCHITTEST for resize borders
        if (uMsg == WM_NCHITTEST) {
            // First let DWM handle it
            LRESULT dwmResult = 0;
            if (DwmDefWindowProc(hWnd, uMsg, wParam, lParam, &dwmResult)) {
                return dwmResult;
            }

            // Check for resize borders
            LRESULT hitTest = HandleNcHitTest(hWnd, lParam);
            if (hitTest != HTCLIENT) {
                return hitTest;
            }
            // Fall through to original handler for client area
        }

        // Handle WM_SETCURSOR to show resize cursors
        if (uMsg == WM_SETCURSOR) {
            WORD hitTest = LOWORD(lParam);
            HCURSOR cursor = GetCursorForHitTest(hitTest);
            if (cursor != nullptr) {
                SetCursor(cursor);
                return TRUE;
            }
        }

        // Handle WM_NCACTIVATE to prevent title bar flicker on focus/unfocus
        // When custom frame is enabled, we prevent Windows from drawing the default
        // non-client area by returning TRUE without calling DefWindowProc
        if (uMsg == WM_NCACTIVATE) {
            // Return TRUE to indicate we handled the activation change
            // The wParam indicates if window is being activated (TRUE) or deactivated (FALSE)
            // By not calling DefWindowProc, we prevent Windows from redrawing the non-client area
            // which causes the flickering effect on focus changes

            // However, we still need to update the internal activation state
            // Setting lParam to -1 tells Windows not to redraw the non-client area
            if (state.originalWndProc) {
                return CallWindowProc(state.originalWndProc, hWnd, uMsg, wParam, -1);
            }
            return TRUE;
        }

        // Handle WM_NCCALCSIZE to remove the title bar space completely
        if (uMsg == WM_NCCALCSIZE && wParam == TRUE) {
            NCCALCSIZE_PARAMS* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lParam);
            RECT originalRect = params->rgrc[0];

            if (IsZoomed(hWnd)) {
                double scaleFactor = GetScaleFactor(hWnd);
                int frameThickness = static_cast<int>(GetSystemMetrics(SM_CXFRAME) * scaleFactor);
                int borderPadding = static_cast<int>(GetSystemMetrics(SM_CXPADDEDBORDER) * scaleFactor);
                int totalPadding = frameThickness + borderPadding;

                params->rgrc[0].top = originalRect.top + totalPadding;
                params->rgrc[0].left = originalRect.left + totalPadding;
                params->rgrc[0].right = originalRect.right - totalPadding;
                params->rgrc[0].bottom = originalRect.bottom - totalPadding;
            } else {
                params->rgrc[0] = originalRect;
                params->rgrc[0].top -= 1;
            }

            return 0;
        }
    }

    if (state.originalWndProc) {
        return CallWindowProc(state.originalWndProc, hWnd, uMsg, wParam, lParam);
    }
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

// Enable or disable custom frameless window handling
// This function is exported and called from Dart via FFI
extern "C" __declspec(dllexport) void EnableCustomFrame(HWND hwnd, bool enable) {
    auto it = g_window_states.find(hwnd);

    if (enable) {
        // Check if this window is already registered
        if (it == g_window_states.end()) {
            // New window - register it
            WindowState state;
            state.customFrameEnabled = true;

            // Replace the window procedure with ours
            state.originalWndProc = reinterpret_cast<WNDPROC>(
                SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(FramelessWndProc))
            );

            g_window_states[hwnd] = state;

            // Install GetMessage hook if not already installed (shared across all windows)
            if (g_getmsg_hook == nullptr) {
                DWORD threadId = GetWindowThreadProcessId(hwnd, nullptr);
                g_getmsg_hook = SetWindowsHookEx(WH_GETMESSAGE, GetMsgProc,
                                                  nullptr, threadId);
            }
            g_hook_ref_count++;

            // Extend frame into client area with 1 pixel on top
            MARGINS margins = {0, 0, 1, 0};
            DwmExtendFrameIntoClientArea(hwnd, &margins);
        } else {
            // Window already registered, just enable custom frame
            it->second.customFrameEnabled = true;

            // Extend frame into client area with 1 pixel on top
            MARGINS margins = {0, 0, 1, 0};
            DwmExtendFrameIntoClientArea(hwnd, &margins);
        }
    } else {
        // Disable custom frame for this window
        if (it != g_window_states.end()) {
            it->second.customFrameEnabled = false;

            // Reset frame extension
            MARGINS margins = {0, 0, 0, 0};
            DwmExtendFrameIntoClientArea(hwnd, &margins);
        }
    }

    // Force Windows to recalculate the non-client area
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

// Check if custom frame is currently enabled for a specific window
extern "C" __declspec(dllexport) bool IsCustomFrameEnabled(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end()) {
        return it->second.customFrameEnabled;
    }
    return false;
}

// Restore the original window procedure (call when window is closed or plugin is unloaded)
extern "C" __declspec(dllexport) void RestoreWindowProc(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end()) {
        // Restore window procedure
        if (it->second.originalWndProc != nullptr) {
            SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(it->second.originalWndProc));
        }

        // Remove from map
        g_window_states.erase(it);

        // Decrement hook ref count and remove hook if no more windows
        g_hook_ref_count--;
        if (g_hook_ref_count <= 0 && g_getmsg_hook != nullptr) {
            UnhookWindowsHookEx(g_getmsg_hook);
            g_getmsg_hook = nullptr;
            g_hook_ref_count = 0;
        }
    }
}

// Start window resize operation from a specific edge
// edge values: 0=left, 1=right, 2=top, 3=bottom, 4=topLeft, 5=topRight, 6=bottomLeft, 7=bottomRight
extern "C" __declspec(dllexport) void StartResize(HWND hwnd, int edge) {
    if (IsZoomed(hwnd)) return; // Can't resize when maximized

    WPARAM resizeType;
    switch (edge) {
        case 0: resizeType = SC_SIZE | 0x0001; break; // WMSZ_LEFT
        case 1: resizeType = SC_SIZE | 0x0002; break; // WMSZ_RIGHT
        case 2: resizeType = SC_SIZE | 0x0003; break; // WMSZ_TOP
        case 3: resizeType = SC_SIZE | 0x0006; break; // WMSZ_BOTTOM
        case 4: resizeType = SC_SIZE | 0x0004; break; // WMSZ_TOPLEFT
        case 5: resizeType = SC_SIZE | 0x0005; break; // WMSZ_TOPRIGHT
        case 6: resizeType = SC_SIZE | 0x0007; break; // WMSZ_BOTTOMLEFT
        case 7: resizeType = SC_SIZE | 0x0008; break; // WMSZ_BOTTOMRIGHT
        default: return;
    }

    ReleaseCapture();
    SendMessage(hwnd, WM_SYSCOMMAND, resizeType, 0);
}

// Start window drag/move operation
extern "C" __declspec(dllexport) void StartDrag(HWND hwnd) {
    ReleaseCapture();
    SendMessage(hwnd, WM_SYSCOMMAND, SC_MOVE | 0x0002, 0);
}

// Get the resize border width
extern "C" __declspec(dllexport) int GetResizeBorderWidth() {
    return RESIZE_BORDER_WIDTH;
}
