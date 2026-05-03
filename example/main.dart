// ignore_for_file: avoid_print

import 'package:pathify/pathify.dart';

void main() {
  // =========================================================
  // POSIX-STYLE USAGE (UNIX / LINUX / MAC)
  // =========================================================

  final posixPath = PathBuf.fromStr('/home/user/projects/app/main.dart');

  print('--- POSIX BASIC ---');
  print(posixPath.toStringLossy());
  print(posixPath.parent()?.toStringLossy());
  print(posixPath.fileName());
  print(posixPath.extension());

  final joined = posixPath.parent()!.join(PathBuf.fromStr('utils.dart'));
  print(joined.toStringLossy());

  // Emoji paths
  final emojiPath = PathBuf.fromStr('/tmp/🚀/build/🔥/output.txt');

  print('\n--- POSIX EMOJI ---');
  print(emojiPath.toStringLossy());
  print(emojiPath.parent()?.toStringLossy());
  print(emojiPath.fileName());

  // Foreign language paths
  final foreignPath = PathBuf.fromStr('/home/用户/данные/ملف.txt');

  print('\n--- POSIX FOREIGN ---');
  print(foreignPath.toStringLossy());
  print(foreignPath.parent()?.toStringLossy());
  print(foreignPath.fileName());

  // Working with components
  print('\n--- POSIX COMPONENTS ---');
  for (final c in posixPath.components().toList()) {
    if (c is ComponentNormal) {
      print(c.value);
    }
  }

  // Building paths incrementally
  final buildPath = PathBuf.fromStr('/var')
    ..push(PathBuf.fromStr('log'))
    ..push(PathBuf.fromStr('app.log'));

  print('\n--- POSIX BUILD ---');
  print(buildPath.toStringLossy());

  // =========================================================
  // WINDOWS-STYLE USAGE
  // =========================================================

  final windowsPath = PathBuf.fromStr(r'C:\Users\Orange\Documents\file.txt');

  print('\n--- WINDOWS BASIC ---');
  print(windowsPath.toStringLossy());
  print(windowsPath.parent()?.toStringLossy());
  print(windowsPath.fileName());
  print(windowsPath.extension());

  final winJoined = windowsPath.parent()!.join(PathBuf.fromStr('notes.txt'));

  print(winJoined.toStringLossy());

  // UNC paths
  final uncPath = PathBuf.fromStr(r'\\server\share\projects\repo\readme.md');

  print('\n--- WINDOWS UNC ---');
  print(uncPath.toStringLossy());
  print(uncPath.parent()?.toStringLossy());
  print(uncPath.fileName());

  // Emoji paths on Windows
  final winEmoji = PathBuf.fromStr(r'C:\temp\🚀\build\🔥\output.txt');

  print('\n--- WINDOWS EMOJI ---');
  print(winEmoji.toStringLossy());
  print(winEmoji.parent()?.toStringLossy());

  // Foreign language paths on Windows
  final winForeign = PathBuf.fromStr(r'C:\用户\данные\ملف.txt');

  print('\n--- WINDOWS FOREIGN ---');
  print(winForeign.toStringLossy());
  print(winForeign.parent()?.toStringLossy());
  print(winForeign.fileName());

  // Mixed separators (Windows accepts both)
  final mixed = PathBuf.fromStr(r'C:\projects/app\src/main.dart');

  print('\n--- WINDOWS MIXED ---');
  print(mixed.toStringLossy());
  print(mixed.parent()?.toStringLossy());

  // Working with components
  print('\n--- WINDOWS COMPONENTS ---');
  for (final c in windowsPath.components().toList()) {
    if (c is ComponentNormal) {
      print(c.value);
    }
  }

  // =========================================================
  // NOTE
  // =========================================================

  // This package is platform-agnostic and does not depend on the host OS
  // to parse paths. You can explicitly choose the behavior you want:

  // Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
  // Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
}
