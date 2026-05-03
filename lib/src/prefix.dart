import 'dart:typed_data';

/// A Windows path prefix.
///
/// Windows uses a variety of path prefix styles, including drive volumes
/// (`C:`), network shares (`\\server\share`), device namespaces (`\\.\COM42`),
/// and verbatim forms (`\\?\...`) where `/` is not treated as a separator and
/// no normalization is performed.
///
/// On non-Windows platforms a path never carries a parsed prefix, so this
/// type does not appear there.
sealed class Prefix {
  const Prefix();

  /// The number of code units this prefix occupies in the source path.
  int get len;

  /// True for prefixes that begin with `\\?\`.
  ///
  /// Verbatim prefixes disable normalization: forward slashes are not treated
  /// as separators and `.` / `..` are not collapsed.
  bool get isVerbatim => switch (this) {
    Verbatim() || VerbatimUNC() || VerbatimDisk() => true,
    _ => false,
  };

  /// True when this prefix is a plain disk prefix (`C:`).
  ///
  /// Disk prefixes are the only kind that does not carry an implicit root,
  /// so a path such as `C:foo` is relative.
  bool get isDrive => this is Disk;

  /// True when this prefix logically implies a root, even if the path bytes
  /// do not contain one.
  ///
  /// For example, `\\server\share` is rooted; `C:` is not.
  bool get hasImplicitRoot => !isDrive;
}

/// Verbatim prefix consisting of `\\?\` followed by a single component.
///
/// Example: `\\?\cat_pics`.
final class Verbatim extends Prefix {
  const Verbatim(this.component);

  /// The component bytes that follow `\\?\`.
  final Uint8List component;

  @override
  int get len => 4 + component.length;
}

/// Verbatim UNC prefix: `\\?\UNC\` followed by a server name and a share name.
///
/// Example: `\\?\UNC\server\share`.
final class VerbatimUNC extends Prefix {
  const VerbatimUNC(this.server, this.share);

  /// The server hostname bytes.
  final Uint8List server;

  /// The share name bytes.
  final Uint8List share;

  @override
  int get len => 8 + server.length + (share.isEmpty ? 0 : 1 + share.length);
}

/// Verbatim disk prefix: `\\?\` followed by a drive letter and `:`.
///
/// Example: `\\?\C:`. The drive letter is stored in uppercase ASCII form.
final class VerbatimDisk extends Prefix {
  const VerbatimDisk(this.drive);

  /// The drive letter as an uppercase ASCII byte (`A`–`Z`).
  final int drive;

  @override
  int get len => 6;
}

/// Device namespace prefix: `\\.\` followed by a device name.
///
/// Example: `\\.\COM42`. Used to refer to Windows device objects directly.
final class DeviceNS extends Prefix {
  const DeviceNS(this.device);

  /// The device name bytes.
  final Uint8List device;

  @override
  int get len => 4 + device.length;
}

/// UNC prefix: `\\` followed by a server name and a share name.
///
/// Example: `\\server\share`. Used to refer to network shares.
final class UNC extends Prefix {
  const UNC(this.server, this.share);

  /// The server hostname bytes.
  final Uint8List server;

  /// The share name bytes.
  final Uint8List share;

  @override
  int get len => 2 + server.length + (share.isEmpty ? 0 : 1 + share.length);
}

/// Disk prefix: a drive letter followed by `:`.
///
/// Example: `C:`. The drive letter is stored in uppercase ASCII form.
final class Disk extends Prefix {
  const Disk(this.drive);

  /// The drive letter as an uppercase ASCII byte (`A`–`Z`).
  final int drive;

  @override
  int get len => 2;
}
