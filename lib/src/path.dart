import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/src/code_units.dart';
import 'package:pathify/src/component.dart';
import 'package:pathify/src/components.dart';
import 'package:pathify/src/path_bytes.dart';
import 'package:pathify/src/pathify_platform.dart';
import 'package:pathify/src/prefix.dart';
import 'package:pathify/src/sys/path/unix_style.dart';
import 'package:pathify/src/sys/path/windows_prefix.dart';
import 'package:pathify/src/sys/path/windows_style.dart';

export 'package:pathify/src/code_units.dart';
export 'package:pathify/src/component.dart';
export 'package:pathify/src/components.dart';
export 'package:pathify/src/prefix.dart';

/// An owned, mutable path.
///
/// Stores raw code units — [Uint8List] for POSIX paths, [Uint16List] for
/// Windows paths — and exposes inspection (parent, file name, components)
/// and mutation (push, pop, set extension) operations on top.
///
/// The path's style is determined intrinsically by the storage type:
/// `Uint16List` is always Windows; `Uint8List` is always POSIX. The
/// platform reported by [Pathify.instance] only affects construction-time
/// assertions and the choice of style for the [PathBuf.fromBytes] entry
/// point.
///
/// All internal operations use the [CodeUnits] abstraction, which
/// preserves the full range of each code unit. POSIX paths can carry
/// arbitrary bytes (including non-UTF-8 sequences); Windows paths can
/// carry the full UTF-16 range (including unpaired surrogates) — both
/// flow through every operation without truncation.
final class PathBuf {
  PathBuf._(this._units);

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
    return PathBuf._(CodeUnits.from(bytes));
  }

  /// Builds a path from a Dart [String], encoding it for the active
  /// platform.
  ///
  /// On POSIX the string is encoded as UTF-8 bytes. On Windows it is
  /// stored directly as UTF-16 code units (Dart's internal string
  /// representation is already UTF-16, so this is a zero-loss copy).
  factory PathBuf.fromStr(String s) {
    if (Pathify.instance.isWindows()) {
      return PathBuf._(WideCodeUnits(Uint16List.fromList(s.codeUnits)));
    }
    return PathBuf._(NarrowCodeUnits(Uint8List.fromList(utf8.encode(s))));
  }

  /// Builds an empty path. Storage type matches the active platform.
  factory PathBuf.empty() {
    if (Pathify.instance.isWindows()) {
      return PathBuf._(WideCodeUnits(Uint16List(0)));
    }
    return PathBuf._(NarrowCodeUnits(Uint8List(0)));
  }

  CodeUnits _units;

  // ── String conversion ────────────────────────────────────────────────

  /// Decodes the path as a Dart [String] when the code units are valid
  /// Unicode, otherwise returns `null`.
  String? toStr() {
    if (_units is NarrowCodeUnits) {
      try {
        return utf8.decode(
          (_units as NarrowCodeUnits).toTypedData(),
          allowMalformed: false,
        );
      } on FormatException {
        return null;
      }
    }
    final wide = (_units as WideCodeUnits).toTypedData();
    for (var i = 0; i < wide.length; i++) {
      final cu = wide[i];
      if (cu >= 0xD800 && cu <= 0xDBFF) {
        if (i + 1 >= wide.length) return null;
        final next = wide[i + 1];
        if (next < 0xDC00 || next > 0xDFFF) return null;
        i++;
      } else if (cu >= 0xDC00 && cu <= 0xDFFF) {
        return null;
      }
    }
    return String.fromCharCodes(wide);
  }

  /// Decodes the path as a Dart [String], substituting U+FFFD for any
  /// code units that are not valid Unicode under the active encoding.
  String toStringLossy() {
    if (_units is NarrowCodeUnits) {
      return utf8.decode(
        (_units as NarrowCodeUnits).toTypedData(),
        allowMalformed: true,
      );
    }
    final wide = (_units as WideCodeUnits).toTypedData();
    final out = StringBuffer();
    for (var i = 0; i < wide.length; i++) {
      final cu = wide[i];
      if (cu >= 0xD800 && cu <= 0xDBFF) {
        if (i + 1 < wide.length) {
          final next = wide[i + 1];
          if (next >= 0xDC00 && next <= 0xDFFF) {
            out
              ..writeCharCode(cu)
              ..writeCharCode(next);
            i++;
            continue;
          }
        }
        out.writeCharCode(0xFFFD);
      } else if (cu >= 0xDC00 && cu <= 0xDFFF) {
        out.writeCharCode(0xFFFD);
      } else {
        out.writeCharCode(cu);
      }
    }
    return out.toString();
  }

  // ── Storage access ───────────────────────────────────────────────────

  bool get _isWindowsStyle => _units.isWide;

  /// The raw underlying storage as supplied to [PathBuf.fromBytes].
  TypedData get bytes => _units.toTypedData();

  /// The path content as a [CodeUnits] view.
  CodeUnits get codeUnits => _units;

  /// Whether this path uses Windows path semantics.
  ///
  /// Derived from the storage type, not from the global platform.
  bool get isWindows => _isWindowsStyle;

  /// Whether this path uses POSIX path semantics.
  bool get isUnix => !isWindows;

  /// True when the path contains no code units.
  bool get isEmpty => _units.isEmpty;

  /// The number of code units in the path.
  int get length => _units.length;

  // ── Prefix and structure ─────────────────────────────────────────────

  /// The parsed Windows prefix, or `null` when the path has none.
  ///
  /// On POSIX this is always `null`. On Windows, runs the cascade prefix
  /// parser over the leading bytes.
  Prefix? prefix() {
    if (!_isWindowsStyle) return null;
    return WindowsPrefix.parsePrefix(_units);
  }

  /// True when the path has a leading root.
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
    pathBytes: _units,
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
  CodeUnits? fileName() {
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
  CodeUnits? fileStem() {
    final name = fileName();
    if (name == null) return null;
    final (before, after) = _rsplitAtDot(name);
    return before ?? after;
  }

  /// The portion of [fileName] preceding the first dot.
  ///
  /// For dotfiles such as `.config`, the leading dot is preserved and the
  /// result is the whole name. Returns `null` when there is no file name.
  CodeUnits? filePrefix() {
    final name = fileName();
    if (name == null) return null;
    final (before, _) = _splitAtDot(name);
    return before;
  }

  /// The file extension, without its leading dot.
  ///
  /// Returns `null` when there is no file name, no embedded dot, or when
  /// the file name begins with a dot and has no other dots within.
  CodeUnits? extension() {
    final name = fileName();
    if (name == null) return null;
    final (before, after) = _rsplitAtDot(name);
    if (before != null && after != null) return after;
    return null;
  }

  /// True when the path ends in a separator code unit.
  bool hasTrailingSep() {
    if (isEmpty) return false;
    final last = _units[_units.length - 1];
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
    final myPrefix = prefix();
    final theirPrefix = path.prefix();

    var needSep = _units.isNotEmpty && !_isSepHere(_units[_units.length - 1]);

    final myPrefixLen = myPrefix?.len ?? 0;
    if (myPrefixLen > 0 && myPrefixLen == _units.length && myPrefix!.isDrive) {
      needSep = false;
    }

    final pathIsAbsolute = path.isAbsolute() || theirPrefix != null;
    if (pathIsAbsolute) {
      _units = path._units;
      return;
    }

    final receiverIsVerbatim = myPrefix != null && myPrefix.isVerbatim;
    if (receiverIsVerbatim && path._units.isNotEmpty) {
      _pushVerbatim(path);
      return;
    }

    if (path.hasRoot()) {
      // Path has a root but no prefix; replace everything after this path's
      // existing prefix.
      _truncate(myPrefixLen);
    } else if (needSep) {
      _appendCodeUnit(_mainSepByte());
    }

    _appendCodeUnits(path._units);
  }

  void _pushVerbatim(PathBuf path) {
    final selfComps = components().toList();
    final buf = <Component>[...selfComps];

    for (final c in path.components().toList()) {
      if (c is ComponentRootDir) {
        while (buf.length > 1) {
          buf.removeLast();
        }
        buf.add(c);
      } else if (c is ComponentCurDir) {
        continue;
      } else if (c is ComponentParentDir) {
        if (buf.isNotEmpty && buf.last is ComponentNormal) {
          buf.removeLast();
        }
      } else {
        buf.add(c);
      }
    }

    // Reassemble. Drive prefixes get no automatic separator after them;
    // non-drive non-empty prefixes do.
    var result = _emptyOfSameWidth();
    var needSep = false;
    for (final c in buf) {
      if (needSep && c is! ComponentRootDir) {
        result = result.appendCodeUnit(_mainSepByte());
      }
      result = result.concat(c.asOsStr());

      if (c is ComponentRootDir) {
        needSep = false;
      } else if (c is ComponentPrefix) {
        final p = c.parsed;
        needSep = !p.isDrive && p.len > 0;
      } else {
        needSep = true;
      }
    }

    _units = result;
  }

  bool pop() {
    final p = parent();
    if (p == null) return false;
    _units = p._units;
    return true;
  }

  /// Replaces the final component with [fileName].
  ///
  /// When the path has no file name (e.g. it ends in a separator), the
  /// supplied name is appended.
  void setFileName(CodeUnits fileName) {
    if (this.fileName() != null) {
      pop();
    }
    push(_materialize(fileName));
  }

  /// Replaces the file extension with [extension].
  ///
  /// When [extension] is empty the existing extension is removed. When the
  /// path has no file name nothing happens and `false` is returned.
  bool setExtension(CodeUnits extension) {
    _validateExtension(extension);
    final stem = fileStem();
    if (stem == null) return false;

    final stemEnd = _findStemEnd(_units, stem);
    _truncate(stemEnd);

    if (extension.isNotEmpty) {
      _appendCodeUnit(PathBytes.dot);
      _appendCodeUnits(extension);
    }
    return true;
  }

  /// Appends [extension] to the path's existing extension without removing
  /// it.
  ///
  /// When the path has no file name nothing happens and `false` is
  /// returned.
  bool addExtension(CodeUnits extension) {
    _validateExtension(extension);
    final name = fileName();
    if (name == null) return false;

    if (extension.isNotEmpty) {
      final nameEnd = _findFileNameEnd(_units, name);
      _truncate(nameEnd);

      _appendCodeUnit(PathBytes.dot);
      _appendCodeUnits(extension);
    }
    return true;
  }

  /// Empties the path.
  void clear() {
    _units = _emptyOfSameWidth();
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
  PathBuf withFileName(CodeUnits fileName) {
    final out = _clone()..setFileName(fileName);
    return out;
  }

  /// Returns a new path with the extension replaced.
  PathBuf withExtension(CodeUnits extension) {
    final out = _clone()..setExtension(extension);
    return out;
  }

  /// Returns a new path with [extension] appended to the existing extension.
  PathBuf withAddedExtension(CodeUnits extension) {
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

  CodeUnits _emptyOfSameWidth() => _units.emptyOfSameWidth();

  void _truncate(int newLength) {
    _units = _units.sublistView(0, newLength);
  }

  void _appendCodeUnit(int unit) {
    _units = _units.appendCodeUnit(unit);
  }

  void _appendCodeUnits(CodeUnits src) {
    if (src.isWide != _units.isWide) {
      // Cross-width append: widen or narrow `src` to match `_units`.
      // This happens when the caller passes a `CodeUnits` of the wrong
      // width (e.g. an extension built as Uint8List for a Windows path).
      // We convert by zero-extending or low-byte-truncating as needed.
      _units = _units.concat(_coerceWidth(src));
    } else {
      _units = _units.concat(src);
    }
  }

  CodeUnits _coerceWidth(CodeUnits src) {
    if (src.isWide == _units.isWide) return src;
    if (_units.isWide) {
      // Widen Uint8List -> Uint16List by zero-extending each byte.
      final out = Uint16List(src.length);
      for (var i = 0; i < src.length; i++) {
        out[i] = src[i];
      }
      return WideCodeUnits(out);
    }
    // Narrow Uint16List -> Uint8List. We use the low byte; this is
    // correct for ASCII payloads (extensions, file names that are all
    // ASCII) and is the lossless choice when the caller has already
    // validated the input.
    final out = Uint8List(src.length);
    for (var i = 0; i < src.length; i++) {
      out[i] = src[i] & 0xFF;
    }
    return NarrowCodeUnits(out);
  }

  PathBuf _clone() => PathBuf._(_units.clone());

  /// Builds a fresh [PathBuf] of the same style from the given code-unit
  /// view.
  PathBuf _materialize(CodeUnits src) {
    if (src.isWide == _isWindowsStyle) {
      // Same width — clone to detach from any sublist view sharing.
      return PathBuf._(src.clone());
    }
    // Different width — coerce. Same logic as `_coerceWidth`.
    if (_isWindowsStyle) {
      final out = Uint16List(src.length);
      for (var i = 0; i < src.length; i++) {
        out[i] = src[i];
      }
      return PathBuf._(WideCodeUnits(out));
    }
    final out = Uint8List(src.length);
    for (var i = 0; i < src.length; i++) {
      out[i] = src[i] & 0xFF;
    }
    return PathBuf._(NarrowCodeUnits(out));
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

  static void _validateExtension(CodeUnits ext) {
    for (var i = 0; i < ext.length; i++) {
      final b = ext[i];
      if (UnixStyle.isSepByte(b) || WindowsStyle.isSepByte(b)) {
        throw ArgumentError(
          'extension cannot contain path separators',
        );
      }
    }
  }
}

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
(CodeUnits?, CodeUnits?) _rsplitAtDot(CodeUnits file) {
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

  final before = file.sublistView(0, dotAt);
  final after = file.sublistView(dotAt + 1);
  if (before.isEmpty) return (file, null);
  return (before, after);
}

/// Splits [file] into `(before, after)` around the first non-leading dot.
///
/// Used for [PathBuf.filePrefix].
(CodeUnits, CodeUnits?) _splitAtDot(CodeUnits file) {
  if (file.length == 2 &&
      file[0] == PathBytes.dot &&
      file[1] == PathBytes.dot) {
    return (file, null);
  }
  var i = -1;
  for (var k = 1; k < file.length; k++) {
    if (file[k] == PathBytes.dot) {
      i = k;
      break;
    }
  }
  if (i < 0) return (file, null);
  return (file.sublistView(0, i), file.sublistView(i + 1));
}

/// Locates the code-unit index immediately after [stem] within [units].
///
/// Used by [PathBuf.setExtension] to truncate the path to the stem.
int _findStemEnd(CodeUnits units, CodeUnits stem) {
  // The stem is always a slice from the end of the path. Search backwards
  // for a matching window.
  for (var i = units.length - stem.length; i >= 0; i--) {
    var match = true;
    for (var k = 0; k < stem.length; k++) {
      if (units[i + k] != stem[k]) {
        match = false;
        break;
      }
    }
    if (match) return i + stem.length;
  }
  return units.length;
}

/// Locates the code-unit index immediately after the last occurrence of
/// [name] within [units].
int _findFileNameEnd(CodeUnits units, CodeUnits name) {
  for (var i = units.length - name.length; i >= 0; i--) {
    var match = true;
    for (var k = 0; k < name.length; k++) {
      if (units[i + k] != name[k]) {
        match = false;
        break;
      }
    }
    if (match) return i + name.length;
  }
  return units.length;
}

bool _componentEquals(Component a, Component b) {
  if (a.runtimeType != b.runtimeType) return false;

  if (a is ComponentPrefix && b is ComponentPrefix) {
    return _prefixEquals(a.parsed, b.parsed);
  }

  return a.asOsStr().equalsCodeUnits(b.asOsStr());
}

bool _prefixEquals(Prefix a, Prefix b) {
  if (a.runtimeType != b.runtimeType) return false;
  switch (a) {
    case Disk():
      return a.drive == (b as Disk).drive;
    case VerbatimDisk():
      return a.drive == (b as VerbatimDisk).drive;
    case Verbatim():
      return a.component.equalsCodeUnits((b as Verbatim).component);
    case DeviceNS():
      return a.device.equalsCodeUnits((b as DeviceNS).device);
    case UNC():
      final other = b as UNC;
      return a.server.equalsCodeUnits(other.server) &&
          a.share.equalsCodeUnits(other.share);
    case VerbatimUNC():
      final other = b as VerbatimUNC;
      return a.server.equalsCodeUnits(other.server) &&
          a.share.equalsCodeUnits(other.share);
  }
}

int _componentHash(Component c) {
  if (c is ComponentPrefix) {
    return _prefixHash(c.parsed);
  }
  final units = c.asOsStr();
  var h = c.runtimeType.hashCode;
  for (var i = 0; i < units.length; i++) {
    h = (h * 31 + units[i]) & 0x7FFFFFFF;
  }
  return h;
}

int _prefixHash(Prefix p) {
  var h = p.runtimeType.hashCode;
  switch (p) {
    case Disk():
      h = (h * 31 + p.drive) & 0x7FFFFFFF;
    case VerbatimDisk():
      h = (h * 31 + p.drive) & 0x7FFFFFFF;
    case Verbatim():
      for (var i = 0; i < p.component.length; i++) {
        h = (h * 31 + p.component[i]) & 0x7FFFFFFF;
      }
    case DeviceNS():
      for (var i = 0; i < p.device.length; i++) {
        h = (h * 31 + p.device[i]) & 0x7FFFFFFF;
      }
    case UNC():
      for (var i = 0; i < p.server.length; i++) {
        h = (h * 31 + p.server[i]) & 0x7FFFFFFF;
      }
      for (var i = 0; i < p.share.length; i++) {
        h = (h * 31 + p.share[i]) & 0x7FFFFFFF;
      }
    case VerbatimUNC():
      for (var i = 0; i < p.server.length; i++) {
        h = (h * 31 + p.server[i]) & 0x7FFFFFFF;
      }
      for (var i = 0; i < p.share.length; i++) {
        h = (h * 31 + p.share[i]) & 0x7FFFFFFF;
      }
  }
  return h;
}

class NormalizeError implements Exception {
  const NormalizeError();

  @override
  String toString() => 'parent reference `..` points outside of base directory';
}
