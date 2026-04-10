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

  group('GPU Operations (Async)', () {
    // Note: These tests require a valid GPU device/environment to pass.
    
    test('GPU Addition', () async {
      BigDec bigDec1 = BigDec.fromString("10.5");
      BigDec bigDec2 = BigDec.fromString("20.5");
      BigDec result = await bigDec1.gpuAdd(bigDec2);
      expect(result.integer, equals(BigInt.from(31)));
    });

    test('GPU Subtraction', () async {
      BigDec bigDec1 = BigDec.fromString("100.00");
      BigDec bigDec2 = BigDec.fromString("50.25");
      BigDec result = await bigDec1.gpuSubtract(bigDec2);
      expect(result.toStringAsFixed(2), equals("49.75"));
    });

    test('GPU Multiplication', () async {
      BigDec bigDec1 = BigDec.fromString("12.5");
      BigDec bigDec2 = BigDec.fromString("2.0");
      BigDec result = await bigDec1.gpuMultiply(bigDec2);
      expect(result.integer, equals(BigInt.from(25)));
    });

    test('GPU Division', () async {
      BigDec bigDec1 = BigDec.fromString("100").setDecimalPrecision(2);
      BigDec bigDec2 = BigDec.fromString("4");
      BigDec result = await bigDec1.gpuDivide(bigDec2);
      expect(result.integer, equals(BigInt.from(25)));
    });

    test('GPU Pow', () async {
      BigDec bigDec1 = BigDec.fromString("5");
      BigDec result = await bigDec1.gpuPow(BigInt.from(3));
      expect(result.integer, equals(BigInt.from(125)));
    });

    test('GPU SQRT', () async {
      BigDec bigDec1 = BigDec.fromString("144");
      BigDec result = await bigDec1.gpuSqrt();
      expect(result.integer, equals(BigInt.from(12)));
    });
  });
}