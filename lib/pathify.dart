/// A byte-level, cross-platform path manipulation library.
///
/// Operates on raw bytes ([Uint8List] on Unix, [Uint16List] on Windows) rather
/// than strings. Correctly handles all Windows path prefix types including
/// verbatim (`\\?\`), UNC, and device namespace (`\\.\`) paths. Suitable for
/// paths containing non-UTF-8 filenames.
library;

import 'dart:typed_data';

export 'src/constants.dart';
export 'src/path.dart';
export 'src/pathify_platform.dart';
