# Pathify - Byte-level, cross-platform path manipulation for Dart

### Introduction

**Pathify** is a byte-level, cross-platform path manipulation library for Dart, ported from Rust’s `std::path`.

It exists because Dart does not provide a complete or correct way to parse Windows paths. Rust has very robust handling for Windows paths including UNC, verbatim paths, and device namespaces. Pathify brings that same capability to Dart.

This is a translation of Rust’s path module adapted for Dart, preserving the same core behavior and semantics. The translation was done using Claude. If you find any bugs or incomplete behavior, feel free to open an issue or raise a PR.



### Description

A byte-level, cross-platform path manipulation library for Dart, ported from Rust's std::path.

Operates on raw bytes (`Uint8List` on Unix, `Uint16List` on Windows) rather than strings. Correctly handles all Windows path prefix types including verbatim (`\\?\`), UNC, and device namespace (`\\.\`) paths. Suitable for paths containing non-UTF-8 filenames.



### Installation

Go to [https://pub.dev/packages/pathify#-installing-tab-](https://pub.dev/packages/pathify#-installing-tab-) for the latest version of **pathify**



### Key Benefits

* Works directly on raw bytes instead of strings
* Preserves unaltered, unsanitized path data
* No implicit normalization or cleanup
* Safe for non-UTF-8 filenames
* Data can be passed around without losing fidelity
* Automatically detects the host platform or allows manual override to work with a different OS behavior
* Cross-platform support including Linux, Windows, Android, iOS, and macOS
* Lightweight and minimal, no third party dependencies
* Does not rely on Dart’s built-in path libraries at all



### Features

* Cross-platform path parsing (POSIX and Windows)
* Byte-level path representation
* Automatic platform detection with optional manual override
* Full Windows prefix support:

    * Disk
    * UNC (Universal Naming Convention)
    * DeviceNS (Device Namespace)
    * Verbatim
    * VerbatimUNC (Verbatim Universal Naming Convention)
    * VerbatimDisk
* Unicode-safe including emoji and foreign scripts
* No normalization or mutation of input
* Component-based parsing and operations
* Predictable and consistent behavior across platforms



### Windows Prefix Support

Pathify fully supports all Windows path prefix types:

#### Disk

```
C:\path\to\file
```

#### UNC (Universal Naming Convention)

```
\\server\share\folder\file
```

#### Device Namespace

```
\\.\COM1
```

#### Verbatim Paths

```
\\?\C:\very\long\path
```

#### Verbatim UNC

```
\\?\UNC\server\share\file
```

#### Verbatim Disk

```
\\?\C:\path
```

These are parsed correctly and exposed as structured prefix types instead of raw strings.



### Usage

Import the library

```dart
import 'package:pathify/pathify.dart';
```



### From String

```dart
final path = PathBuf.fromStr('/home/user/file.txt');

print(path.toStringLossy());
print(path.parent());
print(path.fileName());
print(path.extension());
```



### From Bytes (Core Feature)

```dart
import 'dart:convert';
import 'dart:typed_data';

Uint8List b(String s) => Uint8List.fromList(utf8.encode(s));

final path = PathBuf.fromBytes(b('/tmp/data.bin'));

print(path.toStringLossy());
```

The key advantage here is that the path is stored and passed around as raw bytes.
This means the data remains untouched, unaltered, and not normalized or sanitized in any way.



### Working with Components

```dart
final path = PathBuf.fromStr('/a/b/c');

for (final c in path.components().toList()) {
  if (c is ComponentNormal) {
    print(c.value);
  }
}
```



### Joining Paths

```dart
final base = PathBuf.fromStr('/home/user');
final full = base.join(PathBuf.fromStr('docs/readme.md'));

print(full.toStringLossy());
```



### Emoji and Unicode Paths

```dart
final path = PathBuf.fromStr('/tmp/🚀/🔥/file.txt');

print(path.parent());
print(path.fileName());
```



### Foreign Language Paths

```dart
final path = PathBuf.fromStr('/home/用户/данные/ملف.txt');

print(path.parent());
print(path.fileName());
```



### Windows Paths

```dart
final path = PathBuf.fromStr(r'C:\Users\Public\file.txt');

print(path.parent());
print(path.fileName());
```



### UNC Paths

```dart
final path = PathBuf.fromStr(r'\\server\share\folder\file.txt');

print(path.parent());
```



### No Normalization

Pathify does not normalize paths. It preserves them exactly as provided.

This means:

* No collapsing of duplicate separators
* No resolving `.` or `..`
* No rewriting of mixed separators
* No cleanup or sanitization

**Example**

```dart
final p = PathBuf.fromStr('/a//b/./c/../file.txt');

print(p.toStringLossy());
// Output: /a//b/./c/../file.txt
```

```dart
final mixed = PathBuf.fromStr(r'C:\foo//bar\baz');

print(mixed.toStringLossy());
// Output: C:\foo//bar\baz
```

```dart
import 'dart:typed_data';

final raw = Uint8List.fromList([0x2F, 0x61, 0x2F, 0xFF, 0x62]);
final p = PathBuf.fromBytes(raw);

print(p.toStringLossy());
// Output contains replacement characters for display,
// but original bytes are preserved internally
```



### Platform Behavior

Pathify is platform-agnostic and does not depend on the host OS to parse paths.
You can explicitly control how paths are interpreted:

```dart
Pathify.instance.overriddenPlatform = PathifyPlatform.linux;
Pathify.instance.overriddenPlatform = PathifyPlatform.windows;
Pathify.instance.overriddenPlatform = PathifyPlatform.macOS;
Pathify.instance.overriddenPlatform = PathifyPlatform.android;
Pathify.instance.overriddenPlatform = PathifyPlatform.iOS;
Pathify.instance.overriddenPlatform = PathifyPlatform.fuchsia;
```



### Notes

* This is a translation of Rust’s `std::path` into Dart
* The translation was done using Claude
* The library is backed by around 850+ tests that currently pass
* There may still be edge cases or bugs
* Behavior may differ from Dart’s standard path libraries. If you notice deviations or unexpected behavior, please raise an issue or PR
* Please feel free to open an issue or raise a PR if you find something
* No normalization is performed. Paths are preserved exactly as provided




### Limitations

* Does not work on Web or WASM


### Contacts

Please feel free to reach out via the repository.



### About

* Package URL: [https://pub.dev/packages/pathify](https://pub.dev/packages/pathify)
* Repo URL: [https://github.com/ganeshrvel/pub-pathify](https://github.com/ganeshrvel/pub-pathify)



### License

Pathify | Byte-level, cross-platform path manipulation for Dart. MIT License.
