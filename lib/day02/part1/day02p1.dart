import 'package:rohd/rohd.dart';

class BinaryCodedDecimal extends LogicStructure {
  final LogicArray digits;

  int get numDigits => digits.dimensions.first;

  static const bitsPerDigit = 4;

  BinaryCodedDecimal._(this.digits, {super.name}) : super([digits]);

  factory BinaryCodedDecimal(int numDigits, {String? name}) =>
      BinaryCodedDecimal._(LogicArray([numDigits], bitsPerDigit), name: name);

  @override
  BinaryCodedDecimal clone({String? name}) =>
      BinaryCodedDecimal(numDigits, name: name ?? this.name);

  // BinaryCodedDecimal operator +(BinaryCodedDecimal other) {
  //   throw UnimplementedError();
  // }
}

class BcdAdder extends Module {
  late final BinaryCodedDecimal sum;

  final int numDigits;

  BcdAdder(BinaryCodedDecimal a, BinaryCodedDecimal b)
    : numDigits = a.numDigits,
      super(name: 'BcdAdder') {
    if (a.numDigits != b.numDigits) {
      throw ArgumentError(
        'Both BCD numbers must have the same number of digits.',
      );
    }

    a = addTypedInput('a', a);
    b = addTypedInput('b', b);
    sum = addTypedOutput('sum', a.clone);

    Logic carry = Const(0, width: BinaryCodedDecimal.bitsPerDigit);

    for (var i = 0; i < numDigits; i++) {
      final aDigit = a.digits.elements[i];
      final bDigit = b.digits.elements[i];
      final sumDigit = sum.digits.elements[i];

      final rawSum = aDigit + bDigit + carry;
      carry = rawSum
          .gt(9)
          .zeroExtend(BinaryCodedDecimal.bitsPerDigit)
          .named('carry_$i');
      final correctedSum = rawSum - 9;

      sumDigit <= mux(carry, correctedSum, rawSum);
    }
  }
}
