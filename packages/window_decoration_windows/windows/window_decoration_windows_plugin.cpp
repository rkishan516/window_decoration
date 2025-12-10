// Window Decoration Windows Plugin
// Native C++ implementation for frameless window support
// Handles WM_NCCALCSIZE to remove the title bar while keeping window decorations
// Handles WM_NCHITTEST for resize borders, custom caption, and snap layout support

#include <windows.h>
#include <windowsx.h>  // For GET_X_LPARAM, GET_Y_LPARAM
#include <dwmapi.h>
#include <commctrl.h>
#include <unordered_map>
#include <VersionHelpers.h>

#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "comctl32.lib")

// Frame mode determines how the window frame is handled
enum class FrameMode {
    Normal,      // Standard Windows frame with title bar
    Hidden,      // Legacy hidden mode (borderless popup)
    CustomFrame  // Windows 11 style: no title bar but keeps decorations
};

// Caption button type for hit testing
enum class CaptionButton {
    None = 0,
    Minimize = 1,
    Maximize = 2,
    Close = 3
};

// Rectangle for caption button zones
struct ButtonRect {
    int left;
    int top;
    int right;
    int bottom;
};

// Per-window state
struct WindowState {
    WNDPROC originalWndProc;
    FrameMode frameMode;

    // Custom caption area (relative to client area, in pixels)
    int captionHeight;

    // Caption button zones (in client coordinates)
    ButtonRect minimizeButton;
    ButtonRect maximizeButton;
    ButtonRect closeButton;

    // Whether caption buttons are defined
    bool hasCaptionButtons;
};

// Global state for multi-window support
static std::unordered_map<HWND, WindowState> g_window_states;
static HHOOK g_getmsg_hook = nullptr;
static int g_hook_ref_count = 0;
static bool g_was_on_resize_border = false;

// Resize border width in pixels
static const int RESIZE_BORDER_WIDTH = 8;

// Default caption height if not specified
static const int DEFAULT_CAPTION_HEIGHT = 32;

// Get DPI for window
static UINT GetDpiForWindowSafe(HWND hwnd) {
    // Try GetDpiForWindow (Windows 10 1607+)
    typedef UINT (WINAPI *GetDpiForWindowFunc)(HWND);
    static GetDpiForWindowFunc pGetDpiForWindow = nullptr;
    static bool loaded = false;

    if (!loaded) {
        HMODULE user32 = GetModuleHandleW(L"user32.dll");
        if (user32) {
            pGetDpiForWindow = (GetDpiForWindowFunc)GetProcAddress(user32, "GetDpiForWindow");
        }
        loaded = true;
    }

    if (pGetDpiForWindow) {
        return pGetDpiForWindow(hwnd);
    }

    // Fallback: use DC
    HDC hdc = GetDC(hwnd);
    UINT dpi = GetDeviceCaps(hdc, LOGPIXELSX);
    ReleaseDC(hwnd, hdc);
    return dpi;
}

// Get system metrics for specific DPI
static int GetSystemMetricsForDpiSafe(int nIndex, UINT dpi) {
    // Try GetSystemMetricsForDpi (Windows 10 1607+)
    typedef int (WINAPI *GetSystemMetricsForDpiFunc)(int, UINT);
    static GetSystemMetricsForDpiFunc pGetSystemMetricsForDpi = nullptr;
    static bool loaded = false;

    if (!loaded) {
        HMODULE user32 = GetModuleHandleW(L"user32.dll");
        if (user32) {
            pGetSystemMetricsForDpi = (GetSystemMetricsForDpiFunc)GetProcAddress(user32, "GetSystemMetricsForDpi");
        }
        loaded = true;
    }

    if (pGetSystemMetricsForDpi) {
        return pGetSystemMetricsForDpi(nIndex, dpi);
    }

    // Fallback: use regular GetSystemMetrics and scale
    int value = GetSystemMetrics(nIndex);
    return MulDiv(value, dpi, 96);
}

// Check if running on Windows 11
static bool IsWindows11OrGreater() {
    OSVERSIONINFOEXW osvi = { sizeof(osvi), 0 };
    DWORDLONG conditionMask = 0;

    VER_SET_CONDITION(conditionMask, VER_MAJORVERSION, VER_GREATER_EQUAL);
    VER_SET_CONDITION(conditionMask, VER_MINORVERSION, VER_GREATER_EQUAL);
    VER_SET_CONDITION(conditionMask, VER_BUILDNUMBER, VER_GREATER_EQUAL);

    osvi.dwMajorVersion = 10;
    osvi.dwMinorVersion = 0;
    osvi.dwBuildNumber = 22000;  // Windows 11 starts at build 22000

    return VerifyVersionInfoW(&osvi, VER_MAJORVERSION | VER_MINORVERSION | VER_BUILDNUMBER, conditionMask) != FALSE;
}

// Get the resize frame thickness (DPI-aware)
static int GetResizeFrameThickness(HWND hwnd) {
    UINT dpi = GetDpiForWindowSafe(hwnd);
    int frame = GetSystemMetricsForDpiSafe(SM_CXFRAME, dpi);
    int padding = GetSystemMetricsForDpiSafe(SM_CXPADDEDBORDER, dpi);
    return frame + padding;
}

// Check if point is inside a rectangle
static bool PointInRect(int x, int y, const ButtonRect& rect) {
    return x >= rect.left && x < rect.right && y >= rect.top && y < rect.bottom;
}

// Handle hit testing for the custom frame mode (Windows 11 File Explorer style)
static LRESULT HandleCustomFrameHitTest(HWND hWnd, LPARAM lParam, const WindowState& state) {
    POINT mousePos = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };

    RECT windowRect;
    GetWindowRect(hWnd, &windowRect);

    UINT dpi = GetDpiForWindowSafe(hWnd);
    int frameX = GetSystemMetricsForDpiSafe(SM_CXFRAME, dpi);
    int frameY = GetSystemMetricsForDpiSafe(SM_CYFRAME, dpi);
    int padding = GetSystemMetricsForDpiSafe(SM_CXPADDEDBORDER, dpi);

    int borderWidth = frameX + padding;
    int borderHeight = frameY + padding;

    // Calculate position relative to window
    int x = mousePos.x - windowRect.left;
    int y = mousePos.y - windowRect.top;
    int windowWidth = windowRect.right - windowRect.left;
    int windowHeight = windowRect.bottom - windowRect.top;

    // Check if maximized - no resize borders when maximized
    bool isMaximized = IsZoomed(hWnd);

    if (!isMaximized) {
        // Check resize borders first
        bool isLeft = x < borderWidth;
        bool isRight = x >= windowWidth - borderWidth;
        bool isTop = y < borderHeight;
        bool isBottom = y >= windowHeight - borderHeight;

        // Corners have priority
        if (isTop && isLeft) return HTTOPLEFT;
        if (isTop && isRight) return HTTOPRIGHT;
        if (isBottom && isLeft) return HTBOTTOMLEFT;
        if (isBottom && isRight) return HTBOTTOMRIGHT;

        // Edges
        if (isLeft) return HTLEFT;
        if (isRight) return HTRIGHT;
        if (isBottom) return HTBOTTOM;

        // Top edge - this is special because it overlaps with caption area
        // Only report HTTOP at the very edge (a few pixels)
        if (y < borderHeight / 2) return HTTOP;
    }

    // Convert to client coordinates for caption area detection
    POINT clientPos = mousePos;
    ScreenToClient(hWnd, &clientPos);

    // Check caption button areas first
    if (state.hasCaptionButtons) {
        // Close button
        if (PointInRect(clientPos.x, clientPos.y, state.closeButton)) {
            return HTCLOSE;
        }

        // Maximize button - return HTMAXBUTTON for Windows 11 snap layout support
        if (PointInRect(clientPos.x, clientPos.y, state.maximizeButton)) {
            return HTMAXBUTTON;
        }

        // Minimize button
        if (PointInRect(clientPos.x, clientPos.y, state.minimizeButton)) {
            return HTMINBUTTON;
        }
    }

    // Check if in caption area (custom title bar region)
    int captionHeight = state.captionHeight > 0 ? state.captionHeight : DEFAULT_CAPTION_HEIGHT;

    // Scale caption height for DPI
    captionHeight = MulDiv(captionHeight, dpi, 96);

    // Account for the top border when not maximized
    int topOffset = isMaximized ? 0 : borderHeight;

    if (clientPos.y < captionHeight) {
        return HTCAPTION;
    }

    return HTCLIENT;
}

// Handle hit testing for legacy hidden mode (borderless)
static LRESULT HandleHiddenFrameHitTest(HWND hWnd, LPARAM lParam) {
    POINT mousePos = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };

    RECT windowRect;
    GetWindowRect(hWnd, &windowRect);

    // Check if window is maximized - no resize borders when maximized
    if (IsZoomed(hWnd)) {
        return HTCLIENT;
    }

    int borderWidth = GetResizeFrameThickness(hWnd);
    if (borderWidth < RESIZE_BORDER_WIDTH) {
        borderWidth = RESIZE_BORDER_WIDTH;
    }

    int x = mousePos.x - windowRect.left;
    int y = mousePos.y - windowRect.top;
    int windowWidth = windowRect.right - windowRect.left;
    int windowHeight = windowRect.bottom - windowRect.top;

    int cornerSize = borderWidth * 2;

    bool isLeft = x < borderWidth;
    bool isRight = x >= windowWidth - borderWidth;
    bool isTop = y < borderWidth;
    bool isBottom = y >= windowHeight - borderWidth;

    bool isNearLeft = x < cornerSize;
    bool isNearRight = x >= windowWidth - cornerSize;
    bool isNearTop = y < cornerSize;
    bool isNearBottom = y >= windowHeight - cornerSize;

    // Corners
    if (isTop && isNearLeft) return HTTOPLEFT;
    if (isLeft && isNearTop) return HTTOPLEFT;
    if (isTop && isNearRight) return HTTOPRIGHT;
    if (isRight && isNearTop) return HTTOPRIGHT;
    if (isBottom && isNearLeft) return HTBOTTOMLEFT;
    if (isLeft && isNearBottom) return HTBOTTOMLEFT;
    if (isBottom && isNearRight) return HTBOTTOMRIGHT;
    if (isRight && isNearBottom) return HTBOTTOMRIGHT;

    // Edges
    if (isLeft) return HTLEFT;
    if (isRight) return HTRIGHT;
    if (isTop) return HTTOP;
    if (isBottom) return HTBOTTOM;

    return HTCLIENT;
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
    auto it = g_window_states.find(hwnd);
    if (it == g_window_states.end()) return HTNOWHERE;

    const WindowState& state = it->second;

    if (state.frameMode == FrameMode::CustomFrame) {
        LPARAM lParam = MAKELPARAM(screenX, screenY);
        LRESULT hit = HandleCustomFrameHitTest(hwnd, lParam, state);
        if (hit != HTCLIENT && hit != HTCAPTION && hit != HTCLOSE &&
            hit != HTMAXBUTTON && hit != HTMINBUTTON) {
            return hit;
        }
        return HTNOWHERE;
    } else if (state.frameMode == FrameMode::Hidden) {
        LPARAM lParam = MAKELPARAM(screenX, screenY);
        LRESULT hit = HandleHiddenFrameHitTest(hwnd, lParam);
        if (hit != HTCLIENT) {
            return hit;
        }
    }

    return HTNOWHERE;
}

// Find the managed window for a given HWND
static HWND FindManagedWindow(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end() && it->second.frameMode != FrameMode::Normal) {
        return hwnd;
    }

    HWND parent = GetParent(hwnd);
    if (parent != nullptr) {
        auto parentIt = g_window_states.find(parent);
        if (parentIt != g_window_states.end() && parentIt->second.frameMode != FrameMode::Normal) {
            return parent;
        }
    }

    return nullptr;
}

// GetMessage hook to intercept messages before dispatch
LRESULT CALLBACK GetMsgProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0) {
        MSG* msg = reinterpret_cast<MSG*>(lParam);

        HWND managedWindow = FindManagedWindow(msg->hwnd);

        if (managedWindow != nullptr) {
            if (msg->message == WM_MOUSEMOVE || msg->message == WM_NCMOUSEMOVE) {
                POINT pt;
                GetCursorPos(&pt);
                LRESULT hitTest = HitTestResizeBorder(managedWindow, pt.x, pt.y);

                if (hitTest != HTNOWHERE) {
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

            if (msg->message == WM_LBUTTONDOWN) {
                POINT pt;
                GetCursorPos(&pt);
                LRESULT hitTest = HitTestResizeBorder(managedWindow, pt.x, pt.y);

                if (hitTest != HTNOWHERE) {
                    msg->message = WM_NULL;
                    ReleaseCapture();
                    PostMessage(managedWindow, WM_NCLBUTTONDOWN, hitTest, MAKELPARAM(pt.x, pt.y));
                }
            }
        }
    }

    return CallNextHookEx(g_getmsg_hook, nCode, wParam, lParam);
}

// Replacement window procedure
LRESULT CALLBACK CustomFrameWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    auto it = g_window_states.find(hWnd);
    if (it == g_window_states.end()) {
        return DefWindowProc(hWnd, uMsg, wParam, lParam);
    }

    WindowState& state = it->second;

    if (state.frameMode == FrameMode::CustomFrame) {
        // WM_NCCALCSIZE - This is the key to Windows 11 File Explorer style
        // We adjust the client area to remove the title bar while keeping borders
        if (uMsg == WM_NCCALCSIZE && wParam == TRUE) {
            NCCALCSIZE_PARAMS* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lParam);

            UINT dpi = GetDpiForWindowSafe(hWnd);
            int frameX = GetSystemMetricsForDpiSafe(SM_CXFRAME, dpi);
            int frameY = GetSystemMetricsForDpiSafe(SM_CYFRAME, dpi);
            int padding = GetSystemMetricsForDpiSafe(SM_CXPADDEDBORDER, dpi);

            // Adjust the client rectangle
            // Keep left, right, and bottom borders for resize
            // Remove the top border to eliminate title bar
            params->rgrc[0].left += frameX + padding;
            params->rgrc[0].right -= frameX + padding;
            params->rgrc[0].bottom -= frameY + padding;

            if (IsZoomed(hWnd)) {
                // When maximized, add top padding to prevent content going under taskbar
                params->rgrc[0].top += frameY + padding;
            } else {
                // When not maximized, we need a tiny top margin for the window border
                // On Windows 11, this is typically 1 pixel
                if (IsWindows11OrGreater()) {
                    // Windows 11 has a visible 1px top border that we want to keep
                    // Don't add anything to top - let DWM draw the border
                }
            }

            return 0;
        }

        // WM_NCHITTEST - Handle hit testing for custom frame
        if (uMsg == WM_NCHITTEST) {
            // Let DWM handle caption buttons first
            LRESULT dwmResult = 0;
            if (DwmDefWindowProc(hWnd, uMsg, wParam, lParam, &dwmResult)) {
                return dwmResult;
            }

            return HandleCustomFrameHitTest(hWnd, lParam, state);
        }

        // WM_NCACTIVATE - Prevent default non-client rendering
        if (uMsg == WM_NCACTIVATE) {
            // Return TRUE and set lParam to -1 to prevent non-client area redraw
            if (state.originalWndProc) {
                return CallWindowProc(state.originalWndProc, hWnd, uMsg, wParam, -1);
            }
            return TRUE;
        }

        // WM_SETCURSOR - Show appropriate cursor
        if (uMsg == WM_SETCURSOR) {
            WORD hitTest = LOWORD(lParam);
            HCURSOR cursor = GetCursorForHitTest(hitTest);
            if (cursor != nullptr) {
                SetCursor(cursor);
                return TRUE;
            }
        }

        // WM_NCLBUTTONDOWN on maximize button - show snap layout on Windows 11
        // Windows 11 automatically shows snap layout when HTMAXBUTTON is clicked

        // WM_CREATE - Force frame change
        if (uMsg == WM_CREATE) {
            RECT rcClient;
            GetWindowRect(hWnd, &rcClient);
            SetWindowPos(hWnd, nullptr, rcClient.left, rcClient.top,
                         rcClient.right - rcClient.left, rcClient.bottom - rcClient.top,
                         SWP_FRAMECHANGED | SWP_NOZORDER);
        }

        // WM_GETMINMAXINFO - Handle maximized window bounds while preserving min/max constraints
        if (uMsg == WM_GETMINMAXINFO) {
            // First, let the original WndProc (Flutter) set its min/max constraints
            LRESULT result = 0;
            if (state.originalWndProc) {
                result = CallWindowProc(state.originalWndProc, hWnd, uMsg, wParam, lParam);
            }

            MINMAXINFO* mmi = reinterpret_cast<MINMAXINFO*>(lParam);

            // Get the monitor this window is on
            HMONITOR monitor = MonitorFromWindow(hWnd, MONITOR_DEFAULTTONEAREST);
            MONITORINFO mi = { sizeof(mi) };
            if (GetMonitorInfo(monitor, &mi)) {
                // Only adjust the maximized position and size
                // This ensures the window doesn't go under the taskbar when maximized
                // The min/max tracking size constraints from Flutter are preserved
                mmi->ptMaxPosition.x = mi.rcWork.left - mi.rcMonitor.left;
                mmi->ptMaxPosition.y = mi.rcWork.top - mi.rcMonitor.top;
                mmi->ptMaxSize.x = mi.rcWork.right - mi.rcWork.left;
                mmi->ptMaxSize.y = mi.rcWork.bottom - mi.rcWork.top;
            }

            return result;
        }
    } else if (state.frameMode == FrameMode::Hidden) {
        // Legacy hidden mode handling (borderless popup)
        if (uMsg == WM_NCHITTEST) {
            LRESULT dwmResult = 0;
            if (DwmDefWindowProc(hWnd, uMsg, wParam, lParam, &dwmResult)) {
                return dwmResult;
            }

            LRESULT hitTest = HandleHiddenFrameHitTest(hWnd, lParam);
            if (hitTest != HTCLIENT) {
                return hitTest;
            }
        }

        if (uMsg == WM_SETCURSOR) {
            WORD hitTest = LOWORD(lParam);
            HCURSOR cursor = GetCursorForHitTest(hitTest);
            if (cursor != nullptr) {
                SetCursor(cursor);
                return TRUE;
            }
        }

        if (uMsg == WM_NCACTIVATE) {
            if (state.originalWndProc) {
                return CallWindowProc(state.originalWndProc, hWnd, uMsg, wParam, -1);
            }
            return TRUE;
        }

        if (uMsg == WM_NCCALCSIZE && wParam == TRUE) {
            NCCALCSIZE_PARAMS* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lParam);
            RECT originalRect = params->rgrc[0];

            if (IsZoomed(hWnd)) {
                UINT dpi = GetDpiForWindowSafe(hWnd);
                int frameThickness = GetSystemMetricsForDpiSafe(SM_CXFRAME, dpi);
                int borderPadding = GetSystemMetricsForDpiSafe(SM_CXPADDEDBORDER, dpi);
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

// ==========================================================================
// Exported Functions (called from Dart via FFI)
// ==========================================================================

// Enable custom frame mode (Windows 11 File Explorer style)
extern "C" __declspec(dllexport) void EnableCustomFrameMode(HWND hwnd, int captionHeight) {
    auto it = g_window_states.find(hwnd);

    if (it == g_window_states.end()) {
        WindowState state = {};
        state.frameMode = FrameMode::CustomFrame;
        state.captionHeight = captionHeight > 0 ? captionHeight : DEFAULT_CAPTION_HEIGHT;
        state.hasCaptionButtons = false;

        state.originalWndProc = reinterpret_cast<WNDPROC>(
            SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(CustomFrameWndProc))
        );

        g_window_states[hwnd] = state;

        if (g_getmsg_hook == nullptr) {
            DWORD threadId = GetWindowThreadProcessId(hwnd, nullptr);
            g_getmsg_hook = SetWindowsHookEx(WH_GETMESSAGE, GetMsgProc, nullptr, threadId);
        }
        g_hook_ref_count++;
    } else {
        it->second.frameMode = FrameMode::CustomFrame;
        it->second.captionHeight = captionHeight > 0 ? captionHeight : DEFAULT_CAPTION_HEIGHT;
    }

    // Extend frame into client area with -1 margins for proper DWM rendering
    MARGINS margins = {-1, -1, -1, -1};
    DwmExtendFrameIntoClientArea(hwnd, &margins);

    // Force frame change
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

// Set caption button zones for hit testing
extern "C" __declspec(dllexport) void SetCaptionButtonZones(
    HWND hwnd,
    int minLeft, int minTop, int minRight, int minBottom,
    int maxLeft, int maxTop, int maxRight, int maxBottom,
    int closeLeft, int closeTop, int closeRight, int closeBottom
) {
    auto it = g_window_states.find(hwnd);
    if (it == g_window_states.end()) return;

    WindowState& state = it->second;

    state.minimizeButton = { minLeft, minTop, minRight, minBottom };
    state.maximizeButton = { maxLeft, maxTop, maxRight, maxBottom };
    state.closeButton = { closeLeft, closeTop, closeRight, closeBottom };
    state.hasCaptionButtons = true;
}

// Clear caption button zones
extern "C" __declspec(dllexport) void ClearCaptionButtonZones(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it == g_window_states.end()) return;

    it->second.hasCaptionButtons = false;
}

// Set caption height
extern "C" __declspec(dllexport) void SetCaptionHeight(HWND hwnd, int height) {
    auto it = g_window_states.find(hwnd);
    if (it == g_window_states.end()) return;

    it->second.captionHeight = height > 0 ? height : DEFAULT_CAPTION_HEIGHT;
}

// Legacy: Enable or disable custom frame (hidden mode)
extern "C" __declspec(dllexport) void EnableCustomFrame(HWND hwnd, bool enable) {
    auto it = g_window_states.find(hwnd);

    if (enable) {
        if (it == g_window_states.end()) {
            WindowState state = {};
            state.frameMode = FrameMode::Hidden;
            state.captionHeight = 0;
            state.hasCaptionButtons = false;

            state.originalWndProc = reinterpret_cast<WNDPROC>(
                SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(CustomFrameWndProc))
            );

            g_window_states[hwnd] = state;

            if (g_getmsg_hook == nullptr) {
                DWORD threadId = GetWindowThreadProcessId(hwnd, nullptr);
                g_getmsg_hook = SetWindowsHookEx(WH_GETMESSAGE, GetMsgProc, nullptr, threadId);
            }
            g_hook_ref_count++;

            MARGINS margins = {0, 0, 1, 0};
            DwmExtendFrameIntoClientArea(hwnd, &margins);
        } else {
            it->second.frameMode = FrameMode::Hidden;

            MARGINS margins = {0, 0, 1, 0};
            DwmExtendFrameIntoClientArea(hwnd, &margins);
        }
    } else {
        if (it != g_window_states.end()) {
            it->second.frameMode = FrameMode::Normal;

            MARGINS margins = {0, 0, 0, 0};
            DwmExtendFrameIntoClientArea(hwnd, &margins);
        }
    }

    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

// Disable custom frame and restore normal window
extern "C" __declspec(dllexport) void DisableCustomFrame(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end()) {
        it->second.frameMode = FrameMode::Normal;

        MARGINS margins = {0, 0, 0, 0};
        DwmExtendFrameIntoClientArea(hwnd, &margins);
    }

    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

// Check current frame mode
extern "C" __declspec(dllexport) int GetFrameMode(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end()) {
        return static_cast<int>(it->second.frameMode);
    }
    return static_cast<int>(FrameMode::Normal);
}

// Check if custom frame is currently enabled (legacy)
extern "C" __declspec(dllexport) bool IsCustomFrameEnabled(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end()) {
        return it->second.frameMode != FrameMode::Normal;
    }
    return false;
}

// Restore the original window procedure
extern "C" __declspec(dllexport) void RestoreWindowProc(HWND hwnd) {
    auto it = g_window_states.find(hwnd);
    if (it != g_window_states.end()) {
        if (it->second.originalWndProc != nullptr) {
            SetWindowLongPtr(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(it->second.originalWndProc));
        }

        g_window_states.erase(it);

        g_hook_ref_count--;
        if (g_hook_ref_count <= 0 && g_getmsg_hook != nullptr) {
            UnhookWindowsHookEx(g_getmsg_hook);
            g_getmsg_hook = nullptr;
            g_hook_ref_count = 0;
        }
    }
}

// Start window resize operation
extern "C" __declspec(dllexport) void StartResize(HWND hwnd, int edge) {
    if (IsZoomed(hwnd)) return;

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

// Check if Windows 11
extern "C" __declspec(dllexport) bool IsWindows11() {
    return IsWindows11OrGreater();
}
