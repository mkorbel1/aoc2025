import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart';
import 'package:rohd_vf/rohd_vf.dart';

enum Direction { right, left }

class Day01 extends Module {
  late final Logic zeroCount;

  Day01({
    required Logic clk,
    required Logic reset,
    required Logic value,
    required Logic enable,
    required Logic direction,
    required int numInputs,
  }) : super(name: 'day01') {
    clk = addInput('clk', clk);
    reset = addInput('reset', reset);
    value = addInput('value', value, width: value.width);
    enable = addInput('enable', enable);
    direction = addInput('direction', direction);

    final dialPositionCounter = Counter(
      [
        SumInterface(hasEnable: true, width: value.width)
          ..enable!.gets(enable & direction.eq(Direction.right.index))
          ..amount.gets(value),
        SumInterface(hasEnable: true, width: value.width, increments: false)
          ..enable!.gets(enable & direction.eq(Direction.left.index))
          ..amount.gets(value),
      ],
      clk: clk,
      reset: reset,
      resetValue: 50,
      maxValue: 99,
      name: 'dialPositionCounter',
    );

    final zeroCounter = Counter.simple(
      clk: clk,
      reset: reset,
      enable: dialPositionCounter.equalsMin & enable,
      maxValue: numInputs,
      name: 'zeroCounter',
    );

    zeroCount = addOutput('zeroCount', width: zeroCounter.count.width)
      ..gets(zeroCounter.count);
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

  final lines = File(inputFile).readAsLinesSync()
    // add a zero at the end so we have time to propagate the final count
    ..add('R0');

  const valWidth = 64;

  final clk = SimpleClockGenerator(10).clk;
  final reset = Logic();
  final enable = Logic()..inject(0);
  final direction = Logic()..inject(0);
  final value = Logic(width: valWidth)..inject(0);

  final dut = Day01(
    clk: clk,
    reset: reset,
    value: value,
    enable: enable,
    direction: direction,
    numInputs: lines.length,
  );

  await dut.build();

  File('day01.sv').writeAsStringSync(dut.generateSynth());

  // uncomment if you want to see waveforms
  WaveDumper(dut, outputPath: 'day01.vcd');

  unawaited(Simulator.run());

  // first, a little reset flow
  await clk.waitCycles(2);
  reset.inject(1);
  await clk.waitCycles(2);
  reset.inject(0);
  await clk.waitCycles(2);

  enable.inject(1);
  for (final line in lines) {
    final d = line[0] == 'R' ? Direction.right : Direction.left;
    final v = int.parse(line.substring(1));

    direction.inject(d.index);
    value.inject(v);
    await clk.nextPosedge;
  }

  print('Final zero count: ${dut.zeroCount.value.toInt()}');

  await Simulator.endSimulation();
}
