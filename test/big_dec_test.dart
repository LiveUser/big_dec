import 'package:big_dec/big_dec.dart';
import 'package:test/test.dart';

void main() {
  group('CPU Operations (Immutable)', () {
    test('Addition', () {
      BigDec bigDec1 = BigDec.fromString("1.5");
      BigDec bigDec2 = BigDec.fromString("1.5");
      BigDec result = bigDec1.add(bigDec2);
      print(result);
    });

    test('Subtraction', () {
      BigDec bigDec1 = BigDec.fromString("3.36");
      BigDec bigDec2 = BigDec.fromString("1.5");
      BigDec result = bigDec1.subtract(bigDec2);
      print(result.toStringAsFixed(2));
    });

    test('Multiplication', () {
      BigDec bigDec1 = BigDec.fromString("1.5");
      BigDec bigDec2 = BigDec.fromString("3");
      BigDec result = bigDec1.multiply(bigDec2);
      print(result.toString());
    });

    test('Division', () {
      BigDec bigDec1 = BigDec.fromString("1").setDecimalPrecision(10);
      BigDec bigDec2 = BigDec.fromString("3");
      BigDec result = bigDec1.divide(bigDec2);
      print(result);
    });

    test("Pow", () {
      BigDec bigDec1 = BigDec.fromString("25");
      BigDec result = bigDec1.pow(BigInt.from(2));
      print(result.integer.toString());
    });

    test("SQRT", () {
      BigDec bigDec1 = BigDec.fromString("25");
      BigDec result = bigDec1.sqrt();
      print(result.integer.toString());
    });
  });
}