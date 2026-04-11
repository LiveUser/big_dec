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

  // --- GETTERS ---

  /// Returns the integer part as a BigInt.
  BigInt get integer {
    BigInt full = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    BigInt result = full ~/ scale;
    return _isNegative ? -result : result;
  }

  /// Returns the decimal part as a BigInt.
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

  /// Compares this BigDec to another, aligning precision if necessary.
  @override
  int compareTo(BigDec other) {
    if (_isNegative && !other._isNegative) return -1;
    if (!_isNegative && other._isNegative) return 1;

    // Align precision for accurate byte comparison
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(_maxAmountOfDecimalPlaces)._bytes);
    
    int cmp = v1.compareTo(v2);
    return _isNegative ? -cmp : cmp;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BigDec) return false;
    return compareTo(other) == 0;
  }

  @override
  int get hashCode => Object.hash(_isNegative, _bytesToBigInt(_bytes), _maxAmountOfDecimalPlaces);

  // --- ALIGNMENT ---

  BigDec setDecimalPrecision(int newPrecision) {
    BigInt currentVal = _bytesToBigInt(_bytes);
    if (newPrecision > _maxAmountOfDecimalPlaces) {
      currentVal *= BigInt.from(10).pow(newPrecision - _maxAmountOfDecimalPlaces);
    } else if (newPrecision < _maxAmountOfDecimalPlaces) {
      currentVal ~/= BigInt.from(10).pow(_maxAmountOfDecimalPlaces - newPrecision);
    }
    return BigDec._(_bigIntToBytes(currentVal), newPrecision, isNegative: _isNegative);
  }

  // --- ARITHMETIC ---

  BigDec add(BigDec other) {
    if (other._maxAmountOfDecimalPlaces != _maxAmountOfDecimalPlaces) {
      return add(other.setDecimalPrecision(_maxAmountOfDecimalPlaces));
    }
    if (_isNegative == other._isNegative) {
      return BigDec._(_rawAdd(_bytes, other._bytes), _maxAmountOfDecimalPlaces, isNegative: _isNegative);
    }
    return subtract(other.abs());
  }

  BigDec subtract(BigDec other) {
    if (other._maxAmountOfDecimalPlaces != _maxAmountOfDecimalPlaces) {
      return subtract(other.setDecimalPrecision(_maxAmountOfDecimalPlaces));
    }
    if (_isNegative != other._isNegative) return add(other.abs());
    int cmp = _compareAbs(_bytes, other._bytes);
    if (cmp == 0) return BigDec.fromInt(0, precision: _maxAmountOfDecimalPlaces);

    bool thisIsGreater = cmp > 0;
    final res = _rawSubtract(thisIsGreater ? _bytes : other._bytes, thisIsGreater ? other._bytes : _bytes);
    return BigDec._(res, _maxAmountOfDecimalPlaces, isNegative: thisIsGreater ? _isNegative : !_isNegative);
  }

  BigDec multiply(BigDec other) {
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(_maxAmountOfDecimalPlaces)._bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return BigDec._(_bigIntToBytes((v1 * v2) ~/ scale), _maxAmountOfDecimalPlaces, 
        isNegative: _isNegative != other._isNegative);
  }

  BigDec divide(BigDec other) {
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(_maxAmountOfDecimalPlaces)._bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return BigDec._(_bigIntToBytes((v1 * scale) ~/ v2), _maxAmountOfDecimalPlaces, 
        isNegative: _isNegative != other._isNegative);
  }

  BigDec pow(BigInt exponent) {
    BigInt base = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    int exp = exponent.toInt();
    BigInt result = base.pow(exp);
    BigInt adjustment = scale.pow(exp - 1);
    return BigDec._(_bigIntToBytes(result ~/ adjustment), _maxAmountOfDecimalPlaces, 
        isNegative: _isNegative && exponent.isOdd);
  }

  BigDec sqrt() {
    BigInt value = _bytesToBigInt(_bytes);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    BigInt root = _sqrtBigInt(value * scale); 
    return BigDec._(_bigIntToBytes(root), _maxAmountOfDecimalPlaces, isNegative: false);
  }

  // --- PRIVATE TOOLS ---

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

  Uint8List _rawAdd(Uint8List a, Uint8List b) {
    int maxLen = math.max(a.length, b.length);
    final res = Uint8List(maxLen + 1);
    int carry = 0;
    for (int i = 0; i < maxLen || carry > 0; i++) {
      int sum = (i < a.length ? a[i] : 0) + (i < b.length ? b[i] : 0) + carry;
      if (i < res.length) res[i] = sum & 0xFF;
      carry = sum >> 8;
    }
    return _trim(res);
  }

  Uint8List _rawSubtract(Uint8List a, Uint8List b) {
    final res = Uint8List(a.length);
    int borrow = 0;
    for (int i = 0; i < a.length; i++) {
      int sub = a[i] - (i < b.length ? b[i] : 0) - borrow;
      borrow = sub < 0 ? 1 : 0;
      res[i] = sub < 0 ? sub + 256 : sub;
    }
    return _trim(res);
  }

  static int _compareAbs(Uint8List a, Uint8List b) {
    if (a.length != b.length) return a.length.compareTo(b.length);
    for (int i = a.length - 1; i >= 0; i--) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return 0;
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
  
  static BigDec fromInt(int i, {int precision = 200}) => BigDec.fromBigInt(BigInt.from(i), precision: precision);
}