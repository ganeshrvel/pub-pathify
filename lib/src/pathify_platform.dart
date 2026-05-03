import 'dart:io' show Platform;

import 'package:meta/meta.dart';
import 'package:pathify/pathify.dart';

/// The set of platforms that pathify recognizes.
///
/// Mirrors Flutter's `TargetPlatform` shape but is defined locally so this
/// package does not depend on Flutter and can be used in pure Dart contexts.
enum PathifyPlatform {
  android,
  fuchsia,
  iOS,
  linux,
  macOS,
  windows,
}

/// Singleton that controls how pathify identifies the current platform.
///
/// By default, the platform is auto-detected from `dart:io`'s [Platform].
/// During tests or when simulating a different platform, the detected value
/// can be overridden via [overriddenPlatform]. Setting it back to `null`
/// restores auto-detection.
///
/// Path-style behavior (separator rules, prefix parsing) is determined by the
/// type of bytes a [PathBuf] holds, not by this singleton. The platform
/// detection here governs only:
///
///   * which byte-vector type is expected at [PathBuf.fromBytes] construction,
///   * helpers such as [isWindows] / [isUnix] for callers that need to branch.
class Pathify {
  Pathify._();

  /// The shared instance.
  static final Pathify instance = Pathify._();

  /// When non-null, [platform] returns this value instead of the auto-detected
  /// host platform.
  ///
  /// Intended for tests that need to exercise behavior of a platform other
  /// than the host. Set to `null` to restore auto-detection.
  PathifyPlatform? overriddenPlatform;

  /// The currently effective platform.
  ///
  /// Returns [overriddenPlatform] if set, otherwise the host platform reported
  /// by [Platform].
  PathifyPlatform get platform => overriddenPlatform ?? _hostPlatform();

  /// True when the effective platform is [PathifyPlatform.windows].
  bool isWindows() => platform == PathifyPlatform.windows;

  /// True when the effective platform is [PathifyPlatform.macOS].
  bool isMacOS() => platform == PathifyPlatform.macOS;

  /// True when the effective platform is [PathifyPlatform.linux].
  bool isLinux() => platform == PathifyPlatform.linux;

  /// True when the effective platform is [PathifyPlatform.android].
  bool isAndroid() => platform == PathifyPlatform.android;

  /// True when the effective platform is [PathifyPlatform.iOS].
  bool isIOS() => platform == PathifyPlatform.iOS;

  /// True when the effective platform is [PathifyPlatform.fuchsia].
  bool isFuchsia() => platform == PathifyPlatform.fuchsia;

  /// True for any non-Windows platform.
  ///
  /// All such platforms use POSIX-style paths (single forward-slash separator,
  /// no prefix component).
  bool isUnix() => !isWindows();

  /// Alias for [isUnix].
  bool isPosix() => isUnix();

  @visibleForTesting
  void resetForTesting() {
    overriddenPlatform = null;
  }

  static PathifyPlatform _hostPlatform() {
    if (Platform.isWindows) return PathifyPlatform.windows;
    if (Platform.isMacOS) return PathifyPlatform.macOS;
    if (Platform.isLinux) return PathifyPlatform.linux;
    if (Platform.isAndroid) return PathifyPlatform.android;
    if (Platform.isIOS) return PathifyPlatform.iOS;
    if (Platform.isFuchsia) return PathifyPlatform.fuchsia;
    // Should be unreachable on supported platforms; fall back to Linux.
    return PathifyPlatform.linux;
  }
}
