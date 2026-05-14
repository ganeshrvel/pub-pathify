import 'package:pathify/pathify.dart';
import 'package:pathify/src/path_bytes.dart';

/// Windows prefix parser.
///
/// The parser inspects the leading code units of a path and identifies one
/// of the six prefix forms (verbatim, verbatim UNC, verbatim disk, device
/// namespace, UNC, or plain disk) — or returns `null` when no prefix is
/// present.
///
/// The matcher operates on a normalized lookup window over the first
/// eight code units, where `/` is treated as `\`, so prefix detection
/// succeeds regardless of which separator the caller used. The original
/// path code units are never modified; normalization is confined to the
/// lookup window. All data extracted as variant payloads (server names,
/// device names, the verbatim component) is sliced from the original
/// [CodeUnits] storage so non-ASCII code units flow through verbatim.
class WindowsPrefix {
  WindowsPrefix._();

  /// The size of the lookup window used for prefix detection.
  ///
  /// Eight code units is the longest fixed prefix the parser needs to match
  /// (`\\?\UNC\` is exactly eight). Anything beyond that is parsed against
  /// the source path directly.
  static const int _lookupWindow = 8;

  /// Identifies the path prefix, if any.
  ///
  /// Returns one of the [Prefix] subclasses describing the prefix found, or
  /// `null` when the path does not begin with a recognizable prefix.
  static Prefix? parsePrefix(CodeUnits path) {
    final parser = _PrefixParser._build(path, _lookupWindow).asSlice();

    final afterTwoBack = parser.stripPrefix(
      WindowsPathConstants.standardUncPrefix,
    );
    if (afterTwoBack != null) {
      // Path begins with `\\`. Branch on the next two characters to decide
      // between verbatim (`?\`), device namespace (`.\`), and UNC.
      final afterVerb = afterTwoBack.stripPrefix(
        WindowsPathConstants.verbatimMarker,
      );
      if (afterVerb != null && _isExactVerbatimPrefix(path)) {
        // Path begins with `\\?\`.
        final afterUnc = afterVerb.stripPrefix(WindowsPathConstants.uncMarker);
        if (afterUnc != null) {
          // `\\?\UNC\server\share`.
          final remaining = afterUnc.finish();
          final (server, afterServer) = parseNextComponent(
            remaining,
            verbatim: true,
          );
          final (share, _) = parseNextComponent(afterServer, verbatim: true);
          return VerbatimUNC(server, share);
        }

        final remaining = afterVerb.finish();
        final drive = _parseDriveExact(remaining);
        if (drive != null) {
          // `\\?\C:`.
          return VerbatimDisk(drive);
        }

        // `\\?\<component>`.
        final (component, _) = parseNextComponent(remaining, verbatim: true);
        return Verbatim(component);
      }

      final afterDevice = afterTwoBack.stripPrefix(
        WindowsPathConstants.deviceNsMarker,
      );
      if (afterDevice != null) {
        // `\\.\<device>`.
        final remaining = afterDevice.finish();
        final (device, _) = parseNextComponent(remaining, verbatim: false);
        return DeviceNS(device);
      }

      // `\\<server>\<share>`. Both segments must be non-empty for the prefix
      // to be valid.
      final remaining = afterTwoBack.finish();
      final (server, afterServer) = parseNextComponent(
        remaining,
        verbatim: false,
      );
      final (share, _) = parseNextComponent(afterServer, verbatim: false);
      if (server.isNotEmpty && share.isNotEmpty) {
        return UNC(server, share);
      }
      // Path begins with `\\` but does not match any recognized prefix shape.
      return null;
    }

    // Not a `\\`-prefixed path. The only remaining possibility is a plain
    // drive prefix (`C:` and beyond).
    final drive = _parseDrive(path);
    if (drive == null) return null;
    return Disk(drive);
  }

  /// Parses a drive prefix at the start of [path].
  ///
  /// Accepts a path beginning with a drive letter and a colon, optionally
  /// followed by more bytes. The returned drive letter is normalized to
  /// uppercase ASCII.
  ///
  /// Returns `null` when [path] does not begin with `<letter>:`.
  static int? _parseDrive(CodeUnits path) {
    if (path.length < 2) return null;
    final drive = path[0];
    if (path[1] != PathBytes.colon) return null;
    if (!PathBytes.isAsciiAlpha(drive)) return null;
    return PathBytes.asciiToUpper(drive);
  }

  /// Parses a drive prefix only when the third code unit (if present) is a
  /// separator.
  ///
  /// Used inside verbatim contexts where the drive prefix must be exactly
  /// two characters: a letter followed by `:`. Anything else immediately
  /// after — except a separator or end of path — disqualifies the match.
  static int? _parseDriveExact(CodeUnits path) {
    if (path.length >= 3) {
      final third = path[2];
      if (third != PathBytes.backslash && third != PathBytes.slash) {
        return null;
      }
    }
    return _parseDrive(path);
  }

  /// Splits off the next path component.
  ///
  /// Returns a `(component, remainder)` pair where both views are slices
  /// of the original storage — non-ASCII code units are preserved.
  static (CodeUnits, CodeUnits) parseNextComponent(
    CodeUnits path, {
    required bool verbatim,
  }) {
    bool isSep(int b) {
      if (verbatim) return b == PathBytes.backslash;
      return b == PathBytes.backslash || b == PathBytes.slash;
    }

    for (var i = 0; i < path.length; i++) {
      if (isSep(path[i])) {
        return (path.sublistView(0, i), path.sublistView(i + 1));
      }
    }
    return (path, path.emptyOfSameWidth());
  }
}

/// Top-level alias so callers in this library can use the same name without
/// reaching through [WindowsPrefix].
(CodeUnits, CodeUnits) parseNextComponent(
  CodeUnits path, {
  required bool verbatim,
}) => WindowsPrefix.parseNextComponent(path, verbatim: verbatim);

/// Internal helper that owns the lookup-window buffer.
///
/// The window is a list of integers — one entry per source code unit —
/// where every `/` has been replaced by `\`. Prefix matching against this
/// list succeeds regardless of which separator the caller used. The
/// original [CodeUnits] are never modified.
class _PrefixParser {
  _PrefixParser._raw(this.path, this.window);

  factory _PrefixParser._build(CodeUnits path, int windowLen) {
    final n = path.length < windowLen ? path.length : windowLen;
    final window = List<int>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final ch = path[i];
      window[i] = ch == PathBytes.slash ? PathBytes.backslash : ch;
    }
    return _PrefixParser._raw(path, window);
  }

  final CodeUnits path;
  final List<int> window;

  /// Returns a movable cursor positioned at the start of the lookup window.
  _PrefixParserSlice asSlice() =>
      _PrefixParserSlice(path: path, window: window, index: 0);
}

/// A cursor into a [_PrefixParser]'s lookup window.
///
/// Each successful `stripPrefix` call returns a new slice positioned past the
/// matched bytes. [finish] discards the window and returns the rest of the
/// source path so subsequent code can operate on the original bytes (which
/// may include `/` characters in non-verbatim positions).
class _PrefixParserSlice {
  const _PrefixParserSlice({
    required this.path,
    required this.window,
    required this.index,
  });

  final CodeUnits path;
  final List<int> window;
  final int index;

  /// Tries to consume [pattern] from the current cursor position.
  ///
  /// On success returns a new slice advanced past the pattern. Returns `null`
  /// when the bytes ahead do not match.
  _PrefixParserSlice? stripPrefix(String pattern) {
    final patBytes = pattern.codeUnits;
    if (index + patBytes.length > window.length) return null;
    for (var i = 0; i < patBytes.length; i++) {
      if (window[index + i] != patBytes[i]) return null;
    }
    return _PrefixParserSlice(
      path: path,
      window: window,
      index: index + patBytes.length,
    );
  }

  /// Returns the source code units that remain after the cursor.
  CodeUnits finish() => path.sublistView(index);
}

bool _isExactVerbatimPrefix(CodeUnits path) {
  if (path.length < 4) return false;
  return path[0] == PathBytes.backslash &&
      path[1] == PathBytes.backslash &&
      path[2] == PathBytes.question &&
      path[3] == PathBytes.backslash;
}
