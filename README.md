# BigDec
A library for big calculations.<br>
Hecho en Puerto Rico por Radamés J. Valentín Reyes<br>
Co-engineered by Copilot and Gemini<br>

## Import
~~~dart
import 'package:big_dec/big_dec.dart';
~~~

## Addition
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec bigDec2 = BigDec.fromString("1.5");
BigDec result = bigDec1.add(bigDec2);
print(result.toStringAsFixed(0));
~~~

## Subtraction
~~~dart
BigDec bigDec1 = BigDec.fromString("3.36");
BigDec bigDec2 = BigDec.fromString("1.5");
BigDec result = bigDec1.subtract(bigDec2);
print(result.toStringAsFixed(4));
~~~

## Multiplication
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec bigDec2 = BigDec.fromString("3");
BigDec result = bigDec1.multiply(bigDec2);
print(result.toStringAsFixed(4));
~~~

## Division
~~~dart
BigDec bigDec1 = BigDec.fromString("1");
bigDec1.setDecimalPrecision(100);
BigDec bigDec2 = BigDec.fromString("3");
BigDec result = bigDec1.divide(bigDec2);
print(result.toStringAsFixed(BigDec.getMaxAmountOfDecimalPlaces()));
~~~

## Decimal Precision
Set a new decimal precision. The rest of the operations inherit the decimal precision from the first BigDec.
~~~dart
BigDec bigDec1 = BigDec.fromString("1");
bigDec1.setDecimalPrecision(100);
~~~

## Round
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec result = bigDec1.round();
~~~

## Floor
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec result = bigDec1.floor();
~~~

## Ceil
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec result = bigDec1.ceil();
~~~

## Power
~~~dart
BigDec bigDec1 = BigDec.fromString("25");
BigDec result = bigDec1.pow(BigInt.from(4));
print(result.toString());
~~~

## Square root
~~~dart
BigDec bigDec1 = BigDec.fromString("25");
BigDec result = bigDec1.sqrt();
print(result.toString());
~~~

## Absolute value
~~~dart
BigDec bigDec1 = BigDec.fromString("-25");
BigDec result = bigDec1.abs();
print(result.toString());
~~~