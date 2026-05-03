import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:pathify/src/path_bytes.dart';

/// A single component of a path.
///
/// A component roughly corresponds to a substring between path separators
/// (`/` or `\`). The [Components] iterator produces these by walking the
/// underlying path bytes and identifying each meaningful segment.
sealed class Component {
  const Component();

  /// The code units of this component as they appear in the source path.
  CodeUnits asOsStr();
}

/// A Windows path prefix appearing as the first component of a path.
///
/// Carries both the raw bytes as they appeared in the source path and the
/// fully parsed [Prefix] data, so consumers can both round-trip the path
/// faithfully and inspect what kind of prefix it is.
///
/// Does not occur on POSIX.
final class ComponentPrefix extends Component {
  const ComponentPrefix({required this.raw, required this.parsed});

  /// The raw prefix code units, e.g. `\\?\C:` or `\\server\share`.
  final CodeUnits raw;

  /// The structured prefix data produced by the prefix parser.
  final Prefix parsed;

  /// The kind of prefix this component represents.
  Prefix get kind => parsed;

  @override
  CodeUnits asOsStr() => raw;
}

/// The root directory component.
///
/// Represents a leading separator that designates the path begins at the
/// filesystem root. For Windows paths with a prefix that already implies a
/// root (UNC, verbatim UNC, device namespace), this still appears
/// immediately after the prefix during iteration to make root presence
/// uniform across path shapes.
final class ComponentRootDir extends Component {
  const ComponentRootDir(this.separatorByte, {required this.isWide});

  /// The separator code unit to render: `/` on POSIX, `\` on Windows.
  final int separatorByte;

  /// Whether this root belongs to a wide (Windows) or narrow (POSIX) path.
  final bool isWide;

  @override
  CodeUnits asOsStr() {
    if (isWide) {
      return WideCodeUnits(_singleWide(separatorByte));
    }
    return NarrowCodeUnits(_singleNarrow(separatorByte));
  }
}

/// A reference to the current directory: `.`.
///
/// Only emitted when `.` appears at the start of a relative path. Internal
/// `.` segments are normalized away by the iterator and never produced as
/// components.
final class ComponentCurDir extends Component {
  const ComponentCurDir({required this.isWide});

  final bool isWide;

  @override
  CodeUnits asOsStr() {
    if (isWide) {
      return WideCodeUnits(_singleWide(PathBytes.dot));
    }
    return NarrowCodeUnits(_singleNarrow(PathBytes.dot));
  }
}

/// A reference to the parent directory: `..`.
final class ComponentParentDir extends Component {
  const ComponentParentDir({required this.isWide});

  final bool isWide;

  @override
  CodeUnits asOsStr() {
    if (isWide) {
      return WideCodeUnits(_doubleWide(PathBytes.dot));
    }
    return NarrowCodeUnits(_doubleNarrow(PathBytes.dot));
  }
}

/// A normal path component such as a directory or file name.
///
/// This is the most common variant; it carries the literal bytes of the
/// segment without interpretation.
final class ComponentNormal extends Component {
  const ComponentNormal(this.value);

  /// The component code units.
  final CodeUnits value;

  @override
  CodeUnits asOsStr() => value;
}

Uint8List _singleNarrow(int b) {
  final out = Uint8List(1);
  out[0] = b & 0xFF;
  return out;
}

Uint16List _singleWide(int b) {
  final out = Uint16List(1);
  out[0] = b & 0xFFFF;
  return out;
}

Uint8List _doubleNarrow(int b) {
  final out = Uint8List(2);
  out[0] = b & 0xFF;
  out[1] = b & 0xFF;
  return out;
}

Uint16List _doubleWide(int b) {
  final out = Uint16List(2);
  out[0] = b & 0xFFFF;
  out[1] = b & 0xFFFF;
  return out;
}
