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
    String input = s.trim().toLowerCase();
    if (input.isEmpty) return BigDec.zero;

    bool neg = input.startsWith('-');
    if (neg || input.startsWith('+')) {
      input = input.substring(1);
    }

    String basePart;
    int exponent = 0;
    if (input.contains('e')) {
      var parts = input.split('e');
      basePart = parts[0];
      exponent = int.tryParse(parts[1]) ?? 0;
    } else {
      basePart = input;
    }

    BigInt combinedValue;
    int decimalPlaces = 0;

    if (basePart.contains(".")) {
      var parts = basePart.split(".");
      String intStr = parts[0].isEmpty ? "0" : parts[0];
      String decStr = parts[1];

      decimalPlaces = decStr.length;
      combinedValue = BigInt.parse(intStr + decStr);
    } else {
      combinedValue = BigInt.parse(basePart);
    }

    int finalPrecision = decimalPlaces - exponent;

    if (finalPrecision < 0) {
      combinedValue *= BigInt.from(10).pow(finalPrecision.abs());
      finalPrecision = 0;
    }

    return BigDec._(
      _bigIntToBytes(combinedValue),
      finalPrecision,
      isNegative: neg,
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

    return BigDec._(_bigIntToBytes(rawProduct), outPrecision,
        isNegative: _isNegative != other._isNegative);
  }

  BigDec divide(BigDec other, {int? precision}) {
    int outPrecision = precision ?? _maxAmountOfDecimalPlaces;
    BigInt v1 = _bytesToBigInt(_bytes);
    BigInt v2 = _bytesToBigInt(other.setDecimalPrecision(other.decimalPlaces)._bytes);

    if (v2 == BigInt.zero) throw Exception("Division by zero");

    BigInt scaleFactor =
        BigInt.from(10).pow(outPrecision + other.decimalPlaces - _maxAmountOfDecimalPlaces);
    BigInt result = (v1 * scaleFactor) ~/ v2;

    return BigDec._(_bigIntToBytes(result), outPrecision,
        isNegative: _isNegative != other._isNegative);
  }

  BigDec pow(BigInt exponent) {
    if (exponent == BigInt.zero) {
      return BigDec.one.setDecimalPrecision(_maxAmountOfDecimalPlaces);
    }
    BigDec res = BigDec.one.setDecimalPrecision(_maxAmountOfDecimalPlaces);
    BigDec base = this;
    BigInt e = exponent.abs();
    while (e > BigInt.zero) {
      if (e.isOdd) {
        res = res.multiply(base, precision: _maxAmountOfDecimalPlaces);
      }
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
    for (int i = b.length - 1; i >= 0; i--) {
      res = (res << 8) | BigInt.from(b[i]);
    }
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

  static BigDec fromInt(int i, {int precision = 200}) =>
      BigDec.fromBigInt(BigInt.from(i), precision: precision);

  // ============================================================
  //          EXTRA GETTERS / PREDICATES
  // ============================================================

  bool get isZero => _bytesToBigInt(_bytes) == BigInt.zero;
  bool get isNegative => _isNegative && !isZero;
  bool get isPositive => !_isNegative && !isZero;
  bool get isInteger => decimal == BigInt.zero;

  int get signum {
    if (isZero) return 0;
    return isNegative ? -1 : 1;
  }

  // ============================================================
  //          COMPARISON HELPERS
  // ============================================================

  bool greaterThan(BigDec other) => compareTo(other) > 0;
  bool lessThan(BigDec other) => compareTo(other) < 0;
  bool greaterOrEqual(BigDec other) => compareTo(other) >= 0;
  bool lessOrEqual(BigDec other) => compareTo(other) <= 0;
  bool equalTo(BigDec other) => compareTo(other) == 0;

  // ============================================================
  //          OPERATORS
  // ============================================================

  BigDec operator +(BigDec other) => add(other);
  BigDec operator -(BigDec other) => subtract(other);
  BigDec operator *(BigDec other) => multiply(other);
  BigDec operator /(BigDec other) => divide(other);

  BigDec operator -() =>
      BigDec._(_bytes, _maxAmountOfDecimalPlaces, isNegative: !_isNegative);

  BigDec operator %(BigDec other) {
    BigDec q = divide(other, precision: _maxAmountOfDecimalPlaces);
    BigDec qInt = BigDec.fromBigInt(q.integer, precision: _maxAmountOfDecimalPlaces);
    return subtract(qInt.multiply(other, precision: _maxAmountOfDecimalPlaces));
  }

  // ============================================================
  //          SIMPLE MATH HELPERS
  // ============================================================

  BigDec truncate() =>
      BigDec.fromBigInt(integer, precision: _maxAmountOfDecimalPlaces);

  BigDec floor() {
    if (!isNegative) return truncate();
    return isInteger
        ? this
        : BigDec.fromBigInt(integer - BigInt.one,
            precision: _maxAmountOfDecimalPlaces);
  }

  BigDec ceil() {
    if (isNegative) return truncate();
    return isInteger
        ? this
        : BigDec.fromBigInt(integer + BigInt.one,
            precision: _maxAmountOfDecimalPlaces);
  }

  BigDec round() {
    BigDec half =
        BigDec.fromString("0.5").setDecimalPrecision(_maxAmountOfDecimalPlaces);
    return isNegative ? (this + half).floor() : (this + half).floor();
  }

  BigDec min(BigDec other) => compareTo(other) <= 0 ? this : other;
  BigDec max(BigDec other) => compareTo(other) >= 0 ? this : other;

  BigDec clamp(BigDec lower, BigDec upper) {
    if (compareTo(lower) < 0) return lower;
    if (compareTo(upper) > 0) return upper;
    return this;
  }

  BigDec withPrecision(int newPrecision) => setDecimalPrecision(newPrecision);

  double toDouble() =>
      double.parse(toStringAsFixed(_maxAmountOfDecimalPlaces));

  // ============================================================
  //      HIGH-PRECISION TRANSCENDENTALS: PI, EXP, LOG, SIN, COS
  // ============================================================

  static BigDec _two(int precision) =>
      BigDec.fromInt(2, precision: precision);

  static BigDec _four(int precision) =>
      BigDec.fromInt(4, precision: precision);

  static BigDec _minusOne(int precision) =>
      BigDec.fromInt(-1, precision: precision);

  static BigDec _eps(int precision) =>
      BigDec.fromString("1e-$precision").setDecimalPrecision(precision);

  // Correct AGM-based π
  static BigDec pi(int precision) {
    int p = precision;
    BigDec one = BigDec.one.setDecimalPrecision(p);
    BigDec two = _two(p);
    BigDec quarter = BigDec.fromString("0.25").setDecimalPrecision(p);

    BigDec a = one;
    BigDec b = one.divide(BigDec.fromInt(2, precision: p).sqrt(), precision: p); // 1 / sqrt(2)
    BigDec t = quarter;
    BigDec pK = one;

    BigDec eps = _eps(p);
    int maxIter = p + 10;

    for (int i = 0; i < maxIter; i++) {
      BigDec aNext = (a + b).divide(two, precision: p);
      BigDec bNext = a.multiply(b, precision: p).sqrt();
      BigDec diff = a.subtract(aNext); // a_n - a_{n+1}
      BigDec diffSq = diff.multiply(diff, precision: p);
      t = t.subtract(pK.multiply(diffSq, precision: p));
      a = aNext;
      b = bNext;
      pK = pK.multiply(two, precision: p);

      if (diff.abs().lessOrEqual(eps)) break;
    }

    BigDec sum = a + b;
    BigDec sumSq = sum.multiply(sum, precision: p);
    BigDec denom = t.multiply(_four(p), precision: p);
    return sumSq.divide(denom, precision: p).setDecimalPrecision(p);
  }

  BigDec _modTwoPi(int precision) {
    int p = precision;
    BigDec twoPi = pi(p).multiply(_two(p), precision: p);
    BigDec x = setDecimalPrecision(p);
    BigInt kInt = x.divide(twoPi, precision: p).integer;
    BigDec k = BigDec.fromBigInt(kInt, precision: p);
    return x.subtract(k.multiply(twoPi, precision: p)).setDecimalPrecision(p);
  }

  BigDec exp({int? precision}) {
    int p = _maxAmountOfDecimalPlaces;
    BigDec x = setDecimalPrecision(p);
    if (x.isZero) return BigDec.one.setDecimalPrecision(p);

    bool neg = x._isNegative;
    if (neg) x = x.abs().setDecimalPrecision(p);

    BigDec one = BigDec.one.setDecimalPrecision(p);
    BigDec two = _two(p);

    int k = 0;
    BigDec threshold = one;
    int maxHalve = p + 10;
    while (x.greaterThan(threshold) && k < maxHalve) {
      x = x.divide(two, precision: p);
      k++;
    }

    BigDec term = one;
    BigDec sum = one;
    BigDec eps = _eps(p);
    int maxIter = p * 2 + 10;

    for (int n = 1; n <= maxIter; n++) {
      term = term
          .multiply(x, precision: p)
          .divide(BigDec.fromInt(n, precision: p), precision: p);
      if (term.abs().lessOrEqual(eps)) break;
      sum = sum + term;
    }

    for (int i = 0; i < k; i++) {
      sum = sum.multiply(sum, precision: p);
    }

    if (neg) {
      return one.divide(sum, precision: p).setDecimalPrecision(p);
    }
    return sum.setDecimalPrecision(p);
  }

  BigDec ln({int? precision}) {
    int p = _maxAmountOfDecimalPlaces;
    if (isZero || isNegative) {
      throw Exception("ln undefined for non-positive values");
    }

    BigDec x = setDecimalPrecision(p);
    BigDec y = BigDec.zero.setDecimalPrecision(p);
    BigDec one = BigDec.one.setDecimalPrecision(p);
    BigDec eps = _eps(p);
    int maxIter = p + 10;

    for (int i = 0; i < maxIter; i++) {
      BigDec ey = y.exp();
      BigDec frac = x.divide(ey, precision: p);
      BigDec delta = frac.subtract(one);
      y = y + delta;
      if (delta.abs().lessOrEqual(eps)) break;
    }

    return y.setDecimalPrecision(p);
  }

  BigDec sin({int? precision}) {
    int p = _maxAmountOfDecimalPlaces;
    BigDec x = _modTwoPi(p);

    BigDec piVal = pi(p);
    BigDec twoPi = piVal.multiply(_two(p), precision: p);
    BigDec minusPi = _minusOne(p).multiply(piVal, precision: p);

    if (x.greaterThan(piVal)) {
      x = x.subtract(twoPi);
    } else if (x.lessThan(minusPi)) {
      x = x.add(twoPi);
    }

    BigDec term = x;
    BigDec sum = x;
    BigDec x2 = x.multiply(x, precision: p);
    BigDec eps = _eps(p);
    int maxIter = p * 2 + 10;

    for (int n = 1; n <= maxIter; n++) {
      BigDec denom =
          BigDec.fromInt(2 * n * (2 * n + 1), precision: p);
      term = term
          .multiply(_minusOne(p), precision: p)
          .multiply(x2, precision: p)
          .divide(denom, precision: p);
      if (term.abs().lessOrEqual(eps)) break;
      sum = sum + term;
    }

    return sum.setDecimalPrecision(p);
  }

  BigDec cos({int? precision}) {
    int p = _maxAmountOfDecimalPlaces;
    BigDec x = _modTwoPi(p);

    BigDec piVal = pi(p);
    BigDec twoPi = piVal.multiply(_two(p), precision: p);
    BigDec minusPi = _minusOne(p).multiply(piVal, precision: p);

    if (x.greaterThan(piVal)) {
      x = x.subtract(twoPi);
    } else if (x.lessThan(minusPi)) {
      x = x.add(twoPi);
    }

    BigDec one = BigDec.one.setDecimalPrecision(p);
    BigDec term = one;
    BigDec sum = one;
    BigDec x2 = x.multiply(x, precision: p);
    BigDec eps = _eps(p);
    int maxIter = p * 2 + 10;

    for (int n = 1; n <= maxIter; n++) {
      BigDec denom =
          BigDec.fromInt(2 * n * (2 * n - 1), precision: p);
      term = term
          .multiply(_minusOne(p), precision: p)
          .multiply(x2, precision: p)
          .divide(denom, precision: p);
      if (term.abs().lessOrEqual(eps)) break;
      sum = sum + term;
    }

    return sum.setDecimalPrecision(p);
  }
}
