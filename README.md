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
~~~

## Arithmetic Operations
Includes `add`, `subtract`, `multiply`, `divide`, `pow`, and `sqrt`.

## Equality & Comparison
Support for sorting and numerical comparison.
~~~dart
BigDec a = BigDec.fromString("1.5");
BigDec b = BigDec.fromString("1.50");

print(a.compare(b)); // 0 (Equal)
print(a == b);       // true
~~~

## Component Getters
~~~dart
BigDec bigDec = BigDec.fromString("123.456");
print(bigDec.integer); // 123
print(bigDec.decimal); // 456
~~~