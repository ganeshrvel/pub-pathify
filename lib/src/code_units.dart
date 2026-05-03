import 'dart:typed_data';

/// A platform-agnostic view over a sequence of path code units.
///
/// pathify stores POSIX paths as [Uint8List] (each element is a single byte
/// of the encoded path) and Windows paths as [Uint16List] (each element is
/// one UTF-16 code unit). [CodeUnits] is the abstraction that lets
/// internal code — the components iterator, the prefix parser, the
/// extension splitter — read and slice path content without losing
/// information for non-ASCII code units.
///
/// The crucial property: every operation here preserves the **original**
/// code unit values. ASCII bytes (separators, dots, drive letters,
/// `?`, `UNC`) compare correctly because their values are identical in
/// both representations. Non-ASCII code units (UTF-16 surrogates,
/// non-ASCII UTF-8 bytes) are carried through verbatim and never
/// truncated.
///
/// Slicing produces a new [CodeUnits] that shares storage with the
/// original — it never copies. Materializing via [toTypedData] returns
/// the underlying buffer in its original type.
///
/// To choose a representation:
///
///   * Use [CodeUnits.fromUint8List] for POSIX-style paths.
///   * Use [CodeUnits.fromUint16List] for Windows-style paths.
///   * Use [CodeUnits.from] to dispatch on the runtime type of a
///     [TypedData] handed to you by user code.
sealed class CodeUnits {
  const CodeUnits();

  /// Wraps a [Uint8List] without copying.
  factory CodeUnits.fromUint8List(Uint8List buf) = NarrowCodeUnits;

  /// Wraps a [Uint16List] without copying.
  factory CodeUnits.fromUint16List(Uint16List buf) = WideCodeUnits;

  /// Wraps any supported [TypedData] without copying.
  ///
  /// Throws [ArgumentError] for unsupported types.
  factory CodeUnits.from(TypedData buf) {
    if (buf is Uint8List) return NarrowCodeUnits(buf);
    if (buf is Uint16List) return WideCodeUnits(buf);
    throw ArgumentError(
      'CodeUnits supports Uint8List or Uint16List, got ${buf.runtimeType}',
    );
  }

  /// Builds an empty [CodeUnits] of the same width as this one.
  CodeUnits emptyOfSameWidth();

  /// The number of code units in this view.
  int get length;

  /// True when [length] is zero.
  bool get isEmpty => length == 0;

  /// True when [length] is non-zero.
  bool get isNotEmpty => length != 0;

  /// Reads the code unit at [index].
  ///
  /// On narrow storage the result is in `0–255`. On wide storage it is in
  /// `0–65535`.
  int operator [](int index);

  /// Returns a view over the range `[start, end)` (or `[start, length)`
  /// when [end] is omitted) without copying.
  CodeUnits sublistView(int start, [int? end]);

  /// Returns the underlying buffer as a [TypedData].
  ///
  /// The returned object is the original [Uint8List] or [Uint16List]
  /// (or a sublist view into one) — no widening, no narrowing.
  TypedData toTypedData();

  /// True when this view is backed by a [Uint16List].
  bool get isWide;

  /// True when this view is backed by a [Uint8List].
  bool get isNarrow => !isWide;

  /// Compares two [CodeUnits] views for element-wise equality.
  ///
  /// Different widths never compare equal even when their numeric values
  /// happen to match — that distinction matters for path semantics
  /// (Windows paths are not equal to POSIX paths even if the text looks
  /// the same).
  bool equalsCodeUnits(CodeUnits other) {
    if (isWide != other.isWide) return false;
    if (length != other.length) return false;
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }

  /// Concatenates [other] onto this view, allocating a fresh buffer.
  ///
  /// The two views must have the same width.
  CodeUnits concat(CodeUnits other);

  /// Builds a new [CodeUnits] of the same width with [unit] appended,
  /// allocating a fresh buffer.
  CodeUnits appendCodeUnit(int unit);

  /// Materializes this view as a fresh, non-shared buffer of the same
  /// type and width.
  CodeUnits clone();
}

/// A [CodeUnits] view backed by a [Uint8List].
final class NarrowCodeUnits extends CodeUnits {
  const NarrowCodeUnits(this._buf);

  final Uint8List _buf;

  @override
  int get length => _buf.length;

  @override
  int operator [](int index) => _buf[index];

  @override
  CodeUnits sublistView(int start, [int? end]) =>
      NarrowCodeUnits(Uint8List.sublistView(_buf, start, end));

  @override
  Uint8List toTypedData() => _buf;

  @override
  bool get isWide => false;

  @override
  CodeUnits emptyOfSameWidth() => NarrowCodeUnits(Uint8List(0));

  @override
  CodeUnits concat(CodeUnits other) {
    if (other is! NarrowCodeUnits) {
      throw ArgumentError(
        'cannot concatenate narrow and wide CodeUnits',
      );
    }
    final out = Uint8List(length + other.length)
      ..setRange(0, length, _buf)
      ..setRange(length, length + other.length, other._buf);
    return NarrowCodeUnits(out);
  }

  @override
  CodeUnits appendCodeUnit(int unit) {
    final out = Uint8List(length + 1)..setRange(0, length, _buf);
    out[length] = unit & 0xFF;
    return NarrowCodeUnits(out);
  }

  @override
  CodeUnits clone() => NarrowCodeUnits(Uint8List.fromList(_buf));
}

/// A [CodeUnits] view backed by a [Uint16List].
final class WideCodeUnits extends CodeUnits {
  const WideCodeUnits(this._buf);

  final Uint16List _buf;

  @override
  int get length => _buf.length;

  @override
  int operator [](int index) => _buf[index];

  @override
  CodeUnits sublistView(int start, [int? end]) =>
      WideCodeUnits(Uint16List.sublistView(_buf, start, end));

  @override
  Uint16List toTypedData() => _buf;

  @override
  bool get isWide => true;

  @override
  CodeUnits emptyOfSameWidth() => WideCodeUnits(Uint16List(0));

  @override
  CodeUnits concat(CodeUnits other) {
    if (other is! WideCodeUnits) {
      throw ArgumentError(
        'cannot concatenate wide and narrow CodeUnits',
      );
    }
    final out = Uint16List(length + other.length)
      ..setRange(0, length, _buf)
      ..setRange(length, length + other.length, other._buf);
    return WideCodeUnits(out);
  }

  @override
  CodeUnits appendCodeUnit(int unit) {
    final out = Uint16List(length + 1)..setRange(0, length, _buf);
    out[length] = unit & 0xFFFF;
    return WideCodeUnits(out);
  }

  @override
  CodeUnits clone() => WideCodeUnits(Uint16List.fromList(_buf));
}
