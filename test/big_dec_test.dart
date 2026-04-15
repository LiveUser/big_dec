import 'package:big_dec/big_dec.dart';
import 'package:test/test.dart';

void main() {
  group('BigDec Print-Only Tests', () {

    test('Precision Inheritance in Chained Multiplication', () {
      final a = BigDec.fromString("1.5");
      final b = BigDec.fromString("3.0");
      final result = a.multiply(b);

      print("Chained Multiplication:");
      print("a = $a");
      print("b = $b");
      print("result = $result");
      print("decimalPlaces = ${result.decimalPlaces}");
      print("");
    });

    test('Explicit targetPrecision Override in Multiplication', () {
      final a = BigDec.fromString("1.5");
      final b = BigDec.fromString("3.0");
      final result = a.multiply(b, precision: 5);

      print("Explicit Precision Override:");
      print("result = $result");
      print("decimalPlaces = ${result.decimalPlaces}");
      print("");
    });

    test('Division Periodic Number Truncation', () {
      final one = BigDec.fromString("1");
      final three = BigDec.fromString("3");
      final result = one.divide(three, precision: 10);

      print("Division 1/3:");
      print("result = $result");
      print("decimalPlaces = ${result.decimalPlaces}");
      print("integer part = ${result.integer}");
      print("");
    });

    test('Division with Very Small Ratios', () {
      final error = BigDec.fromString("0.0000000001");
      final actual = BigDec.fromString("1000000");
      final result = error.divide(actual, precision: 20);

      print("Small Ratio Division:");
      print("result = $result");
      print("");
    });

    test('Chained Operation Precision Flow', () {
      final start = BigDec.fromString("1").setDecimalPrecision(50);
      final divisor = BigDec.fromString("3");
      final multiplier = BigDec.fromString("2");

      final result = start.divide(divisor).multiply(multiplier);

      print("Chained Precision Flow:");
      print("result = $result");
      print("decimalPlaces = ${result.decimalPlaces}");
      print("");
    });

    test('Addition/Subtraction Alignment', () {
      final highPrec = BigDec.fromString("1.00005");
      final lowPrec = BigDec.fromString("1.1");

      final sum = highPrec.add(lowPrec);
      final diff = highPrec.subtract(lowPrec);

      print("Addition/Subtraction Alignment:");
      print("sum = $sum");
      print("diff = $diff");
      print("");
    });

    test('Negative Value Arithmetic Integrity', () {
      final a = BigDec.fromString("-10");
      final b = BigDec.fromString("3");
      final result = a.divide(b, precision: 2);

      print("Negative Division:");
      print("result = $result");
      print("");
    });

    test('Square Root Precision Integrity', () {
      final two = BigDec.fromString("2").setDecimalPrecision(10);
      final root = two.sqrt();

      print("Square Root:");
      print("sqrt(2) = $root");
      print("decimalPlaces = ${root.decimalPlaces}");
      print("");
    });

    test('Large Exponent Power Stability', () {
      final base = BigDec.fromString("1.1").setDecimalPrecision(10);
      final result = base.pow(BigInt.from(2));

      print("Power Stability:");
      print("1.1^2 = $result");
      print("");
    });

    test("Parse negative exponents", () {
      final G = BigDec.fromString("6.67430e-11");

      print("Parse Scientific Notation:");
      print("G = $G");
      print("");
    });
  });

  // ============================================================
  //   COMPARISON, OPERATORS, AND PREDICATE TESTS
  // ============================================================

  group('Comparison & Predicate Tests', () {

    test('Sign Predicates', () {
      print("Sign Predicates:");
      print("0.isZero = ${BigDec.fromString("0").isZero}");
      print("-5.isNegative = ${BigDec.fromString("-5").isNegative}");
      print("5.isPositive = ${BigDec.fromString("5").isPositive}");
      print("10.0.isInteger = ${BigDec.fromString("10.0").isInteger}");
      print("");
    });

    test('Comparison Helpers', () {
      final a = BigDec.fromString("2");
      final b = BigDec.fromString("3");

      print("Comparison Helpers:");
      print("2 < 3 = ${a.lessThan(b)}");
      print("3 > 2 = ${b.greaterThan(a)}");
      print("2 == 2 = ${a.equalTo(BigDec.fromString("2"))}");
      print("");
    });

    test('Operator Overloads', () {
      final a = BigDec.fromString("5");
      final b = BigDec.fromString("2");

      print("Operator Overloads:");
      print("5 + 2 = ${a + b}");
      print("5 - 2 = ${a - b}");
      print("5 * 2 = ${a * b}");
      print("5 / 2 = ${a / b}");
      print("");
    });
  });

  // ============================================================
  //   TRANSCENDENTAL FUNCTION TESTS
  // ============================================================

  group('Transcendental Function Tests', () {

    test('exp(1)', () {
      final one = BigDec.fromString("1").setDecimalPrecision(20);
      final e = one.exp();

      print("exp(1):");
      print("e ≈ $e");
      print("");
    });

    test('ln(e)', () {
      final e = BigDec.fromString("2.718281828459045235").setDecimalPrecision(20);
      final ln = e.ln();

      print("ln(e):");
      print("ln ≈ $ln");
      print("");
    });

    test('sin(0)', () {
      final zero = BigDec.fromString("0").setDecimalPrecision(20);
      print("sin(0) = ${zero.sin()}");
      print("");
    });

    test('sin(pi/2)', () {
      final p = BigDec.pi(30);
      final halfPi = p.divide(BigDec.fromString("2"), precision: 30);
      final s = halfPi.sin();

      print("sin(pi/2):");
      print("≈ $s");
      print("");
    });

    test('cos(0)', () {
      final zero = BigDec.fromString("0").setDecimalPrecision(20);
      print("cos(0) = ${zero.cos()}");
      print("");
    });

    test('cos(pi)', () {
      final p = BigDec.pi(30);
      final c = p.cos();

      print("cos(pi):");
      print("≈ $c");
      print("");
    });

    test('pi() AGM precision check', () {
      final p = BigDec.pi(20);

      print("pi(20):");
      print("≈ $p");
      print("");
    });
  });
}
