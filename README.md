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

## GPU Acceleration
Initialize the GPU before using hardware-accelerated methods. These methods utilize WGSL compute shaders for high-throughput calculations.

### Initialize GPU
~~~dart
await BigDec.initGPU();
~~~

### GPU Multiplication
~~~dart
BigDec bigDec1 = BigDec.fromString("1234.56");
BigDec bigDec2 = BigDec.fromString("78.9");
BigDec result = await bigDec1.gpuMultiply(bigDec2);
print(result.toString());
~~~

### GPU Batch Multiplication
Process multiple calculations simultaneously on the GPU for maximum performance.
~~~dart
List<BigDec> listA = [BigDec.fromString("10"), BigDec.fromString("20")];
List<BigDec> listB = [BigDec.fromString("5"), BigDec.fromString("2")];
List<BigDec> results = await BigDec.gpuBatchMultiply(listA, listB);
~~~

### Other GPU Methods
The following methods are also available for GPU-based calculations:
~~~dart
BigDec resultAdd = await bigDec1.gpuAdd(bigDec2);
BigDec resultSub = await bigDec1.gpuSubtract(bigDec2);
BigDec resultDiv = await bigDec1.gpuDivide(bigDec2);
BigDec resultSqrt = await bigDec1.gpuSqrt();
BigDec resultPow = await bigDec1.gpuPow(BigInt.from(3));
~~~