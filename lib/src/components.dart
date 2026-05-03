import 'package:pathify/src/code_units.dart';
import 'package:pathify/src/component.dart';
import 'package:pathify/src/path_bytes.dart';
import 'package:pathify/src/prefix.dart';
import 'package:pathify/src/sys/path/unix_style.dart';
import 'package:pathify/src/sys/path/windows_style.dart';

enum _State { prefix, startDir, body, done }

/// A double-ended iterator over the components of a path.
///
/// Operates on [CodeUnits], so non-ASCII code units (UTF-16 surrogates,
/// non-ASCII UTF-8 bytes) flow through every slice and component verbatim.
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

  factory Components.start({
    required CodeUnits pathBytes,
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

  final bool isWindows;
  CodeUnits path;
  final Prefix? prefix;
  final bool hasPhysicalRoot;

  _State _front;
  _State _back;

  Components clone() => Components._(
    isWindows: isWindows,
    path: path,
    prefix: prefix,
    hasPhysicalRoot: hasPhysicalRoot,
    front: _front,
    back: _back,
  );

  /// The unconsumed portion of the path as a [CodeUnits] view.
  CodeUnits asPathBytes() {
    final clone = this.clone();
    if (clone._front == _State.body) clone._trimLeft();
    if (clone._back == _State.body) clone._trimRight();
    return clone.path;
  }

  bool hasRoot() {
    if (hasPhysicalRoot) return true;
    if (_hasPrefixesFor(isWindows) && prefix != null) {
      if (prefix!.hasImplicitRoot) return true;
    }
    return false;
  }

  Component? next() {
    while (!_finished()) {
      switch (_front) {
        case _State.body:
          if (path.isNotEmpty) {
            final (size, comp) = _parseNextComponent();
            path = path.sublistView(size);
            if (comp != null) return comp;
          } else {
            _front = _State.done;
          }
        case _State.startDir:
          _front = _State.body;
          if (hasPhysicalRoot) {
            assert(
              path.isNotEmpty,
              'physical root expects a leading separator code unit',
            );
            path = path.sublistView(1);
            return ComponentRootDir(_mainSepFor(isWindows), isWide: isWindows);
          } else if (_hasPrefixesFor(isWindows) && prefix != null) {
            if (prefix!.hasImplicitRoot && !prefix!.isVerbatim) {
              return ComponentRootDir(
                _mainSepFor(isWindows),
                isWide: isWindows,
              );
            }
          } else if (_includeCurDir()) {
            assert(
              path.isNotEmpty,
              'curdir state expects at least one code unit to consume',
            );
            path = path.sublistView(1);
            return ComponentCurDir(isWide: isWindows);
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
            final raw = path.sublistView(0, _prefixLen());
            path = path.sublistView(_prefixLen());
            return ComponentPrefix(raw: raw, parsed: prefix!);
          }
        case _State.done:
          throw StateError('components iterator advanced past completion');
      }
    }
    return null;
  }

  Component? nextBack() {
    while (!_finished()) {
      switch (_back) {
        case _State.body:
          if (path.length > _lenBeforeBody()) {
            final (size, comp) = _parseNextComponentBack();
            path = path.sublistView(0, path.length - size);
            if (comp != null) return comp;
          } else {
            _back = _State.startDir;
          }
        case _State.startDir:
          _back = _hasPrefixesFor(isWindows) ? _State.prefix : _State.done;
          if (hasPhysicalRoot) {
            path = path.sublistView(0, path.length - 1);
            return ComponentRootDir(_mainSepFor(isWindows), isWide: isWindows);
          } else if (_hasPrefixesFor(isWindows) && prefix != null) {
            if (prefix!.hasImplicitRoot && !prefix!.isVerbatim) {
              return ComponentRootDir(
                _mainSepFor(isWindows),
                isWide: isWindows,
              );
            }
          } else if (_includeCurDir()) {
            path = path.sublistView(0, path.length - 1);
            return ComponentCurDir(isWide: isWindows);
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

  List<Component> toList() {
    final out = <Component>[];
    Component? c;
    while ((c = next()) != null) {
      out.add(c!);
    }
    return out;
  }

  List<Component> toListReversed() {
    final out = <Component>[];
    Component? c;
    while ((c = nextBack()) != null) {
      out.add(c!);
    }
    return out;
  }

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

  bool _isSepHere(int b) {
    if (_prefixVerbatim()) {
      return _isVerbatimSepFor(isWindows, b);
    }
    return _isSepByteFor(isWindows, b);
  }

  bool _includeCurDir() {
    if (hasRoot()) return false;
    final start = _prefixRemaining();
    if (start >= path.length) return false;
    if (path[start] != PathBytes.dot) return false;
    if (start + 1 == path.length) return true;
    return _isSepHere(path[start + 1]);
  }

  Component? _classify(CodeUnits comp) {
    if (comp.isEmpty) return null;
    if (comp.length == 1 && comp[0] == PathBytes.dot) {
      if (_hasPrefixesFor(isWindows) && _prefixVerbatim()) {
        return ComponentCurDir(isWide: isWindows);
      }
      return null;
    }
    if (comp.length == 2 &&
        comp[0] == PathBytes.dot &&
        comp[1] == PathBytes.dot) {
      return ComponentParentDir(isWide: isWindows);
    }
    return ComponentNormal(comp);
  }

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
    final comp = path.sublistView(0, sepIdx);
    return (sepIdx + 1, _classify(comp));
  }

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
      final comp = path.sublistView(start);
      return (path.length - start, _classify(comp));
    }
    final compStart = start + sepIdx + 1;
    final comp = path.sublistView(compStart);
    return (comp.length + 1, _classify(comp));
  }

  void _trimLeft() {
    while (path.isNotEmpty) {
      final (size, comp) = _parseNextComponent();
      if (comp != null) return;
      path = path.sublistView(size);
    }
  }

  void _trimRight() {
    while (path.length > _lenBeforeBody()) {
      final (size, comp) = _parseNextComponentBack();
      if (comp != null) return;
      path = path.sublistView(0, path.length - size);
    }
  }
}

/// An iterator that yields each component's code units directly.
class Iter {
  Iter(this._inner);

  final Components _inner;

  CodeUnits? next() => _inner.next()?.asOsStr();

  CodeUnits? nextBack() => _inner.nextBack()?.asOsStr();

  CodeUnits asPathBytes() => _inner.asPathBytes();
}

bool _hasPrefixesFor(bool isWindows) =>
    isWindows ? WindowsStyle.hasPrefixes : UnixStyle.hasPrefixes;

int _mainSepFor(bool isWindows) =>
    isWindows ? WindowsStyle.mainSep : UnixStyle.mainSep;

bool _isSepByteFor(bool isWindows, int b) =>
    isWindows ? WindowsStyle.isSepByte(b) : UnixStyle.isSepByte(b);

bool _isVerbatimSepFor(bool isWindows, int b) =>
    isWindows ? WindowsStyle.isVerbatimSep(b) : UnixStyle.isVerbatimSep(b);

bool _hasPhysicalRoot(CodeUnits path, Prefix? prefix, bool isWindows) {
  final start = prefix?.len ?? 0;
  if (start >= path.length) return false;
  return _isSepByteFor(isWindows, path[start]);
}
