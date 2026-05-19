// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:benchmark_harness_plus/benchmark_harness_plus.dart';
import 'package:pathify/pathify.dart';

// ignore: unused_element
Object? _sink;

String _makePath(int len) {
  const base = '/storage/emulated/0/DCIM/Camera/';
  final remaining = len - base.length;
  if (remaining <= 0) {
    return base;
  }
  return '$base${'a' * (remaining - 4)}.jpg';
}

void _run(String title, Benchmark benchmark) {
  print(title);
  final results = benchmark.run(log: print);
  for (final r in results) {
    print(
      '  ${r.name.padRight(20)} | '
      'median=${r.median.toStringAsFixed(3)}µs  '
      'mean=${r.mean.toStringAsFixed(3)}µs  '
      'fastest=${r.min.toStringAsFixed(3)}µs  '
      'stddev=${r.stdDev.toStringAsFixed(3)}  '
      'cv=${r.cv.toStringAsPercent()}',
    );
  }
  if (results.length >= 2) {
    final base = results[0].median;
    final warm = results[1].median;
    final savedUs = base - warm;
    final ratio = base > 0 ? base / warm : 1.0;
    print(
      '  saved=${savedUs.toStringAsFixed(3)}µs per call  '
      'speedup=${ratio.toStringAsFixed(2)}x',
    );
  }
  print('');
}

void main() {
  const sizes = [
    1,
    5,
    10,
    20,
    50,
    100,
    200,
    500,
    1000,
    5000,
    10000,
    50000,
    100000,
  ];

  for (final n in sizes) {
    final path = _makePath(n);
    final utf8Bytes = Uint8List.fromList(path.codeUnits);

    final pToStrCold = PathBuf.fromStr(path);
    final pToStrWarm = PathBuf.fromStr(path)..toStr();
    final pLossyCold = PathBuf.fromStr(path);
    final pLossyWarm = PathBuf.fromStr(path)..toStringLossy();

    _run(
      'toStr n=$n — cold vs warm',
      Benchmark(
        title: 'toStr_n$n',
        config: BenchmarkConfig.thorough,
        variants: [
          BenchmarkVariant(
            name: 'cold',
            run: () {
              _sink = pToStrCold.toStr();
            },
          ),
          BenchmarkVariant(
            name: 'warm',
            run: () {
              _sink = pToStrWarm.toStr();
            },
          ),
        ],
      ),
    );

    _run(
      'toStringLossy n=$n — cold vs warm',
      Benchmark(
        title: 'toStringLossy_n$n',
        config: BenchmarkConfig.thorough,
        variants: [
          BenchmarkVariant(
            name: 'cold',
            run: () {
              _sink = pLossyCold.toStringLossy();
            },
          ),
          BenchmarkVariant(
            name: 'warm',
            run: () {
              _sink = pLossyWarm.toStringLossy();
            },
          ),
        ],
      ),
    );

    _run(
      'construction n=$n — fromStr vs fromBytes',
      Benchmark(
        title: 'construction_n$n',
        config: BenchmarkConfig.thorough,
        variants: [
          BenchmarkVariant(
            name: 'fromStr',
            run: () {
              _sink = PathBuf.fromStr(path);
            },
          ),
          BenchmarkVariant(
            name: 'fromBytes',
            run: () {
              _sink = PathBuf.fromBytes(utf8Bytes);
            },
          ),
        ],
      ),
    );
  }
}
