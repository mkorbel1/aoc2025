import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart';
import 'package:rohd_vf/rohd_vf.dart';

enum Direction { right, left }

class Turn extends LogicStructure {
  final Logic direction;
  final Logic amount;

  Turn({required this.direction, required this.amount, String? name})
    : super([amount, direction], name: name);

  @override
  Turn clone({String? name}) => Turn(
    direction: direction.clone(),
    amount: amount.clone(),
    name: name ?? this.name,
  );
}

enum ProcessingState { ready, busy }

class Day01p2 extends Module {
  late final Logic zeroCount;

  late final Logic turnReady;

  Day01p2({
    required Logic clk,
    required Logic reset,
    required Logic turnValid,
    required Turn turn,
    required int numInputs,
  }) : super(name: 'day01p2') {
    clk = addInput('clk', clk);
    reset = addInput('reset', reset);
    turnValid = addInput('turnValid', turnValid);
    turn = addTypedInput('turn', turn);
    turnReady = addOutput('turnReady');

    const rollAmount = 100;
    final valueWidth = turn.amount.width;

    final turnAccepted = (turnValid & turnReady).named('turnAccepted');

    final turnInProgress = turn.clone(name: 'turnInProgress');

    final turnIsBig = turnInProgress.amount.gt(rollAmount).named('turnIsBig');

    final countEnable = Logic(name: 'countEnable');

    FiniteStateMachine<ProcessingState>(clk, reset, ProcessingState.ready, [
      State(
        .ready,
        events: {turnAccepted & turnIsBig: .busy},
        actions: [
          turnReady < 1,
          turnInProgress < turn,
          countEnable < turnValid,
        ],
      ),
      State(
        .busy,
        events: {~turnIsBig: .ready},
        actions: [
          turnReady < 0,
          countEnable < 1,
          turnInProgress <
              flop(
                clk,
                reset: reset,
                turnInProgress.clone(name: 'nextTurnInProgress')
                  ..amount.gets(
                    mux(
                      turnIsBig,
                      turnInProgress.amount - rollAmount,
                      Const(0, width: valueWidth),
                    ),
                  )
                  ..direction.gets(turnInProgress.direction),
              ),
        ],
      ),
    ]);

    final dialAmountThisCycle = mux(
      turnIsBig,
      Const(rollAmount, width: valueWidth),
      turnInProgress.amount,
    ).named('dialAmountThisCycle');

    final dialPositionCounter = Counter(
      [
        SumInterface(hasEnable: true, width: valueWidth)
          ..enable!.gets(
            countEnable & turnInProgress.direction.eq(Direction.right.index),
          )
          ..amount.gets(dialAmountThisCycle),
        SumInterface(hasEnable: true, width: valueWidth, increments: false)
          ..enable!.gets(
            countEnable & turnInProgress.direction.eq(Direction.left.index),
          )
          ..amount.gets(dialAmountThisCycle),
      ],
      clk: clk,
      reset: reset,
      resetValue: 50,
      maxValue: 99,
      name: 'dialPositionCounter',
    );

    final wasZero = flop(
      clk,
      reset: reset,
      dialPositionCounter.equalsMin,
    ).named('wasZero');

    final zeroCounter = Counter.simple(
      clk: clk,
      reset: reset,
      enable:
          (~wasZero &
                  (dialPositionCounter.underflowed |
                      dialPositionCounter.overflowed))
              .named('rolledOver') |
          (dialPositionCounter.equalsMin & flop(clk, reset: reset, countEnable))
              .named('enabledZero'),
      maxValue: numInputs * 11,
      name: 'zeroCounter',
    );

    zeroCount = addOutput('zeroCount', width: zeroCounter.count.width)
      ..gets(zeroCounter.count);
  }
}

class Day01p2Test extends Test {
  final List<String> lines;

  static const valWidth = 32;

  final clk = SimpleClockGenerator(10).clk;
  final reset = Logic();

  final turnValid = Logic();
  late final turn = Turn(
    direction: Logic(),
    amount: Logic(width: valWidth),
  );

  late final Day01p2 dut = Day01p2(
    clk: clk,
    reset: reset,
    turnValid: turnValid,
    turn: turn,
    numInputs: lines.length,
  );

  late final ReadyValidTransmitterAgent transmitterAgent;

  Day01p2Test(this.lines, {String name = 'day01p2test'}) : super(name) {
    transmitterAgent = ReadyValidTransmitterAgent(
      clk: clk,
      reset: reset,
      valid: turnValid,
      ready: dut.turnReady,
      data: turn,
      name: 'turnTransmitter',
      parent: this,
    );
  }

  @override
  Future<void> run(Phase phase) async {
    unawaited(super.run(phase));
    final obj = phase.raiseObjection();

    await _resetFlow();

    final tmpTurn = Turn(
      direction: Logic(),
      amount: Logic(width: valWidth),
    );

    for (final line in lines) {
      final d = line[0] == 'R' ? Direction.right : Direction.left;
      final v = int.parse(line.substring(1));

      tmpTurn.direction.put(d.index);
      tmpTurn.amount.put(v);
      transmitterAgent.sequencer.add(ReadyValidPacket(tmpTurn.value));
    }

    await clk.waitCycles(3);

    obj.drop();
  }

  Future<void> _resetFlow() async {
    await clk.waitCycles(2);
    reset.inject(1);
    await clk.waitCycles(2);
    reset.inject(0);
    await clk.waitCycles(2);
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

  final lines = File(
    inputFile,
  ).readAsLinesSync().where((line) => !line.startsWith('#')).toList();

  final t = Day01p2Test(lines);
  await t.dut.build();

  File('day01p2.sv').writeAsStringSync(t.dut.generateSynth());

  WaveDumper(t.dut, outputPath: 'day01p2.vcd');

  Simulator.setMaxSimTime(1000000);

  await t.start();

  print('Final zero count: ${t.dut.zeroCount.value.toInt()}');
}
