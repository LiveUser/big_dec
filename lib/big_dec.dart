import 'dart:typed_data';

class BigDec {
  final Uint64List _limbs;
  final int _maxAmountOfDecimalPlaces;
  final bool _isNegative;

  BigDec._(this._limbs, this._maxAmountOfDecimalPlaces, {bool isNegative = false})
      : _isNegative = isNegative;

  // --- GETTERS ---

  /// Returns the integer part as a BigInt.
  BigInt get integer {
    BigInt full = _limbsToBigInt(_limbs);
    BigInt result = full ~/ BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return _isNegative ? -result : result;
  }

  /// Returns the decimal part as a BigInt.
  BigInt get decimal {
    BigInt full = _limbsToBigInt(_limbs);
    return (full % BigInt.from(10).pow(_maxAmountOfDecimalPlaces)).abs();
  }

  int get decimalPlaces => _maxAmountOfDecimalPlaces;

  // --- CONSTRUCTORS & PARSERS ---

  BigDec({
    required BigInt integer,
    required BigInt decimal,
    int decimalPlaces = 200,
  })  : _maxAmountOfDecimalPlaces = decimalPlaces,
        _isNegative = integer < BigInt.zero,
        _limbs = _bigIntToLimbs((integer.abs() * BigInt.from(10).pow(decimalPlaces)) + decimal.abs());

  factory BigDec.fromBigInt(BigInt value, {int precision = 200}) =>
      BigDec(integer: value, decimal: BigInt.zero, decimalPlaces: precision);

  factory BigDec.fromInt(int value, {int precision = 200}) =>
      BigDec.fromBigInt(BigInt.from(value), precision: precision);

  factory BigDec.fromDouble(double value, {int precision = 200}) =>
      BigDec.fromString(value.toString()).setDecimalPrecision(precision);

  factory BigDec.fromString(String s) {
    bool neg = s.startsWith('-');
    String clean = neg ? s.substring(1) : s;
    if (clean.contains(".")) {
      var parts = clean.split(".");
      return BigDec(
          integer: BigInt.parse(neg ? "-${parts[0]}" : parts[0]),
          decimal: BigInt.parse(parts[1]),
          decimalPlaces: parts[1].length);
    }
    return BigDec(integer: BigInt.parse(s), decimal: BigInt.zero, decimalPlaces: 0);
  }

  // --- BITMATH CORE ---

  BigDec add(BigDec other) {
    if (_isNegative == other._isNegative) {
      final res = Uint64List(12);
      int carry = 0;
      for (int i = 0; i < 12; i++) {
        int sum = _limbs[i] + other._limbs[i] + carry;
        res[i] = sum;
        carry = (sum < _limbs[i] || (sum == _limbs[i] && carry > 0)) ? 1 : 0;
      }
      return BigDec._(res, _maxAmountOfDecimalPlaces, isNegative: _isNegative);
    }
    return subtract(other.abs());
  }

  BigDec subtract(BigDec other) {
    if (_isNegative != other._isNegative) return add(other.abs());
    int cmp = _compareAbs(_limbs, other._limbs);
    if (cmp == 0) return BigDec.fromInt(0, precision: _maxAmountOfDecimalPlaces);

    bool thisIsGreater = cmp > 0;
    final res = Uint64List(12);
    final a = thisIsGreater ? _limbs : other._limbs;
    final b = thisIsGreater ? other._limbs : _limbs;

    int borrow = 0;
    for (int i = 0; i < 12; i++) {
      int sub = a[i] - b[i] - borrow;
      res[i] = sub;
      borrow = (a[i] < b[i] + borrow) ? 1 : 0;
    }
    return BigDec._(res, _maxAmountOfDecimalPlaces, isNegative: thisIsGreater ? _isNegative : !_isNegative);
  }

  BigDec multiply(BigDec other) {
    BigInt v1 = _limbsToBigInt(_limbs);
    BigInt v2 = _limbsToBigInt(other._limbs);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return BigDec._(_bigIntToLimbs((v1 * v2) ~/ scale), _maxAmountOfDecimalPlaces, isNegative: _isNegative != other._isNegative);
  }

  BigDec divide(BigDec other) {
    BigInt v1 = _limbsToBigInt(_limbs);
    BigInt v2 = _limbsToBigInt(other._limbs);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    return BigDec._(_bigIntToLimbs((v1 * scale) ~/ v2), _maxAmountOfDecimalPlaces, isNegative: _isNegative != other._isNegative);
  }

  BigDec pow(BigInt exponent) {
    BigDec res = BigDec.fromInt(1, precision: _maxAmountOfDecimalPlaces);
    BigDec base = this;
    BigInt e = exponent;
    while (e > BigInt.zero) {
      if (e.isOdd) res = res.multiply(base);
      base = base.multiply(base);
      e >>= 1;
    }
    return res;
  }

  BigDec sqrt() {
    BigInt val = _limbsToBigInt(_limbs);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    BigInt valueToRoot = val * scale;
    BigInt x = BigInt.one << (valueToRoot.bitLength + 1) ~/ 2;
    BigInt y = (x + valueToRoot ~/ x) >> 1;
    while (y < x) {
      x = y;
      y = (x + valueToRoot ~/ x) >> 1;
    }
    return BigDec._(_bigIntToLimbs(x), _maxAmountOfDecimalPlaces);
  }

  // --- TRUNCATION & UTILITIES ---

  BigDec abs() => BigDec._(_limbs, _maxAmountOfDecimalPlaces, isNegative: false);
  BigDec floor() => BigDec(integer: integer, decimal: BigInt.zero, decimalPlaces: _maxAmountOfDecimalPlaces);
  BigDec ceil() => (decimal > BigInt.zero) ? BigDec(integer: integer + BigInt.one, decimal: BigInt.zero, decimalPlaces: _maxAmountOfDecimalPlaces) : this;

  BigDec round() {
    BigInt half = BigInt.from(10).pow(_maxAmountOfDecimalPlaces) ~/ BigInt.two;
    return decimal >= half ? ceil() : floor();
  }

  BigDec setDecimalPrecision(int p) {
    BigInt val = _limbsToBigInt(_limbs);
    if (p > _maxAmountOfDecimalPlaces) val *= BigInt.from(10).pow(p - _maxAmountOfDecimalPlaces);
    else if (p < _maxAmountOfDecimalPlaces) val ~/= BigInt.from(10).pow(_maxAmountOfDecimalPlaces - p);
    return BigDec._(_bigIntToLimbs(val), p, isNegative: _isNegative);
  }

  // --- INTERNAL BITWISE HELPERS ---

  static int _compareAbs(Uint64List a, Uint64List b) {
    for (int i = 11; i >= 0; i--) {
      if (a[i] > b[i]) return 1;
      if (a[i] < b[i]) return -1;
    }
    return 0;
  }

  static Uint64List _bigIntToLimbs(BigInt value) {
    final limbs = Uint64List(12);
    BigInt temp = value.abs();
    for (int i = 0; i < 12; i++) {
      limbs[i] = (temp & BigInt.from(0xFFFFFFFFFFFFFFFF)).toUnsigned(64).toInt();
      temp >>= 64;
    }
    return limbs;
  }

  static BigInt _limbsToBigInt(Uint64List limbs) {
    BigInt res = BigInt.zero;
    for (int i = 11; i >= 0; i--) res = (res << 64) | BigInt.from(limbs[i]);
    return res;
  }

  // --- STRING FORMATTING ---

  String toStringAsFixed(int p) {
    BigInt full = _limbsToBigInt(_limbs);
    BigInt scale = BigInt.from(10).pow(_maxAmountOfDecimalPlaces);
    String decStr = (full % scale).abs().toString().padLeft(_maxAmountOfDecimalPlaces, '0');
    decStr = p < decStr.length ? decStr.substring(0, p) : decStr.padRight(p, '0');
    return "${_isNegative ? '-' : ''}${full ~/ scale}${p > 0 ? '.' : ''}$decStr";
  }

  @override
  String toString() => toStringAsFixed(_maxAmountOfDecimalPlaces);
}