/// Byte and code-unit constants used throughout pathify.
///
/// Path parsing operates on the numeric value of single ASCII bytes (on Unix)
/// or single ASCII code units (on Windows, where storage is UTF-16). Because
/// every path-significant character is ASCII, the same numeric value applies
/// in both cases.
class PathBytes {
  PathBytes._();

  /// `/`
  static const int slash = 0x2F;

  /// `\`
  static const int backslash = 0x5C;

  /// `:`
  static const int colon = 0x3A;

  /// `.`
  static const int dot = 0x2E;

  /// `?`
  static const int question = 0x3F;

  static const int upperA = 0x41;
  static const int upperZ = 0x5A;
  static const int lowerA = 0x61;
  static const int lowerZ = 0x7A;

  /// True when the value is an ASCII alphabetic character.
  static bool isAsciiAlpha(int b) =>
      (b >= upperA && b <= upperZ) || (b >= lowerA && b <= lowerZ);

  /// Returns the uppercase form of an ASCII alphabetic value, or the value
  /// unchanged if it is not lowercase ASCII.
  static int asciiToUpper(int b) {
    if (b >= lowerA && b <= lowerZ) return b - 0x20;
    return b;
  }
}
