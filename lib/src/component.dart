import 'dart:typed_data';

import 'package:pathify/pathify.dart';

/// A single component of a path.
///
/// A component roughly corresponds to a substring between path separators
/// (`/` or `\`). The [Components] iterator produces these by walking the
/// underlying path bytes and identifying each meaningful segment.
sealed class Component {
  const Component();

  /// The bytes of this component as they appear in the source path.
  ///
  /// For [ComponentRootDir], [ComponentCurDir], and [ComponentParentDir],
  /// the returned slice is a freshly allocated single- or double-byte list.
  /// For [ComponentNormal] and [ComponentPrefix] it is a view into the
  /// underlying path.
  Uint8List asOsStr();
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

  /// The raw prefix bytes, e.g. `\\?\C:` or `\\server\share`.
  final Uint8List raw;

  /// The structured prefix data produced by the prefix parser.
  final Prefix parsed;

  /// The kind of prefix this component represents.
  Prefix get kind => parsed;

  @override
  Uint8List asOsStr() => raw;
}

/// The root directory component.
///
/// Represents a leading separator that designates the path begins at the
/// filesystem root. For Windows paths with a prefix that already implies a
/// root (UNC, verbatim UNC, device namespace), this still appears
/// immediately after the prefix during iteration to make root presence
/// uniform across path shapes.
final class ComponentRootDir extends Component {
  const ComponentRootDir(this.separatorByte);

  /// The separator byte to render for this root: `/` on POSIX, `\` on
  /// Windows.
  final int separatorByte;

  @override
  Uint8List asOsStr() => Uint8List.fromList([separatorByte]);
}

/// A reference to the current directory: `.`.
///
/// Only emitted when `.` appears at the start of a relative path. Internal
/// `.` segments are normalized away by the iterator and never produced as
/// components.
final class ComponentCurDir extends Component {
  const ComponentCurDir();

  @override
  Uint8List asOsStr() => Uint8List.fromList(const [0x2E]);
}

/// A reference to the parent directory: `..`.
final class ComponentParentDir extends Component {
  const ComponentParentDir();

  @override
  Uint8List asOsStr() => Uint8List.fromList(const [0x2E, 0x2E]);
}

/// A normal path component such as a directory or file name.
///
/// This is the most common variant; it carries the literal bytes of the
/// segment without interpretation.
final class ComponentNormal extends Component {
  const ComponentNormal(this.value);

  /// The component bytes.
  final Uint8List value;

  @override
  Uint8List asOsStr() => value;
}
