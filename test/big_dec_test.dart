import 'package:big_dec/big_dec.dart';
import 'package:test/test.dart';

void main() {
  test('Addition', () {
    BigDec bigDec1 = BigDec.fromString("1.5");
    BigDec bigDec2 = BigDec.fromString("1.5");
    BigDec result = bigDec1.add(bigDec2);
    print(result.toStringAsFixed(0));
  });
  test('Subtraction', () {
    BigDec bigDec1 = BigDec.fromString("3.36");
    BigDec bigDec2 = BigDec.fromString("1.5");
    BigDec result = bigDec1.subtract(bigDec2);
    print(result.toStringAsFixed(4));
  });
  test('Multiplication', () {
    BigDec bigDec1 = BigDec.fromString("1.5");
    BigDec bigDec2 = BigDec.fromString("3");
    BigDec result = bigDec1.multiply(bigDec2);
    print(result.toStringAsFixed(4));
  });
  test('Division', () {
    BigDec bigDec1 = BigDec.fromString("1");
    bigDec1.setDecimalPrecision(100);
    BigDec bigDec2 = BigDec.fromString("3");
    BigDec result = bigDec1.divide(bigDec2);
    print(result.toString());
  });
  test("Pow", (){
    BigDec bigDec1 = BigDec.fromString("25");
    bigDec1.pow(BigInt.from(4));
    print(bigDec1.toString());
  });
  test("SQRT", (){
    BigDec bigDec1 = BigDec.fromString("25");
    bigDec1.sqrt();
    print(bigDec1.toString());
  });
}