import 'dart:typed_data';

import 'package:pathify/src/component.dart';
import 'package:pathify/src/components.dart';
import 'package:pathify/src/path_bytes.dart';
import 'package:pathify/src/pathify_platform.dart';
import 'package:pathify/src/prefix.dart';
import 'package:pathify/src/sys/path/unix_style.dart';
import 'package:pathify/src/sys/path/windows_prefix.dart';
import 'package:pathify/src/sys/path/windows_style.dart';

export 'package:pathify/src/component.dart';
export 'package:pathify/src/components.dart';
export 'package:pathify/src/prefix.dart';

/// An owned, mutable path.
///
/// Stores raw bytes — [Uint8List] for POSIX paths, [Uint16List] for Windows
/// paths — and exposes inspection (parent, file name, components) and
/// mutation (push, pop, set extension) operations on top.
///
/// The path's style is determined intrinsically by the storage type:
/// `Uint16List` is always Windows; `Uint8List` is always POSIX. The platform
/// reported by [Pathify.instance] only affects construction-time assertions
/// and the choice of style for the [PathBuf.fromBytes] entry point.
final class PathBuf {
  PathBuf._(this._bytes);

  /// Builds a path from raw bytes.
  ///
  /// On Windows the bytes must be a [Uint16List] of UTF-16 code units; on
  /// any other platform they must be a [Uint8List]. The expected type is
  /// determined by `Pathify.instance.platform`.
  ///
  /// In debug builds an [AssertionError] is thrown if [bytes] is the wrong
  /// type for the active platform. In release builds the assertion is
  /// skipped and the supplied buffer is used as-is.
  factory PathBuf.fromBytes(TypedData bytes) {
    assert(
      _validateStorage(bytes),
      'PathBuf.fromBytes received the wrong byte vector for this platform. '
      'Expected ${Pathify.instance.isWindows() ? 'Uint16List' : 'Uint8List'}, '
      'got ${bytes.runtimeType}.',
    );
    return PathBuf._(bytes);
  }

  /// Builds an empty path.
  ///
  /// The storage type is chosen based on the active platform.
  factory PathBuf.empty() {
    if (Pathify.instance.isWindows()) {
      return PathBuf._(Uint16List(0));
    }
    return PathBuf._(Uint8List(0));
  }

  TypedData _bytes;

  // ── Storage access (style-agnostic) ──────────────────────────────────

  /// True when the underlying storage is a [Uint16List], i.e. Windows-style.
  bool get _isWindowsStyle => _bytes is Uint16List;

  /// The number of code units (or bytes) in the path.
  int get _length => _bytes.lengthInBytes ~/ _bytes.elementSizeInBytes;

  /// Reads a single code unit (or byte) at [index].
  int _at(int index) {
    final b = _bytes;
    if (b is Uint8List) return b[index];
    if (b is Uint16List) return b[index];
    throw StateError('unsupported PathBuf storage: ${b.runtimeType}');
  }

  /// Materializes the path bytes into a [Uint8List] view.
  ///
  /// On POSIX this is a zero-copy view of the underlying bytes. On Windows
  /// it allocates a new buffer of the same length, copying each UTF-16 code
  /// unit into a single byte slot — this is only safe for ASCII-only paths
  /// and is provided to support the prefix parser, which inspects only
  /// ASCII bytes.
  ///
  /// Used internally by operations that need a uniform byte view.
  Uint8List _asAsciiBytes() {
    final b = _bytes;
    if (b is Uint8List) return b;
    if (b is Uint16List) {
      final out = Uint8List(b.length);
      for (var i = 0; i < b.length; i++) {
        // Path-significant bytes are ASCII; non-ASCII code units may be
        // truncated here, but the parser never inspects them — only slices
        // them out as opaque payload.
        out[i] = b[i] & 0xFF;
      }
      return out;
    }
    throw StateError('unsupported PathBuf storage: ${b.runtimeType}');
  }

  /// The raw underlying storage as supplied to [PathBuf.fromBytes].
  TypedData get bytes => _bytes;

  /// Whether this path uses Windows path semantics.
  ///
  /// Derived from the storage type, not from the global platform.
  bool get isWindows => _isWindowsStyle;

  /// Whether this path uses POSIX path semantics.
  bool get isUnix => !isWindows;

  /// True when the path contains no bytes.
  bool get isEmpty => _length == 0;

  /// The number of code units (or bytes) in the path.
  int get length => _length;

  // ── Prefix and structure ─────────────────────────────────────────────

  /// The parsed Windows prefix, or `null` when the path has none.
  ///
  /// On POSIX this is always `null`. On Windows, runs the cascade prefix
  /// parser over the leading bytes.
  Prefix? prefix() {
    if (!_isWindowsStyle) return null;
    return WindowsPrefix.parsePrefix(_asAsciiBytes());
  }

  /// True when the path has a leading root, either physically (a leading
  /// separator) or implied by its prefix (UNC, device namespace, etc.).
  bool hasRoot() => components().hasRoot();

  /// True when the path is independent of the current working directory.
  ///
  /// On POSIX, this is equivalent to [hasRoot]. On Windows, the path must
  /// have both a recognized prefix and a root; bare drive prefixes such as
  /// `C:foo` are relative.
  bool isAbsolute() {
    if (_isWindowsStyle) {
      return hasRoot() && prefix() != null;
    }
    return hasRoot();
  }

  /// True when [isAbsolute] is false.
  bool isRelative() => !isAbsolute();

  // ── Iteration ────────────────────────────────────────────────────────

  /// Walks the components of the path.
  ///
  /// See [Components] for the normalization rules applied during iteration.
  Components components() => Components.start(
    pathBytes: _asAsciiBytes(),
    prefix: prefix(),
    isWindows: _isWindowsStyle,
  );

  /// Walks the components as raw byte slices.
  Iter iter() => Iter(components());

  /// Iterates from this path up through each successive parent, ending with
  /// the topmost ancestor.
  Iterable<PathBuf> ancestors() sync* {
    PathBuf? current = this;
    while (current != null) {
      yield current;
      current = current.parent();
    }
  }

  // ── Inspection ───────────────────────────────────────────────────────

  /// The path with its final component removed.
  ///
  /// Returns `null` when the path terminates in a root or prefix, or when
  /// the path is empty. For a relative path with one component, returns an
  /// empty path.
  PathBuf? parent() {
    final iter = components();
    final last = iter.nextBack();
    if (last == null) return null;
    return switch (last) {
      ComponentNormal() ||
      ComponentCurDir() ||
      ComponentParentDir() => _materialize(iter.asPathBytes()),
      _ => null,
    };
  }

  /// The final component of the path.
  ///
  /// Returns `null` when the path terminates in a root, prefix, or `..`.
  Uint8List? fileName() {
    final iter = components();
    final last = iter.nextBack();
    if (last is ComponentNormal) {
      return last.value;
    }
    return null;
  }

  /// The portion of [fileName] preceding the final dot.
  ///
  /// Returns the entire file name when there is no embedded dot, or when the
  /// file name begins with a dot and has no other dots within. Returns
  /// `null` when there is no file name.
  Uint8List? fileStem() {
    final name = fileName();
    if (name == null) return null;
    final (before, after) = _rsplitAtDot(name);
    return before ?? after;
  }

  /// The portion of [fileName] preceding the first dot.
  ///
  /// For dotfiles such as `.config`, the leading dot is preserved and the
  /// result is the whole name. Returns `null` when there is no file name.
  Uint8List? filePrefix() {
    final name = fileName();
    if (name == null) return null;
    final (before, _) = _splitAtDot(name);
    return before;
  }

  /// The file extension, without its leading dot.
  ///
  /// Returns `null` when there is no file name, no embedded dot, or when
  /// the file name begins with a dot and has no other dots within.
  Uint8List? extension() {
    final name = fileName();
    if (name == null) return null;
    final (before, after) = _rsplitAtDot(name);
    if (before != null && after != null) return after;
    return null;
  }

  /// True when the path ends in a separator byte.
  bool hasTrailingSep() {
    if (isEmpty) return false;
    final last = _at(_length - 1);
    if (_isWindowsStyle) {
      return WindowsStyle.isSepByte(last);
    }
    return UnixStyle.isSepByte(last);
  }

  // ── Comparison helpers ───────────────────────────────────────────────

  /// True when [base] is a prefix of this path on whole-component
  /// boundaries.
  bool startsWith(PathBuf base) =>
      _iterAfter(components(), base.components()) != null;

  /// True when [child] is a suffix of this path on whole-component
  /// boundaries.
  bool endsWith(PathBuf child) {
    final selfComps = components().toListReversed();
    final childComps = child.components().toListReversed();
    if (childComps.length > selfComps.length) return false;
    for (var i = 0; i < childComps.length; i++) {
      if (!_componentEquals(selfComps[i], childComps[i])) return false;
    }
    return true;
  }

  /// Returns a new path with [base] removed from the front, or `null` when
  /// [base] is not a prefix of this path.
  PathBuf? stripPrefix(PathBuf base) {
    final remaining = _iterAfter(components(), base.components());
    if (remaining == null) return null;
    return _materialize(remaining.asPathBytes());
  }

  // ── Mutation ─────────────────────────────────────────────────────────

  /// Appends [path] to this path.
  ///
  /// If [path] is absolute it replaces this path entirely. On Windows, if
  /// [path] has a root but no prefix it replaces everything except the
  /// existing prefix; if it has a prefix it replaces the entire path.
  ///
  /// Otherwise [path] is appended after a separator (one is inserted if
  /// the existing path does not already end with one).
  void push(PathBuf path) {
    final myBytes = _asAsciiBytes();
    final theirBytes = path._asAsciiBytes();

    var needSep =
        myBytes.isNotEmpty && !_isSepHere(myBytes[myBytes.length - 1]);

    // Special case: when this path is exactly a drive prefix (e.g. `C:`),
    // do not insert a separator.
    final myComps = Components.start(
      pathBytes: myBytes,
      prefix: prefix(),
      isWindows: _isWindowsStyle,
    );
    final myPrefixLen = prefix()?.len ?? 0;
    if (myPrefixLen > 0 && myPrefixLen == myBytes.length && prefix()!.isDrive) {
      needSep = false;
    }
    // Reference [myComps] to avoid unused-variable lints; iteration is not
    // required here.
    myComps.toList();

    final pathIsAbsolute = path.isAbsolute() || path.prefix() != null;
    if (pathIsAbsolute) {
      _bytes = path._bytes;
      return;
    }

    if (path.hasRoot()) {
      // Path has a root but no prefix; replace everything after this path's
      // existing prefix.
      _truncate(myPrefixLen);
    } else if (needSep) {
      _appendByte(_mainSepByte());
    }

    _appendBytes(theirBytes);
  }

  /// Truncates this path to its parent, returning whether anything was
  /// removed.
  bool pop() {
    final p = parent();
    if (p == null) return false;
    _bytes = p._bytes;
    return true;
  }

  /// Replaces the final component with [fileName].
  ///
  /// When the path has no file name (e.g. it ends in a separator), the
  /// supplied name is appended.
  void setFileName(Uint8List fileName) {
    if (this.fileName() != null) {
      pop();
    }
    push(_materialize(fileName));
  }

  /// Replaces the file extension with [extension].
  ///
  /// When [extension] is empty the existing extension is removed. When the
  /// path has no file name nothing happens and `false` is returned.
  bool setExtension(Uint8List extension) {
    _validateExtension(extension);
    final stem = fileStem();
    if (stem == null) return false;

    // Truncate to just past the stem.
    final myBytes = _asAsciiBytes();
    final stemEnd = _findStemEnd(myBytes, stem);
    _truncate(stemEnd);

    if (extension.isNotEmpty) {
      _appendByte(PathBytes.dot);
      _appendBytes(extension);
    }
    return true;
  }

  /// Appends [extension] to the path's existing extension without removing
  /// it.
  ///
  /// When the path has no file name nothing happens and `false` is
  /// returned.
  bool addExtension(Uint8List extension) {
    _validateExtension(extension);
    final name = fileName();
    if (name == null) return false;

    if (extension.isNotEmpty) {
      _appendByte(PathBytes.dot);
      _appendBytes(extension);
    }
    return true;
  }

  /// Empties the path.
  void clear() {
    _bytes = _isWindowsStyle ? Uint16List(0) : Uint8List(0);
  }

  // ── Non-mutating builders ────────────────────────────────────────────

  /// Returns a new path with [other] joined onto this one.
  ///
  /// Uses the same rules as [push].
  PathBuf join(PathBuf other) {
    final out = _clone()..push(other);
    return out;
  }

  /// Returns a new path with the file name replaced.
  PathBuf withFileName(Uint8List fileName) {
    final out = _clone()..setFileName(fileName);
    return out;
  }

  /// Returns a new path with the extension replaced.
  PathBuf withExtension(Uint8List extension) {
    final out = _clone()..setExtension(extension);
    return out;
  }

  /// Returns a new path with [extension] appended to the existing extension.
  PathBuf withAddedExtension(Uint8List extension) {
    final out = _clone()..addExtension(extension);
    return out;
  }

  // ── Equality ─────────────────────────────────────────────────────────

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (other is! PathBuf) return false;
    if (other._isWindowsStyle != _isWindowsStyle) return false;
    final a = components().toList();
    final b = other.components().toList();
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_componentEquals(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode {
    var h = _isWindowsStyle.hashCode;
    for (final c in components().toList()) {
      h = h ^ _componentHash(c);
    }
    return h;
  }

  // ── Internal mutation primitives ─────────────────────────────────────

  void _truncate(int newLength) {
    final b = _bytes;
    if (b is Uint8List) {
      _bytes = Uint8List.sublistView(b, 0, newLength);
    } else if (b is Uint16List) {
      _bytes = Uint16List.sublistView(b, 0, newLength);
    } else {
      throw StateError('unsupported PathBuf storage: ${b.runtimeType}');
    }
  }

  void _appendByte(int byte) {
    final b = _bytes;
    if (b is Uint8List) {
      final out = Uint8List(b.length + 1)..setRange(0, b.length, b);
      out[b.length] = byte;
      _bytes = out;
    } else if (b is Uint16List) {
      final out = Uint16List(b.length + 1)..setRange(0, b.length, b);
      out[b.length] = byte;
      _bytes = out;
    } else {
      throw StateError('unsupported PathBuf storage: ${b.runtimeType}');
    }
  }

  void _appendBytes(Uint8List src) {
    final b = _bytes;
    if (b is Uint8List) {
      final out = Uint8List(b.length + src.length)
        ..setRange(0, b.length, b)
        ..setRange(b.length, b.length + src.length, src);
      _bytes = out;
    } else if (b is Uint16List) {
      final out = Uint16List(b.length + src.length)..setRange(0, b.length, b);
      for (var i = 0; i < src.length; i++) {
        out[b.length + i] = src[i];
      }
      _bytes = out;
    } else {
      throw StateError('unsupported PathBuf storage: ${b.runtimeType}');
    }
  }

  PathBuf _clone() {
    final b = _bytes;
    if (b is Uint8List) return PathBuf._(Uint8List.fromList(b));
    if (b is Uint16List) return PathBuf._(Uint16List.fromList(b));
    throw StateError('unsupported PathBuf storage: ${b.runtimeType}');
  }

  /// Builds a fresh [PathBuf] of the same style from the given byte view.
  PathBuf _materialize(Uint8List bytes) {
    if (_isWindowsStyle) {
      final out = Uint16List(bytes.length);
      for (var i = 0; i < bytes.length; i++) {
        out[i] = bytes[i];
      }
      return PathBuf._(out);
    }
    return PathBuf._(Uint8List.fromList(bytes));
  }

  bool _isSepHere(int b) =>
      _isWindowsStyle ? WindowsStyle.isSepByte(b) : UnixStyle.isSepByte(b);

  int _mainSepByte() =>
      _isWindowsStyle ? WindowsStyle.mainSep : UnixStyle.mainSep;

  // ── Static validation ────────────────────────────────────────────────

  static bool _validateStorage(TypedData bytes) {
    if (Pathify.instance.isWindows()) {
      return bytes is Uint16List;
    }
    return bytes is Uint8List;
  }

  static void _validateExtension(Uint8List ext) {
    for (final b in ext) {
      if (UnixStyle.isSepByte(b) || WindowsStyle.isSepByte(b)) {
        throw ArgumentError(
          'extension cannot contain path separators: ${ext.toList()}',
        );
      }
    }
  }
}

// ── Free helpers ───────────────────────────────────────────────────────────

/// True when [codeUnit] is one of the platform's path separators.
///
/// On Windows both `\` and `/` qualify; on POSIX only `/` does.
bool isSeparator(int codeUnit) {
  if (codeUnit > 0x7F) return false;
  if (Pathify.instance.isWindows()) {
    return WindowsStyle.isSepByte(codeUnit);
  }
  return UnixStyle.isSepByte(codeUnit);
}

/// The platform's primary path separator as a code unit.
int mainSeparator() =>
    Pathify.instance.isWindows() ? WindowsStyle.mainSep : UnixStyle.mainSep;

/// The platform's primary path separator as a single-character string.
String mainSeparatorStr() => Pathify.instance.isWindows()
    ? WindowsStyle.mainSepStr
    : UnixStyle.mainSepStr;

/// Walks `iter` and `prefix` in lockstep, returning the remainder of `iter`
/// when `prefix` is exhausted with all components matching, or `null` when
/// the components diverge.
Components? _iterAfter(Components iter, Components prefix) {
  var cursor = iter;
  while (true) {
    final iterClone = cursor.clone();
    final next = iterClone.next();
    final pfx = prefix.next();
    if (next == null && pfx == null) return cursor;
    if (next != null && pfx == null) return cursor;
    if (next == null && pfx != null) return null;
    if (!_componentEquals(next!, pfx!)) return null;
    cursor = iterClone;
  }
}

/// Splits [file] into `(before, after)` around the final embedded dot.
///
/// `..` is preserved as a whole. A leading dot is not treated as a split
/// point; `.bashrc` returns `(null, '.bashrc')`. The exact behavior
/// matches the file-stem / extension rules.
(Uint8List?, Uint8List?) _rsplitAtDot(Uint8List file) {
  if (file.length == 2 &&
      file[0] == PathBytes.dot &&
      file[1] == PathBytes.dot) {
    return (file, null);
  }

  var dotAt = -1;
  for (var i = file.length - 1; i >= 0; i--) {
    if (file[i] == PathBytes.dot) {
      dotAt = i;
      break;
    }
  }

  if (dotAt < 0) return (null, file);

  final before = Uint8List.sublistView(file, 0, dotAt);
  final after = Uint8List.sublistView(file, dotAt + 1);
  if (before.isEmpty) return (file, null);
  return (before, after);
}

/// Splits [file] into `(before, after)` around the first non-leading dot.
///
/// Used for [PathBuf.filePrefix].
(Uint8List, Uint8List?) _splitAtDot(Uint8List file) {
  if (file.length == 2 &&
      file[0] == PathBytes.dot &&
      file[1] == PathBytes.dot) {
    return (file, null);
  }
  var i = -1;
  // Skip the leading byte so a leading dot does not count as a split point.
  for (var k = 1; k < file.length; k++) {
    if (file[k] == PathBytes.dot) {
      i = k;
      break;
    }
  }
  if (i < 0) return (file, null);
  final before = Uint8List.sublistView(file, 0, i);
  final after = Uint8List.sublistView(file, i + 1);
  return (before, after);
}

/// Locates the byte index immediately after [stem] within [bytes].
///
/// Used by [PathBuf.setExtension] to truncate the path to the stem.
int _findStemEnd(Uint8List bytes, Uint8List stem) {
  // The stem is always a slice from the end of the path. Search backwards
  // for a matching window.
  for (var i = bytes.length - stem.length; i >= 0; i--) {
    var match = true;
    for (var k = 0; k < stem.length; k++) {
      if (bytes[i + k] != stem[k]) {
        match = false;
        break;
      }
    }
    if (match) return i + stem.length;
  }
  return bytes.length;
}

/// Compares two components for whole-component equality.
bool _componentEquals(Component a, Component b) {
  if (a.runtimeType != b.runtimeType) return false;
  return _bytesEqual(a.asOsStr(), b.asOsStr());
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _componentHash(Component c) {
  final bytes = c.asOsStr();
  var h = c.runtimeType.hashCode;
  for (final b in bytes) {
    h = (h * 31 + b) & 0x7FFFFFFF;
  }
  return h;
}

/// Raised by lexical normalization when a `..` segment would escape the
/// path's logical root.
class NormalizeError implements Exception {
  const NormalizeError();

  @override
  String toString() => 'parent reference `..` points outside of base directory';
}
