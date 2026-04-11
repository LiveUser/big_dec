# BigDec
A library for big calculations.<br>
Hecho en Puerto Rico por Radamés J. Valentín Reyes<br>
Co-engineered by Copilot and Gemini<br>

**Note:** This library uses high-performance `Uint64List` limb storage to handle arbitrary-precision calculations (defaulting to 200+ decimal places) with significantly reduced heap overhead.

## Import
~~~dart
import 'package:big_dec/big_dec.dart';
~~~

## Constructors & Parsers
You can now convert from standard Dart types directly into `BigDec` while maintaining a specific precision cap.

### From BigInt
~~~dart
BigInt largeInt = BigInt.parse("12345678901234567890");
BigDec bigDec = BigDec.fromBigInt(largeInt, precision: 200);
~~~

### From Int
~~~dart
BigDec bigDec = BigDec.fromInt(42, precision: 200);
~~~

### From Double
~~~dart
BigDec bigDec = BigDec.fromDouble(3.14159, precision: 200);
~~~

### From String
~~~dart
BigDec bigDec = BigDec.fromString("1.23456789");
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
print(result.toStringAsFixed(100));
~~~

## Decimal Precision
Set a new decimal precision. Subsequent operations will adhere to this precision cap.
~~~dart
BigDec bigDec1 = BigDec.fromString("1");
BigDec updated = bigDec1.setDecimalPrecision(200);
~~~

## Rounding & Truncation
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");

// Round
BigDec rounded = bigDec1.round();

// Floor
BigDec floorVal = bigDec1.floor();

// Ceil
BigDec ceilVal = bigDec1.ceil();
~~~

## Absolute Value
~~~dart
BigDec bigDec1 = BigDec.fromString("-25");
BigDec result = bigDec1.abs();
print(result.toString());
~~~

## Power
~~~dart
BigDec bigDec1 = BigDec.fromString("25");
BigDec result = bigDec1.pow(BigInt.from(4));
print(result.toString());
~~~

## Square Root
~~~dart
BigDec bigDec1 = BigDec.fromString("25");
BigDec result = bigDec1.sqrt();
print(result.toString());
~~~

## Component Getters
Access the underlying magnitude components as `BigInt`.
~~~dart
BigDec bigDec1 = BigDec.fromString("123.456");
print(bigDec1.integer); // 123
print(bigDec1.decimal); // 456
~~~

## String Formatting
~~~dart
BigDec bigDec1 = BigDec.fromString("1.23456789");
print(bigDec1.toStringAsFixed(2)); // 1.23
~~~