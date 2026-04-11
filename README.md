# BigDec
A library for big calculations.<br>
Hecho en Puerto Rico por Radamés J. Valentín Reyes<br>
Co-engineered by Copilot and Gemini<br>

**Note:** This library uses high-performance `Uint8List` storage to handle arbitrary-precision calculations (defaulting to 200+ decimal places) with significantly reduced heap overhead.

## Import
~~~dart
import 'package:big_dec/big_dec.dart';
~~~

## Constructors & Parsers
Convert standard Dart types into `BigDec` while maintaining a specific precision cap.

### From BigInt
~~~dart
BigInt largeInt = BigInt.parse("12345678901234567890");
BigDec bigDec = BigDec.fromBigInt(largeInt, precision: 200);
~~~

### From Int
~~~dart
BigDec bigDec = BigDec.fromInt(42, precision: 200);
~~~

### From String
~~~dart
BigDec bigDec = BigDec.fromString("1.23456789");
~~~

## Arithmetic Operations
The library ensures precise results by aligning decimal precision across operands.

### Addition
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec bigDec2 = BigDec.fromString("1.5");
BigDec result = bigDec1.add(bigDec2); // Result: 3.0
~~~

### Subtraction
~~~dart
BigDec bigDec1 = BigDec.fromString("3.36");
BigDec bigDec2 = BigDec.fromString("1.5");
BigDec result = bigDec1.subtract(bigDec2); // Result: 1.86
~~~

### Multiplication
~~~dart
BigDec bigDec1 = BigDec.fromString("1.5");
BigDec bigDec2 = BigDec.fromString("3");
BigDec result = bigDec1.multiply(bigDec2); // Result: 4.5
~~~

### Division
~~~dart
BigDec bigDec1 = BigDec.fromString("1").setDecimalPrecision(10);
BigDec bigDec2 = BigDec.fromString("3");
BigDec result = bigDec1.divide(bigDec2); // Result: 0.3333333333
~~~

## Advanced Math
Logic updated to maintain decimal alignment during complex operations.

### Power
~~~dart
BigDec bigDec1 = BigDec.fromString("25");
BigDec result = bigDec1.pow(BigInt.from(2));
print(result.integer); // 625
~~~

### Square Root
Fixed scaling logic ensures that the root is correctly placed within the decimal space.
~~~dart
BigDec bigDec1 = BigDec.fromString("25");
BigDec result = bigDec1.sqrt();
print(result.integer); // 5
~~~

## Equality & Comparison
The library now supports standard Dart comparison patterns.
~~~dart
BigDec a = BigDec.fromString("1.5");
BigDec b = BigDec.fromString("1.50");

print(a == b);      // true
print(a.compareTo(b) == 0); // true
~~~

## Component Getters
Access underlying magnitude components as `BigInt`.
~~~dart
BigDec bigDec1 = BigDec.fromString("123.456");
print(bigDec1.integer); // 123
print(bigDec1.decimal); // 456
~~~

## Precision Management
Adjust decimal precision manually. Operations will adhere to this precision cap.
~~~dart
BigDec bigDec1 = BigDec.fromString("1");
BigDec updated = bigDec1.setDecimalPrecision(200);
~~~

## String Formatting
~~~dart
BigDec bigDec1 = BigDec.fromString("1.23456789");
print(bigDec1.toStringAsFixed(2)); // 1.23
~~~