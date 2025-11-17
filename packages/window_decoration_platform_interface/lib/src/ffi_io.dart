// Export dart:ffi for desktop platforms
import 'dart:ffi';

export 'dart:ffi';

/// Type alias for window handle pointer
/// On native platforms, this is a Pointer<Void> from dart:ffi
typedef FfiPointer = Pointer<Void>;
