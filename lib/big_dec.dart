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
    bool neg = s.startsWith('-');
    String clean = neg ? s.substring(1) : s;
    if (clean.contains(".")) {
      var parts = clean.split(".");
      int precision = parts[1].length;
      return BigDec(
          integer: BigInt.parse(neg ? "-${parts[0]}" : parts[0]),
          decimal: BigInt.parse(parts[1]),
          decimalPlaces: precision);
    }
    return BigDec(integer: BigInt.parse(s), decimal: BigInt.zero, decimalPlaces: 0);
  }

  // --- COMPARISON & EQUALITY ---

  int compare(BigDec other) {
    if (_isNegative && !other._isNegative) return -1;
    if (!_isNegative && other._isNegative) return 1;

    // Manual magnitude comparison to avoid recursion via setDecimalPrecision
    Uint8List b1 = _bytes;
    Uint8List b2 = other._bytes;

    if (_maxAmountOfDecimalPlaces != other._maxAmountOfDecimalPlaces) {
      // Use BigInt for cross-precision comparison to ensure accuracy
      BigInt v1 = _bytesToBigInt(_bytes);
      BigInt v2 = _bytesToBigInt(other._bytes);
      int target = math.max(_maxAmountOfDecimalPlaces, other._maxAmountOfDecimalPlaces);
      v1 *= BigInt.from(10).pow(target - _maxAmountOfDecimalPlaces);
      v2 *= BigInt.from(10).pow(target - other._maxAmountOfDecimalPlaces);
      int cmp = v1.compareTo(v2);
      return _isNegative ? -cmp : cmp;
    }

    int cmp = _compareMagnitudes(b1, b2);
    return _isNegative ? -cmp : cmp;
  }

  static int _compareMagnitudes(Uint8List a, Uint8List b) {
    if (a.length > b.length) return 1;
    if (b.length > a.length) return -1;
    for (int i = a.length - 1; i >= 0; i--) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }
    return 0;
  }

  @override
  int compareTo(BigDec other) => compare(other);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BigDec) return false;
    return compare(other) == 0;
  }

  @override
  int get hashCode => Object.hash(_isNegative, _bytesToBigInt(_bytes), _maxAmountOfDecimalPlaces);

  bool equals(BigDec other) => compare(other) == 0;

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
    int precision = _maxAmountOfDecimalPlaces;
    Uint8List b1 = _bytes;
    // Align other to this precision scale
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
    int precision = _maxAmountOfDecimalPlaces;
    Uint8List b1 = _bytes;
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

  BigDec multiply(BigDec other) {
    BigInt v1 = _bytesToBigInt(_bytes);
    // Align and Clamp: Use this instance's precision as the limit
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(_maxAmountOfDecimalPlaces)._bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    
    // Result is clamped to the scale of the host object
    return BigDec._(_bigIntToBytes((v1 * v2) ~/ scale), _maxAmountOfDecimalPlaces, 
        isNegative: _isNegative != other._isNegative);
  }

  BigDec divide(BigDec other) {
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(_maxAmountOfDecimalPlaces)._bytes);
    if (v2 == BigInt.zero) throw IntegerDivisionByZeroException();

    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return BigDec._(_bigIntToBytes((v1 * scale) ~/ v2), _maxAmountOfDecimalPlaces, 
        isNegative: _isNegative != other._isNegative);
  }

  BigDec pow(BigInt exponent) {
    if (exponent == BigInt.zero) return BigDec.one.setDecimalPrecision(_maxAmountOfDecimalPlaces);
    BigDec res = BigDec.one.setDecimalPrecision(_maxAmountOfDecimalPlaces);
    BigDec base = this;
    BigInt e = exponent.abs();
    while (e > BigInt.zero) {
      if (e.isOdd) res = res.multiply(base); // multiply() handles the clamping
      base = base.multiply(base);
      e >>= 1;
    }
    return res;
  }

  BigDec sqrt() {
    BigInt value = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    // Adjust value to maintain precision after sqrt
    BigInt root = _sqrtBigInt(value * scale); 
    return BigDec._(_bigIntToBytes(root), _maxAmountOfDecimalPlaces, isNegative: false);
  }

  // --- PRIVATE TOOLS (BITWISE/BYTEWISE) ---

  Uint8List _rawAdd(Uint8List a, Uint8List b) {
    int maxLen = math.max(a.length, b.length);
    final res = Uint8List(maxLen + 1);
    int carry = 0;
    for (int i = 0; i < maxLen; i++) {
      int valA = i < a.length ? a[i] : 0;
      int valB = i < b.length ? b[i] : 0;
      int sum = valA + valB + carry;
      res[i] = sum & 0xFF; // Bytewise addition
      carry = sum >> 8;    // Bitwise carry
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
  
  static BigDec fromInt(int i, {int precision = 200}) => BigDec.fromBigInt(BigInt.from(i), precision: precision);
}