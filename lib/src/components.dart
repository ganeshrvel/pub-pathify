import 'dart:typed_data';

import 'package:pathify/src/component.dart';
import 'package:pathify/src/path_bytes.dart';
import 'package:pathify/src/prefix.dart';
import 'package:pathify/src/sys/path/unix_style.dart';
import 'package:pathify/src/sys/path/windows_style.dart';

/// Internal cursor states used by the components iterator.
///
/// The iterator advances through these in order from the front (and in
/// reverse from the back), producing one [Component] per state when one is
/// available. This double-ended structure is what allows efficient
/// `parent()`, `strip_prefix()`, and `ends_with()` implementations.
enum _State {
  /// The Windows prefix has not yet been consumed.
  prefix,

  /// The leading root separator (or leading `.` for relative paths) has not
  /// yet been consumed.
  startDir,

  /// Iterating through the body of the path.
  body,

  /// Iteration is complete from this end.
  done,
}

/// A double-ended iterator over the components of a path.
///
/// The iterator performs minimal normalization while yielding components:
///
///   * Repeated separators are skipped, so `a//b` yields `a` and `b`.
///   * Internal `.` segments are skipped; a leading `.` in a relative path
///     is preserved as [ComponentCurDir].
///   * Trailing separators are skipped, so `/a/b` and `/a/b/` iterate
///     identically.
///
/// `..` segments are not resolved and are produced as [ComponentParentDir],
/// because resolving them in general requires filesystem knowledge (a
/// component might be a symbolic link).
class Components {
  Components._({
    required this.isWindows,
    required this.path,
    required this.prefix,
    required this.hasPhysicalRoot,
    required _State front,
    required _State back,
  }) : _front = front,
       _back = back;

  /// Builds an iterator for the given [pathBytes].
  ///
  /// [prefix] should be the result of running the prefix parser on
  /// [pathBytes] (or `null` when on POSIX).
  factory Components.start({
    required Uint8List pathBytes,
    required Prefix? prefix,
    required bool isWindows,
  }) {
    final hasPhysicalRoot = _hasPhysicalRoot(pathBytes, prefix, isWindows);
    final initialFront = _hasPrefixesFor(isWindows)
        ? _State.prefix
        : _State.startDir;
    return Components._(
      isWindows: isWindows,
      path: pathBytes,
      prefix: prefix,
      hasPhysicalRoot: hasPhysicalRoot,
      front: initialFront,
      back: _State.body,
    );
  }

  /// Whether the underlying path uses Windows path semantics.
  ///
  /// Determines which separator predicate applies, whether prefixes are
  /// recognized, and how the start-directory state behaves.
  final bool isWindows;

  /// The path bytes that have not yet been consumed by either cursor.
  Uint8List path;

  /// The Windows prefix, if any, parsed once at iterator construction.
  final Prefix? prefix;

  /// Whether the source path has a physical root separator immediately after
  /// the prefix.
  ///
  /// Some Windows prefixes (UNC, device namespace) imply a root logically
  /// even when no separator byte follows; that is tracked separately via
  /// [Prefix.hasImplicitRoot].
  final bool hasPhysicalRoot;

  _State _front;
  _State _back;

  /// Produces a copy of this iterator with the same cursor positions.
  Components clone() => Components._(
    isWindows: isWindows,
    path: path,
    prefix: prefix,
    hasPhysicalRoot: hasPhysicalRoot,
    front: _front,
    back: _back,
  );

  /// The bytes corresponding to the portion of the path that has not yet
  /// been consumed from either end.
  ///
  /// Trims trailing repeated-separator runs from the right and trailing
  /// repeated-separator runs from the left, then returns the remaining
  /// slice. Useful for reconstructing a sub-path from a partially advanced
  /// iterator.
  Uint8List asPathBytes() {
    final clone = this.clone();
    if (clone._front == _State.body) clone._trimLeft();
    if (clone._back == _State.body) clone._trimRight();
    return clone.path;
  }

  /// True when the path has a leading root, either physically or implied by
  /// its prefix.
  bool hasRoot() {
    if (hasPhysicalRoot) return true;
    if (_hasPrefixesFor(isWindows) && prefix != null) {
      if (prefix!.hasImplicitRoot) return true;
    }
    return false;
  }

  // ── Iteration ──────────────────────────────────────────────────────────

  /// Advances the front cursor and returns the next component, or `null`
  /// when the iterator is exhausted from this end.
  Component? next() {
    while (!_finished()) {
      switch (_front) {
        case _State.body:
          if (path.isNotEmpty) {
            final (size, comp) = _parseNextComponent();
            path = Uint8List.sublistView(path, size);
            if (comp != null) return comp;
          } else {
            _front = _State.done;
          }
        case _State.startDir:
          _front = _State.body;
          if (hasPhysicalRoot) {
            assert(
              path.isNotEmpty,
              'physical root expects a leading separator byte',
            );
            path = Uint8List.sublistView(path, 1);
            return ComponentRootDir(_mainSepFor(isWindows));
          } else if (_hasPrefixesFor(isWindows) && prefix != null) {
            if (prefix!.hasImplicitRoot && !prefix!.isVerbatim) {
              return ComponentRootDir(_mainSepFor(isWindows));
            }
          } else if (_includeCurDir()) {
            assert(
              path.isNotEmpty,
              'curdir state expects at least one byte to consume',
            );
            path = Uint8List.sublistView(path, 1);
            return const ComponentCurDir();
          }
        case _State.prefix:
          if (!_hasPrefixesFor(isWindows)) {
            _front = _State.startDir;
          } else if (_prefixLen() == 0) {
            _front = _State.startDir;
          } else {
            _front = _State.startDir;
            assert(
              _prefixLen() <= path.length,
              'prefix length must not exceed remaining path',
            );
            final raw = Uint8List.sublistView(path, 0, _prefixLen());
            path = Uint8List.sublistView(path, _prefixLen());
            return ComponentPrefix(raw: raw, parsed: prefix!);
          }
        case _State.done:
          throw StateError('components iterator advanced past completion');
      }
    }
    return null;
  }

  /// Advances the back cursor and returns the previous component, or `null`
  /// when the iterator is exhausted from this end.
  Component? nextBack() {
    while (!_finished()) {
      switch (_back) {
        case _State.body:
          if (path.length > _lenBeforeBody()) {
            final (size, comp) = _parseNextComponentBack();
            path = Uint8List.sublistView(path, 0, path.length - size);
            if (comp != null) return comp;
          } else {
            _back = _State.startDir;
          }
        case _State.startDir:
          _back = _hasPrefixesFor(isWindows) ? _State.prefix : _State.done;
          if (hasPhysicalRoot) {
            path = Uint8List.sublistView(path, 0, path.length - 1);
            return ComponentRootDir(_mainSepFor(isWindows));
          } else if (_hasPrefixesFor(isWindows) && prefix != null) {
            if (prefix!.hasImplicitRoot && !prefix!.isVerbatim) {
              return ComponentRootDir(_mainSepFor(isWindows));
            }
          } else if (_includeCurDir()) {
            path = Uint8List.sublistView(path, 0, path.length - 1);
            return const ComponentCurDir();
          }
        case _State.prefix:
          if (!_hasPrefixesFor(isWindows)) {
            _back = _State.done;
            return null;
          } else if (_prefixLen() > 0) {
            _back = _State.done;
            return ComponentPrefix(raw: path, parsed: prefix!);
          } else {
            _back = _State.done;
            return null;
          }
        case _State.done:
          throw StateError('components iterator advanced past completion');
      }
    }
    return null;
  }

  /// Pulls all remaining components into a list, advancing the front cursor
  /// to completion.
  List<Component> toList() {
    final out = <Component>[];
    Component? c;
    while ((c = next()) != null) {
      out.add(c!);
    }
    return out;
  }

  /// Pulls all remaining components in reverse order, advancing the back
  /// cursor to completion.
  List<Component> toListReversed() {
    final out = <Component>[];
    Component? c;
    while ((c = nextBack()) != null) {
      out.add(c!);
    }
    return out;
  }

  // ── Internal helpers ──────────────────────────────────────────────────

  int _prefixLen() {
    if (!_hasPrefixesFor(isWindows)) return 0;
    return prefix?.len ?? 0;
  }

  bool _prefixVerbatim() {
    if (!_hasPrefixesFor(isWindows)) return false;
    return prefix?.isVerbatim ?? false;
  }

  int _prefixRemaining() {
    if (!_hasPrefixesFor(isWindows)) return 0;
    return _front == _State.prefix ? _prefixLen() : 0;
  }

  /// The number of code units occupied by the prefix and start-of-path
  /// elements (root, leading `.`) that have not yet been consumed.
  int _lenBeforeBody() {
    final root = (_front.index <= _State.startDir.index && hasPhysicalRoot)
        ? 1
        : 0;
    final curDir = (_front.index <= _State.startDir.index && _includeCurDir())
        ? 1
        : 0;
    return _prefixRemaining() + root + curDir;
  }

  bool _finished() =>
      _front == _State.done ||
      _back == _State.done ||
      _front.index > _back.index;

  /// True when [b] should be treated as a separator at the current cursor
  /// position.
  ///
  /// Verbatim paths recognize only `\`; all other paths recognize the
  /// platform's separator set.
  bool _isSepHere(int b) {
    if (_prefixVerbatim()) {
      return _isVerbatimSepFor(isWindows, b);
    }
    return _isSepByteFor(isWindows, b);
  }

  /// True when the path begins with a `.` followed by a separator (or the
  /// `.` is the entire remaining path), making it a current-directory
  /// reference that should be preserved as a leading [ComponentCurDir].
  bool _includeCurDir() {
    if (hasRoot()) return false;
    final start = _prefixRemaining();
    if (start >= path.length) return false;
    if (path[start] != PathBytes.dot) return false;
    if (start + 1 == path.length) return true;
    return _isSepHere(path[start + 1]);
  }

  /// Identifies what kind of [Component] (if any) a raw byte slice
  /// represents.
  ///
  /// Empty slices and `.` segments (outside the leading-curdir case) return
  /// `null` so the iterator skips them. Verbatim paths preserve `.` as
  /// [ComponentCurDir] because verbatim disables normalization.
  Component? _classify(Uint8List comp) {
    if (comp.isEmpty) return null;
    if (comp.length == 1 && comp[0] == PathBytes.dot) {
      if (_hasPrefixesFor(isWindows) && _prefixVerbatim()) {
        return const ComponentCurDir();
      }
      return null;
    }
    if (comp.length == 2 &&
        comp[0] == PathBytes.dot &&
        comp[1] == PathBytes.dot) {
      return const ComponentParentDir();
    }
    return ComponentNormal(comp);
  }

  /// Splits off the next component from the front, returning the number of
  /// bytes to advance and the classified component (if any).
  (int, Component?) _parseNextComponent() {
    var sepIdx = -1;
    for (var i = 0; i < path.length; i++) {
      if (_isSepHere(path[i])) {
        sepIdx = i;
        break;
      }
    }
    if (sepIdx == -1) {
      return (path.length, _classify(path));
    }
    final comp = Uint8List.sublistView(path, 0, sepIdx);
    return (sepIdx + 1, _classify(comp));
  }

  /// Splits off the next component from the back, returning the number of
  /// bytes to retract and the classified component (if any).
  (int, Component?) _parseNextComponentBack() {
    final start = _lenBeforeBody();
    var sepIdx = -1;
    for (var i = path.length - 1; i >= start; i--) {
      if (_isSepHere(path[i])) {
        sepIdx = i - start;
        break;
      }
    }
    if (sepIdx == -1) {
      final comp = Uint8List.sublistView(path, start);
      return (path.length - start, _classify(comp));
    }
    final compStart = start + sepIdx + 1;
    final comp = Uint8List.sublistView(path, compStart);
    return (comp.length + 1, _classify(comp));
  }

  /// Removes runs of empty components (produced by repeated separators) from
  /// the front of the unconsumed path.
  void _trimLeft() {
    while (path.isNotEmpty) {
      final (size, comp) = _parseNextComponent();
      if (comp != null) return;
      path = Uint8List.sublistView(path, size);
    }
  }

  /// Removes runs of empty components from the back of the unconsumed path.
  void _trimRight() {
    while (path.length > _lenBeforeBody()) {
      final (size, comp) = _parseNextComponentBack();
      if (comp != null) return;
      path = Uint8List.sublistView(path, 0, path.length - size);
    }
  }
}

/// An iterator that yields each component's bytes directly, dropping the
/// structural [Component] wrapper.
///
/// Useful when callers only need the raw segment bytes and have already
/// classified the path some other way.
class Iter {
  Iter(this._inner);

  final Components _inner;

  /// Pulls the next component's bytes.
  Uint8List? next() {
    final c = _inner.next();
    return c?.asOsStr();
  }

  /// Pulls the previous component's bytes.
  Uint8List? nextBack() {
    final c = _inner.nextBack();
    return c?.asOsStr();
  }

  /// The unconsumed portion of the underlying path.
  Uint8List asPathBytes() => _inner.asPathBytes();
}

// ── Style dispatch helpers ─────────────────────────────────────────────────

bool _hasPrefixesFor(bool isWindows) =>
    isWindows ? WindowsStyle.hasPrefixes : UnixStyle.hasPrefixes;

int _mainSepFor(bool isWindows) =>
    isWindows ? WindowsStyle.mainSep : UnixStyle.mainSep;

bool _isSepByteFor(bool isWindows, int b) =>
    isWindows ? WindowsStyle.isSepByte(b) : UnixStyle.isSepByte(b);

bool _isVerbatimSepFor(bool isWindows, int b) =>
    isWindows ? WindowsStyle.isVerbatimSep(b) : UnixStyle.isVerbatimSep(b);

/// True when [path], with the given parsed [prefix], physically begins with
/// a separator immediately after the prefix bytes.
///
/// This is distinct from logical rooting via [Prefix.hasImplicitRoot]; some
/// prefixes (UNC, device namespace) imply a root even when no separator byte
/// follows. Both signals are tracked separately by the iterator.
bool _hasPhysicalRoot(Uint8List path, Prefix? prefix, bool isWindows) {
  final start = prefix?.len ?? 0;
  if (start >= path.length) return false;
  return _isSepByteFor(isWindows, path[start]);
}
