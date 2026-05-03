import 'dart:convert';
import 'dart:typed_data';

import 'package:pathify/pathify.dart';
import 'package:test/test.dart';

// ────────────────────────────────────────────────────────────────────────────
// Code-unit construction helpers
// ────────────────────────────────────────────────────────────────────────────

Uint8List b(String s) => Uint8List.fromList(s.codeUnits);

Uint16List w(String s) => Uint16List.fromList(s.codeUnits);

CodeUnits cuN(String s) => NarrowCodeUnits(b(s));

CodeUnits cuW(String s) => WideCodeUnits(w(s));

CodeUnits cuFor(String s, {required bool isWindows}) =>
    isWindows ? cuW(s) : cuN(s);

// ────────────────────────────────────────────────────────────────────────────
// Render helpers
// ────────────────────────────────────────────────────────────────────────────

String cuStr(CodeUnits units) {
  final td = units.toTypedData();
  if (td is Uint8List) return utf8.decode(td);
  if (td is Uint16List) return String.fromCharCodes(td);
  throw StateError('unsupported CodeUnits backing: ${td.runtimeType}');
}

String byteStr(Uint8List bytes) => String.fromCharCodes(bytes);

String wideStr(Uint16List wide) => String.fromCharCodes(wide);

String pStr(PathBuf path) => cuStr(path.codeUnits);

PathBuf pBuf(String s) {
  if (Pathify.instance.isWindows()) {
    return PathBuf.fromBytes(w(s));
  }
  return PathBuf.fromBytes(b(s));
}

// ────────────────────────────────────────────────────────────────────────────
// Platform setup helpers
// ────────────────────────────────────────────────────────────────────────────

void usePosix() {
  setUp(() {
    Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
  });
  tearDown(Pathify.instance.resetForTesting);
}

void useWindows() {
  setUp(() {
    Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
  });
  tearDown(Pathify.instance.resetForTesting);
}

// ────────────────────────────────────────────────────────────────────────────
// `t!` macro
// ────────────────────────────────────────────────────────────────────────────

void t({
  required String path,
  required bool isWindows,
  List<String>? iter,
  bool? hasRoot,
  bool? isAbsolute,
  String? parent,
  bool parentIsNone = false,
  String? fileName,
  bool fileNameIsNone = false,
  String? fileStem,
  bool fileStemIsNone = false,
  String? extension,
  bool extensionIsNone = false,
  String? filePrefix,
  bool filePrefixIsNone = false,
}) {
  final p = isWindows ? PathBuf.fromBytes(w(path)) : PathBuf.fromBytes(b(path));

  if (iter != null) {
    final forward = <String>[];
    final iterFwd = p.iter();
    while (true) {
      final c = iterFwd.next();
      if (c == null) break;
      forward.add(cuStr(c));
    }
    expect(forward, equals(iter), reason: 'iter forward: path=${_dbg(path)}');

    final reversed = <String>[];
    final iterBack = p.iter();
    while (true) {
      final c = iterBack.nextBack();
      if (c == null) break;
      reversed.add(cuStr(c));
    }
    expect(
      reversed,
      equals(iter.reversed.toList()),
      reason: 'iter reversed: path=${_dbg(path)}',
    );
  }

  if (hasRoot != null) {
    expect(
      p.hasRoot(),
      equals(hasRoot),
      reason: 'has_root: path=${_dbg(path)}',
    );
  }
  if (isAbsolute != null) {
    expect(
      p.isAbsolute(),
      equals(isAbsolute),
      reason: 'is_absolute: path=${_dbg(path)}',
    );
  }

  if (parentIsNone) {
    expect(p.parent(), isNull, reason: 'parent: path=${_dbg(path)}');
  } else if (parent != null) {
    final actual = p.parent();
    expect(actual, isNotNull, reason: 'parent: path=${_dbg(path)}');
    expect(pStr(actual!), equals(parent), reason: 'parent: path=${_dbg(path)}');
  }

  if (fileNameIsNone) {
    expect(p.fileName(), isNull, reason: 'file_name: path=${_dbg(path)}');
  } else if (fileName != null) {
    final actual = p.fileName();
    expect(actual, isNotNull, reason: 'file_name: path=${_dbg(path)}');
    expect(
      cuStr(actual!),
      equals(fileName),
      reason: 'file_name: path=${_dbg(path)}',
    );
  }

  if (fileStemIsNone) {
    expect(p.fileStem(), isNull, reason: 'file_stem: path=${_dbg(path)}');
  } else if (fileStem != null) {
    final actual = p.fileStem();
    expect(actual, isNotNull, reason: 'file_stem: path=${_dbg(path)}');
    expect(
      cuStr(actual!),
      equals(fileStem),
      reason: 'file_stem: path=${_dbg(path)}',
    );
  }

  if (extensionIsNone) {
    expect(p.extension(), isNull, reason: 'extension: path=${_dbg(path)}');
  } else if (extension != null) {
    final actual = p.extension();
    expect(actual, isNotNull, reason: 'extension: path=${_dbg(path)}');
    expect(
      cuStr(actual!),
      equals(extension),
      reason: 'extension: path=${_dbg(path)}',
    );
  }

  if (filePrefixIsNone) {
    expect(p.filePrefix(), isNull, reason: 'file_prefix: path=${_dbg(path)}');
  } else if (filePrefix != null) {
    final actual = p.filePrefix();
    expect(actual, isNotNull, reason: 'file_prefix: path=${_dbg(path)}');
    expect(
      cuStr(actual!),
      equals(filePrefix),
      reason: 'file_prefix: path=${_dbg(path)}',
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// `tp!`, `tpop`, `tfn!`, `tfe!`, `twe!`
// ────────────────────────────────────────────────────────────────────────────

void tp({
  required String path,
  required String push,
  required String expected,
  required bool isWindows,
}) {
  final p = isWindows ? PathBuf.fromBytes(w(path)) : PathBuf.fromBytes(b(path));
  final addend = isWindows
      ? PathBuf.fromBytes(w(push))
      : PathBuf.fromBytes(b(push));
  p.push(addend);
  expect(
    pStr(p),
    equals(expected),
    reason: 'pushing ${_dbg(push)} onto ${_dbg(path)}',
  );
}

void tpop({
  required String path,
  required String expected,
  required bool output,
  required bool isWindows,
}) {
  final p = isWindows ? PathBuf.fromBytes(w(path)) : PathBuf.fromBytes(b(path));
  final popped = p.pop();
  expect(popped, equals(output), reason: 'popping from ${_dbg(path)}: output');
  expect(
    pStr(p),
    equals(expected),
    reason: 'popping from ${_dbg(path)}: result',
  );
}

void tfn({
  required String path,
  required String file,
  required String expected,
  required bool isWindows,
}) {
  final p = isWindows ? PathBuf.fromBytes(w(path)) : PathBuf.fromBytes(b(path))
    ..setFileName(cuFor(file, isWindows: isWindows));
  expect(
    pStr(p),
    equals(expected),
    reason: 'set_file_name(${_dbg(file)}) on ${_dbg(path)}',
  );
}

void tfe({
  required String path,
  required String ext,
  required String expected,
  required bool output,
  required bool isWindows,
}) {
  final p = isWindows ? PathBuf.fromBytes(w(path)) : PathBuf.fromBytes(b(path));
  final ok = p.setExtension(cuFor(ext, isWindows: isWindows));
  expect(
    ok,
    equals(output),
    reason: 'set_extension(${_dbg(ext)}) on ${_dbg(path)}: output',
  );
  expect(
    pStr(p),
    equals(expected),
    reason: 'set_extension(${_dbg(ext)}) on ${_dbg(path)}: result',
  );
}

void tfeAdd({
  required String path,
  required String ext,
  required String expected,
  required bool output,
  required bool isWindows,
}) {
  final p = isWindows ? PathBuf.fromBytes(w(path)) : PathBuf.fromBytes(b(path));
  final ok = p.addExtension(cuFor(ext, isWindows: isWindows));
  expect(
    ok,
    equals(output),
    reason: 'add_extension(${_dbg(ext)}) on ${_dbg(path)}: output',
  );
  expect(
    pStr(p),
    equals(expected),
    reason: 'add_extension(${_dbg(ext)}) on ${_dbg(path)}: result',
  );
}

void twe({
  required String input,
  required String ext,
  required String expected,
  required bool isWindows,
}) {
  final p = isWindows
      ? PathBuf.fromBytes(w(input))
      : PathBuf.fromBytes(b(input));
  final out = p.withExtension(cuFor(ext, isWindows: isWindows));
  expect(
    pStr(out),
    equals(expected),
    reason: 'with_extension(${_dbg(ext)}) on ${_dbg(input)}',
  );
}

void tweAdd({
  required String input,
  required String ext,
  required String expected,
  required bool isWindows,
}) {
  final p = isWindows
      ? PathBuf.fromBytes(w(input))
      : PathBuf.fromBytes(b(input));
  final out = p.withAddedExtension(cuFor(ext, isWindows: isWindows));
  expect(
    pStr(out),
    equals(expected),
    reason: 'with_added_extension(${_dbg(ext)}) on ${_dbg(input)}',
  );
}

void tc({
  required String path1,
  required String path2,
  required bool eq,
  required bool startsWith,
  required bool endsWith,
  required bool isWindows,
  String? relativeFrom,
  bool relativeFromIsNone = false,
}) {
  final a = isWindows
      ? PathBuf.fromBytes(w(path1))
      : PathBuf.fromBytes(b(path1));
  final c = isWindows
      ? PathBuf.fromBytes(w(path2))
      : PathBuf.fromBytes(b(path2));

  expect(a == c, equals(eq), reason: '${_dbg(path1)} == ${_dbg(path2)}');
  expect(
    a.hashCode == c.hashCode,
    equals(eq),
    reason: 'hash agreement for ${_dbg(path1)} vs ${_dbg(path2)}',
  );

  expect(
    a.startsWith(c),
    equals(startsWith),
    reason: '${_dbg(path1)}.starts_with(${_dbg(path2)})',
  );
  expect(
    a.endsWith(c),
    equals(endsWith),
    reason: '${_dbg(path1)}.ends_with(${_dbg(path2)})',
  );

  final stripped = a.stripPrefix(c);
  if (relativeFromIsNone) {
    expect(
      stripped,
      isNull,
      reason: '${_dbg(path1)}.strip_prefix(${_dbg(path2)})',
    );
  } else if (relativeFrom != null) {
    expect(
      stripped,
      isNotNull,
      reason: '${_dbg(path1)}.strip_prefix(${_dbg(path2)})',
    );
    expect(
      pStr(stripped!),
      equals(relativeFrom),
      reason: '${_dbg(path1)}.strip_prefix(${_dbg(path2)})',
    );
  }
}

void ordEqual({
  required String left,
  required String right,
  required bool isWindows,
}) {
  final l = isWindows ? PathBuf.fromBytes(w(left)) : PathBuf.fromBytes(b(left));
  final r = isWindows
      ? PathBuf.fromBytes(w(right))
      : PathBuf.fromBytes(b(right));
  expect(l == r, isTrue, reason: '${_dbg(left)} should equal ${_dbg(right)}');
  expect(
    l.hashCode,
    equals(r.hashCode),
    reason: 'hashes for ${_dbg(left)} and ${_dbg(right)} must match',
  );
}

void ordNotEqual({
  required String left,
  required String right,
  required bool isWindows,
}) {
  final l = isWindows ? PathBuf.fromBytes(w(left)) : PathBuf.fromBytes(b(left));
  final r = isWindows
      ? PathBuf.fromBytes(w(right))
      : PathBuf.fromBytes(b(right));
  expect(
    l == r,
    isFalse,
    reason: '${_dbg(left)} should not equal ${_dbg(right)}',
  );
}

String _dbg(String s) {
  final buf = StringBuffer('"');
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    switch (ch) {
      case '"':
        buf.write(r'\"');
      case r'\':
        buf.write(r'\\');
      case '\n':
        buf.write(r'\n');
      case '\t':
        buf.write(r'\t');
      default:
        buf.write(ch);
    }
  }
  buf.write('"');
  return buf.toString();
}
