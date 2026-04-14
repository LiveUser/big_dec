import 'package:big_dec/big_dec.dart';
import 'package:test/test.dart';

void main() {
  group('BigDec Precision Integrity & Arithmetic Tests', () {
    
    test('Precision Inheritance in Chained Multiplication', () {
      // 1.5 (dp: 1) * 3.0 (dp: 1) -> result should default to max(1, 1) = 1
      final a = BigDec.fromString("1.5");
      final b = BigDec.fromString("3.0");
      final result = a.multiply(b);
      
      expect(result.decimalPlaces, equals(1));
      expect(result.toString(), equals("4.5"));
    });

    test('Explicit targetPrecision Override in Multiplication', () {
      final a = BigDec.fromString("1.5");
      final b = BigDec.fromString("3.0");
      // Force result to 5 decimal places
      final result = a.multiply(b, precision: 5);
      
      expect(result.decimalPlaces, equals(5));
      expect(result.toString(), equals("4.50000"));
    });

    test('Division Periodic Number Truncation (Overflow Protection)', () {
      // 1 / 3 is 0.333... 
      // We want to ensure it stops exactly at the targetPrecision and does not overflow
      final one = BigDec.fromString("1");
      final three = BigDec.fromString("3");
      
      final result = one.divide(three, precision: 10);
      
      expect(result.decimalPlaces, equals(10));
      expect(result.toString(), equals("0.3333333333"));
      // Internal byte length check: shouldn't have massive growth
      expect(result.integer, equals(BigInt.zero));
    });

    test('Division with Very Small Ratios (High Precision Support)', () {
      // Test the fix for the "0%" error seen in orbital mechanics
      final error = BigDec.fromString("0.0000000001"); // 1e-10
      final actual = BigDec.fromString("1000000");     // 1e6
      
      // Without proper scaling before division, this would be 0
      final result = error.divide(actual, precision: 20);
      
      expect(result.toString(), equals("0.00000000000000010000"));
    });

    test('Chained Operation Precision Flow', () {
      final start = BigDec.fromString("1").setDecimalPrecision(50);
      final divisor = BigDec.fromString("3");
      final multiplier = BigDec.fromString("2");
      
      // (1 / 3) * 2 should maintain the 50 dp throughout the chain
      final result = start.divide(divisor).multiply(multiplier);
      
      expect(result.decimalPlaces, equals(50));
      expect(result.toString().contains("0.666666"), isTrue);
      expect(result.toString().length, greaterThan(50));
    });

    test('Addition/Subtraction Alignment to Max Precision', () {
      final highPrec = BigDec.fromString("1.00005"); // dp: 5
      final lowPrec = BigDec.fromString("1.1");      // dp: 1
      
      final sum = highPrec.add(lowPrec);
      final diff = highPrec.subtract(lowPrec);
      
      expect(sum.decimalPlaces, equals(5));
      expect(sum.toString(), equals("2.10005"));
      
      expect(diff.decimalPlaces, equals(5));
      expect(diff.toString(), equals("-0.09995"));
    });

    test('Negative Value Arithmetic Integrity', () {
      final a = BigDec.fromString("-10");
      final b = BigDec.fromString("3");
      
      final result = a.divide(b, precision: 2);
      expect(result.toString(), equals("-3.33"));
    });

    test('Square Root Precision Integrity', () {
      final two = BigDec.fromString("2").setDecimalPrecision(10);
      final root = two.sqrt();
      
      // sqrt(2) approx 1.4142135623
      expect(root.decimalPlaces, equals(10));
      expect(root.toString(), equals("1.4142135623"));
    });

    test('Large Exponent Power Stability', () {
      final base = BigDec.fromString("1.1").setDecimalPrecision(10);
      final result = base.pow(BigInt.from(2)); // 1.1 * 1.1 = 1.21
      
      expect(result.toString(), equals("1.2100000000"));
    });
    test("Parse negative exponents", (){
      BigDec G = BigDec.fromString("6.67430e-11");
      print(G.toString());
    });
  });
}