// ignore_for_file: non_constant_identifier_names, constant_identifier_names, avoid_positional_boolean_parameters

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Objective-C object pointer type
typedef ObjCObjectPointer = Pointer<ObjCObject>;

/// Objective-C selector pointer type
typedef ObjCSelectorPointer = Pointer<ObjCSelector>;

/// Opaque type for Objective-C objects
final class ObjCObject extends Opaque {}

/// Opaque type for Objective-C selectors
final class ObjCSelector extends Opaque {}

/// NSRect structure for macOS window frames
final class NSRect extends Struct {
  @Double()
  external double x;

  @Double()
  external double y;

  @Double()
  external double width;

  @Double()
  external double height;
}

/// Objective-C Runtime FFI bindings for macOS window manipulation
class ObjCBindings {
  ObjCBindings._();

  static final DynamicLibrary _objc = DynamicLibrary.process();

  // ==========================================================================
  // Objective-C Runtime API
  // ==========================================================================

  /// Get an Objective-C class by name
  static final ObjCObjectPointer Function(Pointer<Utf8>) objc_getClass = _objc
      .lookupFunction<
        ObjCObjectPointer Function(Pointer<Utf8>),
        ObjCObjectPointer Function(Pointer<Utf8>)
      >('objc_getClass');

  /// Register or get an Objective-C selector
  static final ObjCSelectorPointer Function(Pointer<Utf8>) sel_registerName =
      _objc.lookupFunction<
        ObjCSelectorPointer Function(Pointer<Utf8>),
        ObjCSelectorPointer Function(Pointer<Utf8>)
      >('sel_registerName');

  // ==========================================================================
  // objc_msgSend variants
  // ==========================================================================

  /// Send a message that returns an object
  static final ObjCObjectPointer Function(
    ObjCObjectPointer,
    ObjCSelectorPointer,
  )
  objc_msgSend = _objc
      .lookupFunction<
        ObjCObjectPointer Function(ObjCObjectPointer, ObjCSelectorPointer),
        ObjCObjectPointer Function(ObjCObjectPointer, ObjCSelectorPointer)
      >('objc_msgSend');

  /// Send a message that returns void and takes an int parameter
  static final void Function(ObjCObjectPointer, ObjCSelectorPointer, int)
  objc_msgSend_void_int = _objc
      .lookupFunction<
        Void Function(ObjCObjectPointer, ObjCSelectorPointer, Uint64),
        void Function(ObjCObjectPointer, ObjCSelectorPointer, int)
      >('objc_msgSend');

  /// Send a message that returns void and takes a bool parameter
  static final void Function(ObjCObjectPointer, ObjCSelectorPointer, bool)
  objc_msgSend_void_bool = _objc
      .lookupFunction<
        Void Function(ObjCObjectPointer, ObjCSelectorPointer, Bool),
        void Function(ObjCObjectPointer, ObjCSelectorPointer, bool)
      >('objc_msgSend');

  /// Send a message that returns void and takes a double parameter
  static final void Function(ObjCObjectPointer, ObjCSelectorPointer, double)
  objc_msgSend_void_double = _objc
      .lookupFunction<
        Void Function(ObjCObjectPointer, ObjCSelectorPointer, Double),
        void Function(ObjCObjectPointer, ObjCSelectorPointer, double)
      >('objc_msgSend');

  /// Send a message that returns void and takes an object parameter
  static final void Function(
    ObjCObjectPointer,
    ObjCSelectorPointer,
    ObjCObjectPointer,
  )
  objc_msgSend_void_obj = _objc
      .lookupFunction<
        Void Function(
          ObjCObjectPointer,
          ObjCSelectorPointer,
          ObjCObjectPointer,
        ),
        void Function(ObjCObjectPointer, ObjCSelectorPointer, ObjCObjectPointer)
      >('objc_msgSend');

  /// Send a message that returns an int
  static final int Function(ObjCObjectPointer, ObjCSelectorPointer)
  objc_msgSend_int = _objc
      .lookupFunction<
        Uint64 Function(ObjCObjectPointer, ObjCSelectorPointer),
        int Function(ObjCObjectPointer, ObjCSelectorPointer)
      >('objc_msgSend');

  /// Send a message that returns a double
  static final double Function(ObjCObjectPointer, ObjCSelectorPointer)
  objc_msgSend_double = _objc
      .lookupFunction<
        Double Function(ObjCObjectPointer, ObjCSelectorPointer),
        double Function(ObjCObjectPointer, ObjCSelectorPointer)
      >('objc_msgSend');

  /// Send a message that returns an object and takes an int parameter
  static final ObjCObjectPointer Function(
    ObjCObjectPointer,
    ObjCSelectorPointer,
    int,
  )
  objc_msgSend_obj_int = _objc
      .lookupFunction<
        ObjCObjectPointer Function(
          ObjCObjectPointer,
          ObjCSelectorPointer,
          Uint64,
        ),
        ObjCObjectPointer Function(ObjCObjectPointer, ObjCSelectorPointer, int)
      >('objc_msgSend');

  /// Send a message that returns an object and takes 4 double parameters (for NSColor)
  static final ObjCObjectPointer Function(
    ObjCObjectPointer,
    ObjCSelectorPointer,
    double,
    double,
    double,
    double,
  )
  objc_msgSend_obj_4doubles = _objc
      .lookupFunction<
        ObjCObjectPointer Function(
          ObjCObjectPointer,
          ObjCSelectorPointer,
          Double,
          Double,
          Double,
          Double,
        ),
        ObjCObjectPointer Function(
          ObjCObjectPointer,
          ObjCSelectorPointer,
          double,
          double,
          double,
          double,
        )
      >('objc_msgSend');

  /// Send a message that returns a struct (NSRect)
  /// On arm64, structs are returned in registers - use regular objc_msgSend
  /// On x86_64, use objc_msgSend_stret for struct returns
  static NSRect objc_msgSend_stret_nsrect(
    ObjCObjectPointer obj,
    ObjCSelectorPointer sel,
  ) {
    // On arm64 (Apple Silicon), use regular objc_msgSend
    // Structs are returned in registers
    final getFrame = _objc
        .lookupFunction<
          NSRect Function(ObjCObjectPointer, ObjCSelectorPointer),
          NSRect Function(ObjCObjectPointer, ObjCSelectorPointer)
        >('objc_msgSend');

    return getFrame(obj, sel);
  }

  /// Send a message that sets a frame with display parameter
  static final void Function(
    ObjCObjectPointer,
    ObjCSelectorPointer,
    Pointer<NSRect>,
    bool,
  )
  objc_msgSend_void_rect_bool = _objc
      .lookupFunction<
        Void Function(
          ObjCObjectPointer,
          ObjCSelectorPointer,
          Pointer<NSRect>,
          Bool,
        ),
        void Function(
          ObjCObjectPointer,
          ObjCSelectorPointer,
          Pointer<NSRect>,
          bool,
        )
      >('objc_msgSend');

  // ==========================================================================
  // Helper Functions
  // ==========================================================================

  /// Helper to create an Objective-C selector
  static ObjCSelectorPointer sel(String name) {
    final cStr = name.toNativeUtf8();
    final selector = sel_registerName(cStr);
    malloc.free(cStr);
    return selector;
  }

  /// Helper to get an Objective-C class
  static ObjCObjectPointer getClass(String name) {
    final cStr = name.toNativeUtf8();
    final cls = objc_getClass(cStr);
    malloc.free(cStr);
    return cls;
  }
}

// ==========================================================================
// NSWindow Constants
// ==========================================================================

/// NSWindow style mask constants
class NSWindowStyleMask {
  NSWindowStyleMask._();

  static const int borderless = 0;
  static const int titled = 1 << 0;
  static const int closable = 1 << 1;
  static const int miniaturizable = 1 << 2;
  static const int resizable = 1 << 3;
  static const int fullScreen = 1 << 14;
  static const int fullSizeContentView = 1 << 15;
}

/// NSWindow title visibility constants
class NSWindowTitleVisibility {
  NSWindowTitleVisibility._();

  static const int visible = 0;
  static const int hidden = 1;
}

/// NSWindow level constants
class NSWindowLevel {
  NSWindowLevel._();

  static const int normal = 0;
  static const int floating = 3;
  static const int submenu = 3;
  static const int torn_off_menu = 3;
  static const int main_menu = 24;
  static const int status = 25;
  static const int modal_panel = 8;
  static const int pop_up_menu = 101;
  static const int screen_saver = 1000;
}

/// NSApplication activation policy constants
class NSApplicationActivationPolicy {
  NSApplicationActivationPolicy._();

  static const int regular = 0;
  static const int accessory = 1;
  static const int prohibited = 2;
}

/// NSWindowButton type constants
class NSWindowButton {
  NSWindowButton._();

  static const int closeButton = 0;
  static const int miniaturizeButton = 1;
  static const int zoomButton = 2;
  static const int toolbarButton = 3;
  static const int documentIconButton = 4;
  static const int documentVersionsButton = 6;
}
