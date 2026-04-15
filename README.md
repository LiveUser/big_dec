# BigDec
A library for big calculations.<br>
Hecho en Puerto Rico por Radamés J. Valentín Reyes<br>
Co-engineered by Copilot and Gemini<br>

**Note:** This library uses high-performance `Uint8List` storage to handle arbitrary-precision calculations (defaulting to 200+ decimal places).

## Constants
~~~dart
BigDec zero = BigDec.zero;
BigDec one = BigDec.one;
~~~

## Constructors
~~~dart
BigDec bigDec = BigDec.fromInt(42, precision: 200);
BigDec bigDecStr = BigDec.fromString("1.2345");
BigDec bigDecRaw = BigDec(integer: BigInt.from(10), decimal: BigInt.from(5));
~~~

## Arithmetic Operations
Includes standard operators and named methods.
~~~dart
BigDec sum = a + b;           // or a.add(b)
BigDec diff = a - b;          // or a.subtract(b)
BigDec product = a * b;       // or a.multiply(b)
BigDec quotient = a / b;      // or a.divide(b)
BigDec remainder = a % b;
BigDec neg = -a;
~~~

## Advanced Math & Transcendentals
High-precision implementations for complex simulations.
~~~dart
BigDec power = a.pow(BigInt.from(10));
BigDec root = a.sqrt();
BigDec absolute = a.abs();

// Transcendental Functions
BigDec pi = BigDec.pi(200);
BigDec naturalLog = a.ln();
BigDec exponent = a.exp();
BigDec sine = a.sin();
BigDec cosine = a.cos();
~~~

## Equality & Comparison
Support for sorting and numerical comparison logic.
~~~dart
if (a.greaterThan(b)) { ... }
if (a == b) { ... } // Also supports compareTo(other)
~~~

## Component Getters & Predicates
~~~dart
BigDec val = BigDec.fromString("-123.456");

print(val.integer);    // -123
print(val.decimal);    // 456
print(val.isNegative); // true
print(val.isInteger);  // false
print(val.signum);     // -1
~~~

## Rounding & Precision
~~~dart
BigDec rounded = val.round();
BigDec floored = val.floor();
BigDec ceiled = val.ceil();
BigDec truncated = val.truncate();

// Adjusting precision
BigDec highRes = val.withPrecision(500);
~~~

## Utility & Output
~~~dart
String fixed = val.toStringAsFixed(2); // "-123.46"
String full = val.toString();
double approx = val.toDouble();
~~~