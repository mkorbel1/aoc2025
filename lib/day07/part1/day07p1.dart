import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart';
import 'package:rohd_vf/rohd_vf.dart';

class Day07p1 extends Module {
  final int rowWidth;

  late final Logic totalSplittersHitCount;

  /// Constructs a Day07p1 module.
  ///
  /// The [splitterVector] is `1` where there is a splitter and `0` elsewhere (open
  /// space).
  Day07p1({
    required Logic clk,
    required Logic reset,
    required Logic splitterVector,
    super.name = 'day07p1',
  }) : rowWidth = splitterVector.width {
    clk = addInput('clk', clk);
    reset = addInput('reset', reset);
    splitterVector = addInput(
      'splitterVector',
      splitterVector,
      width: rowWidth,
    );

    final laserPresent = Logic(name: 'laserPresent', width: rowWidth);

    final splitterHit = (splitterVector & laserPresent).named('splitterHit');

    laserPresent <=
        flop(
          clk,
          reset: reset,
          // we can just assume that the `S` always lands in the middle
          resetValue: LogicValue.ofInt(1, rowWidth) << (rowWidth ~/ 2),
          // it looks like we don't have to worry about neighboring splitters
          [
            for (var i = 0; i < rowWidth; i++)
              ~splitterVector[i] &
                  (
                  // no splitter present and neighboring splitter was hit
                  [
                        if (i > 0) splitterHit[i - 1],
                        if (i < rowWidth - 1) splitterHit[i + 1],
                      ].swizzle().or() |
                      // laser was present in previous cycle
                      laserPresent[i]),
          ].rswizzle(),
        );

    final splittersHitCountInRow = Count(
      splitterHit,
    ).count.named('splittersHitCountInRow');

    final totalSplittersHitCount = Counter.ofLogics(
      [splittersHitCountInRow],
      clk: clk,
      reset: reset,
      width: rowWidth + 2, // a little bigger to be safe, looks square-ish
    ).count.named('totalSplittersHitCount');
    this.totalSplittersHitCount = addOutput(
      'totalSplittersHitCount',
      width: totalSplittersHitCount.width,
    )..gets(totalSplittersHitCount);
  }
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('input_file', abbr: 'i', help: 'Path to the input file');
  final parsedArgs = parser.parse(args);

  if (parsedArgs['input_file'] == null) {
    print('Please provide an input file using -i option.');
    exit(1);
  }

  final inputFile = parsedArgs['input_file'] as String;
  print('Input file: $inputFile');

  final lines = File(inputFile).readAsLinesSync();

  final clk = SimpleClockGenerator(10).clk;
  final reset = Logic();
  final splitterVector = Logic(width: lines[0].length, name: 'splitterVector')
    ..inject(0);

  final dut = Day07p1(clk: clk, reset: reset, splitterVector: splitterVector);

  await dut.build();

  File('day07p1.sv').writeAsStringSync(dut.generateSynth());

  WaveDumper(dut, outputPath: 'day07p1.vcd');

  unawaited(Simulator.run());

  // first, a little reset flow
  await clk.waitCycles(2);
  reset.inject(1);
  await clk.waitCycles(2);
  reset.inject(0);
  await clk.waitCycles(2);

  for (final line in lines) {
    final row = LogicValue.ofString(
      line.replaceAll('.', '0').replaceAll('^', '1').replaceAll('S', '0'),
    );
    splitterVector.inject(row);
    await clk.waitCycles(1);
  }

  splitterVector.inject(0);
  await clk.waitCycles(5);

  await Simulator.endSimulation();

  print('Final split count: ${dut.totalSplittersHitCount.value.toInt()}');
}
