import 'dart:typed_data';
import 'dart:math' as math;

class BigDec implements Comparable<BigDec> {
  final Uint8List _bytes;
  final int _maxAmountOfDecimalPlaces;
  final bool _isNegative;

  BigDec._(
    this._bytes, 
    this._maxAmountOfDecimalPlaces, {
    bool isNegative = false,
  }) : _isNegative = isNegative;

  // --- STATIC GETTERS ---
  static BigDec get zero => BigDec.fromInt(0);
  static BigDec get one => BigDec.fromInt(1);

  // --- GETTERS ---
  BigInt get integer {
    BigInt full = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    BigInt result = full ~/ scale;
    return _isNegative ? -result : result;
  }

  BigInt get decimal {
    BigInt full = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return (full % scale).abs();
  }

  int get decimalPlaces => _maxAmountOfDecimalPlaces;

  // --- CONSTRUCTORS ---
  BigDec({
    required BigInt integer,
    required BigInt decimal,
    int decimalPlaces = 200,
  })  : _maxAmountOfDecimalPlaces = decimalPlaces,
        _isNegative = integer < BigInt.zero,
        _bytes = _bigIntToBytes(
            (integer.abs() * BigInt.from(10).pow(decimalPlaces)) + decimal.abs());

  factory BigDec.fromBigInt(BigInt value, {int precision = 200}) =>
      BigDec(integer: value, decimal: BigInt.zero, decimalPlaces: precision);

  factory BigDec.fromString(String s) {
    // 1. Normalize input: lowercase and remove whitespace
    String input = s.trim().toLowerCase();
    if (input.isEmpty) return BigDec.zero;

    // 2. Handle Scientific Notation (e.g., 1.23e-10)
    if (input.contains('e')) {
      var parts = input.split('e');
      BigDec coefficient = BigDec.fromString(parts[0]);
      int exponent = int.parse(parts[1]);

      if (exponent == 0) return coefficient;
      
      if (exponent > 0) {
        // For positive exponents, we shift the decimal right by multiplying
        return coefficient.multiply(
          BigDec.fromBigInt(BigInt.from(10).pow(exponent), precision: 0),
          precision: coefficient.decimalPlaces
        );
      } else {
        // For negative exponents, increase precision and divide
        int newPrecision = coefficient.decimalPlaces + exponent.abs();
        return coefficient.divide(
          BigDec.fromBigInt(BigInt.from(10).pow(exponent.abs()), precision: 0),
          precision: newPrecision
        );
      }
    }

    // 3. Handle Standard Decimal Notation
    bool neg = input.startsWith('-');
    String clean = neg ? input.substring(1) : input;
    
    if (clean.contains(".")) {
      var parts = clean.split(".");
      String intStr = parts[0].isEmpty ? "0" : parts[0];
      String decStr = parts[1];
      int precision = decStr.length;
      
      // Combine integer and decimal into a single BigInt based on precision
      BigInt integerPart = BigInt.parse(intStr);
      BigInt decimalPart = BigInt.parse(decStr);
      
      return BigDec(
        integer: neg ? -integerPart : integerPart,
        decimal: decimalPart,
        decimalPlaces: precision,
      );
    }

    // 4. Handle pure Integers
    return BigDec(
      integer: BigInt.parse(input), 
      decimal: BigInt.zero, 
      decimalPlaces: 0
    );
  }

  // --- ALIGNMENT ---
  BigDec setDecimalPrecision(int newPrecision) {
    if (newPrecision == _maxAmountOfDecimalPlaces) return this;
    BigInt currentVal = _bytesToBigInt(_bytes);
    if (newPrecision > _maxAmountOfDecimalPlaces) {
      currentVal *= BigInt.from(10).pow(newPrecision - _maxAmountOfDecimalPlaces);
    } else {
      currentVal ~/= BigInt.from(10).pow(_maxAmountOfDecimalPlaces - newPrecision);
    }
    return BigDec._(_bigIntToBytes(currentVal), newPrecision, isNegative: _isNegative);
  }

  // --- ARITHMETIC ---
  BigDec add(BigDec other) {
    int precision = math.max(_maxAmountOfDecimalPlaces, other.decimalPlaces);
    Uint8List b1 = setDecimalPrecision(precision)._bytes;
    Uint8List b2 = other.setDecimalPrecision(precision)._bytes;

    if (_isNegative == other._isNegative) {
      return BigDec._(_rawAdd(b1, b2), precision, isNegative: _isNegative);
    }
    
    int cmp = _compareMagnitudes(b1, b2);
    if (cmp == 0) return BigDec.fromInt(0, precision: precision);
    
    bool b1IsGreater = cmp > 0;
    Uint8List res = b1IsGreater ? _rawSubtract(b1, b2) : _rawSubtract(b2, b1);
    return BigDec._(res, precision, isNegative: b1IsGreater ? _isNegative : !_isNegative);
  }

  BigDec subtract(BigDec other) {
    int precision = math.max(_maxAmountOfDecimalPlaces, other.decimalPlaces);
    Uint8List b1 = setDecimalPrecision(precision)._bytes;
    Uint8List b2 = other.setDecimalPrecision(precision)._bytes;

    if (_isNegative != other._isNegative) {
      return BigDec._(_rawAdd(b1, b2), precision, isNegative: _isNegative);
    }
    
    int cmp = _compareMagnitudes(b1, b2);
    if (cmp == 0) return BigDec.fromInt(0, precision: precision);
    
    bool b1IsGreater = cmp > 0;
    Uint8List res = b1IsGreater ? _rawSubtract(b1, b2) : _rawSubtract(b2, b1);
    return BigDec._(res, precision, isNegative: b1IsGreater ? _isNegative : !_isNegative);
  }

  /// Multiplies and inherits precision. Normalizes to [precision] if provided.
  BigDec multiply(BigDec other, {int? precision}) {
    int outPrecision = precision ?? math.max(_maxAmountOfDecimalPlaces, other.decimalPlaces);
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other._bytes);
    
    int combinedScale = _maxAmountOfDecimalPlaces + other.decimalPlaces;
    BigInt rawProduct = v1 * v2;
    
    if (combinedScale > outPrecision) {
      rawProduct ~/= BigInt.from(10).pow(combinedScale - outPrecision);
    } else if (combinedScale < outPrecision) {
      rawProduct *= BigInt.from(10).pow(outPrecision - combinedScale);
    }

    return BigDec._(_bigIntToBytes(rawProduct), outPrecision, isNegative: _isNegative != other._isNegative);
  }

  /// Divides v1 by v2. Scales v1 by [precision] before division to avoid truncation.
  BigDec divide(BigDec other, {int? precision}) {
    int outPrecision = precision ?? _maxAmountOfDecimalPlaces;
    BigInt v1 = _bytesToBigInt(_bytes);
    // Align divisor to host precision
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(other.decimalPlaces)._bytes);
    
    if (v2 == BigInt.zero) throw Exception("Division by zero");

    // Shift v1 to maintain decimal integrity before integer division
    BigInt scaleFactor = BigInt.from(10).pow(outPrecision + other.decimalPlaces - _maxAmountOfDecimalPlaces);
    BigInt result = (v1 * scaleFactor) ~/ v2;

    return BigDec._(_bigIntToBytes(result), outPrecision, isNegative: _isNegative != other._isNegative);
  }

  BigDec pow(BigInt exponent) {
    if (exponent == BigInt.zero) return BigDec.one.setDecimalPrecision(_maxAmountOfDecimalPlaces);
    BigDec res = BigDec.one.setDecimalPrecision(_maxAmountOfDecimalPlaces);
    BigDec base = this;
    BigInt e = exponent.abs();
    while (e > BigInt.zero) {
      if (e.isOdd) res = res.multiply(base, precision: _maxAmountOfDecimalPlaces);
      base = base.multiply(base, precision: _maxAmountOfDecimalPlaces);
      e >>= 1;
    }
    return res;
  }

  BigDec sqrt() {
    BigInt value = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    BigInt root = _sqrtBigInt(value * scale); 
    return BigDec._(_bigIntToBytes(root), _maxAmountOfDecimalPlaces, isNegative: false);
  }

  // --- INTERNAL TOOLS ---
  static int _compareMagnitudes(Uint8List a, Uint8List b) {
    if (a.length > b.length) return 1;
    if (b.length > a.length) return -1;
    for (int i = a.length - 1; i >= 0; i--) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }
    return 0;
  }

  static Uint8List _bigIntToBytes(BigInt n) {
    BigInt temp = n.abs();
    if (temp == BigInt.zero) return Uint8List.fromList([0]);
    int len = (temp.bitLength + 7) >> 3;
    final res = Uint8List(len);
    for (int i = 0; i < len; i++) {
      res[i] = (temp & BigInt.from(0xFF)).toInt();
      temp >>= 8;
    }
    return res;
  }

  static BigInt _bytesToBigInt(Uint8List b) {
    BigInt res = BigInt.zero;
    for (int i = b.length - 1; i >= 0; i--) res = (res << 8) | BigInt.from(b[i]);
    return res;
  }

  Uint8List _rawAdd(Uint8List a, Uint8List b) {
    int maxLen = math.max(a.length, b.length);
    final res = Uint8List(maxLen + 1);
    int carry = 0;
    for (int i = 0; i < maxLen; i++) {
      int valA = i < a.length ? a[i] : 0;
      int valB = i < b.length ? b[i] : 0;
      int sum = valA + valB + carry;
      res[i] = sum & 0xFF;
      carry = sum >> 8;
    }
    res[maxLen] = carry;
    return _trim(res);
  }

  Uint8List _rawSubtract(Uint8List a, Uint8List b) {
    final res = Uint8List(a.length);
    int borrow = 0;
    for (int i = 0; i < a.length; i++) {
      int valA = a[i];
      int valB = (i < b.length ? b[i] : 0) + borrow;
      if (valA < valB) {
        res[i] = (valA + 256) - valB;
        borrow = 1;
      } else {
        res[i] = valA - valB;
        borrow = 0;
      }
    }
    return _trim(res);
  }

  Uint8List _trim(Uint8List bytes) {
    int i = bytes.length - 1;
    while (i > 0 && bytes[i] == 0) i--;
    return bytes.sublist(0, i + 1);
  }

  BigInt _sqrtBigInt(BigInt n) {
    if (n < BigInt.zero) throw Exception("Negative SQRT");
    if (n < BigInt.from(2)) return n;
    BigInt x = BigInt.one << ((n.bitLength + 1) >> 1);
    while (true) {
      BigInt y = (x + n ~/ x) >> 1;
      if (y >= x) return x;
      x = y;
    }
  }

  BigDec abs() => BigDec._(_bytes, _maxAmountOfDecimalPlaces, isNegative: false);

  String toStringAsFixed(int fractionDigits) {
    BigInt full = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    BigInt intPart = full ~/ scale;
    BigInt fractionPart = (full % scale).abs();
    
    if (fractionDigits > _maxAmountOfDecimalPlaces) {
      fractionPart *= BigInt.from(10).pow(fractionDigits - _maxAmountOfDecimalPlaces);
    } else {
      fractionPart ~/= BigInt.from(10).pow(_maxAmountOfDecimalPlaces - fractionDigits);
    }
    return "${_isNegative ? '-' : ''}$intPart.${fractionPart.toString().padLeft(fractionDigits, '0')}";
  }

  @override
  String toString() => toStringAsFixed(_maxAmountOfDecimalPlaces);

  @override
  int compareTo(BigDec other) {
    if (_isNegative && !other._isNegative) return -1;
    if (!_isNegative && other._isNegative) return 1;
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other._bytes);
    int target = math.max(_maxAmountOfDecimalPlaces, other.decimalPlaces);
    v1 *= BigInt.from(10).pow(target - _maxAmountOfDecimalPlaces);
    v2 *= BigInt.from(10).pow(target - other.decimalPlaces);
    int cmp = v1.compareTo(v2);
    return _isNegative ? -cmp : cmp;
  }

  static BigDec fromInt(int i, {int precision = 200}) => BigDec.fromBigInt(BigInt.from(i), precision: precision);
}