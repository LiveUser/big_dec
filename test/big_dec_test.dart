import 'package:big_dec/big_dec.dart';
import 'package:test/test.dart';

void main() {
  group('CPU Operations (Immutable)', () {
    test('Addition', () {
      BigDec bigDec1 = BigDec.fromString("1.5");
      BigDec bigDec2 = BigDec.fromString("1.5");
      BigDec result = bigDec1.add(bigDec2);
      expect(result.toStringAsFixed(0), equals("3"));
    });

    test('Subtraction', () {
      BigDec bigDec1 = BigDec.fromString("3.36");
      BigDec bigDec2 = BigDec.fromString("1.5");
      BigDec result = bigDec1.subtract(bigDec2);
      expect(result.toStringAsFixed(2), equals("1.86"));
    });

    test('Multiplication', () {
      BigDec bigDec1 = BigDec.fromString("1.5");
      BigDec bigDec2 = BigDec.fromString("3");
      BigDec result = bigDec1.multiply(bigDec2);
      expect(result.toStringAsFixed(1), equals("4.5"));
    });

    test('Division', () {
      BigDec bigDec1 = BigDec.fromString("1").setDecimalPrecision(10);
      BigDec bigDec2 = BigDec.fromString("3");
      BigDec result = bigDec1.divide(bigDec2);
      expect(result.toString().contains("0.33333"), isTrue);
    });

    test("Pow", () {
      BigDec bigDec1 = BigDec.fromString("25");
      BigDec result = bigDec1.pow(BigInt.from(2));
      expect(result.integer, equals(BigInt.from(625)));
    });

    test("SQRT", () {
      BigDec bigDec1 = BigDec.fromString("25");
      BigDec result = bigDec1.sqrt();
      expect(result.integer, equals(BigInt.from(5)));
    });
  });
}