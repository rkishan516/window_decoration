/// Stub implementation for FFI types
/// This is used on web where dart:ffi is not available

/// Type alias for window handle pointer
/// On web, this is null since there's no FFI
typedef FfiPointer = Object?;
