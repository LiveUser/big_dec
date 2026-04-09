import 'dart:math' as math;

class BigDec {
  BigDec({
    required BigInt integer,
    required BigInt decimal,
    required int decimalPlaces,
  }) {
    _integer = integer;
    _decimal = decimal;
    _maxAmountOfDecimalPlaces = decimalPlaces;
  }

  BigInt _integer = BigInt.from(0);
  BigInt _decimal = BigInt.from(0);
  BigInt get integer => _integer;
  BigInt get decimal => _decimal;
  int _maxAmountOfDecimalPlaces = 10;

  static int getMaxAmountOfDecimalPlaces() => 15;

  void setDecimalPrecision(int precision) {
    if (precision > _maxAmountOfDecimalPlaces) {
      _decimal *= BigInt.from(10).pow(precision - _maxAmountOfDecimalPlaces);
    } else if (precision < _maxAmountOfDecimalPlaces) {
      _decimal ~/= BigInt.from(10).pow(_maxAmountOfDecimalPlaces - precision);
    }
    _maxAmountOfDecimalPlaces = precision;
  }

  BigInt _normalize(BigDec other, int targetP) {
    BigInt val = other._decimal;
    if (other._maxAmountOfDecimalPlaces < targetP) {
      val *= BigInt.from(10).pow(targetP - other._maxAmountOfDecimalPlaces);
    } else if (other._maxAmountOfDecimalPlaces > targetP) {
      val ~/= BigInt.from(10).pow(other._maxAmountOfDecimalPlaces - targetP);
    }
    return val;
  }

  String toStringAsFixed(int decimalPlaces) {
    BigInt integerPart = _integer;
    String decimalAsString = _decimal.toString().padLeft(_maxAmountOfDecimalPlaces, '0');
    
    if (decimalAsString.length > _maxAmountOfDecimalPlaces) {
      decimalAsString = decimalAsString.substring(0, _maxAmountOfDecimalPlaces);
    }
    
    List<int> decimalsList = decimalAsString.split('').map(int.parse).toList();

    if (decimalPlaces < decimalsList.length) {
      for (int i = decimalsList.length - 1; i >= decimalPlaces; i--) {
        int value = decimalsList[i];
        if (value >= 5) {
          if (i > 0) {
            bool carried = false;
            for (int j = i - 1; j >= 0; j--) {
              if (decimalsList[j] < 9) {
                decimalsList[j] += 1;
                carried = true;
                break;
              } else {
                decimalsList[j] = 0;
              }
            }
            if (!carried) integerPart += BigInt.one;
          } else {
            integerPart += BigInt.one;
          }
        }
      }
      decimalsList = decimalsList.sublist(0, decimalPlaces);
    }

    decimalAsString = decimalsList.join().padRight(decimalPlaces, '0');
    return decimalPlaces == 0 ? integerPart.toString() : "${integerPart.toString()}.$decimalAsString";
  }

  void ceil() {
    if (BigInt.zero < _decimal) {
      _decimal = BigInt.zero;
      _integer += BigInt.one;
    }
  }

  void floor() => _decimal = BigInt.zero;

  void round() {
    List<String> roundedStr = toStringAsFixed(0).split(".");
    _integer = BigInt.parse(roundedStr[0]);
    _decimal = BigInt.zero;
  }

  void pow(BigInt exponent, {int? precisionOverride}) {
    int p = precisionOverride ?? _maxAmountOfDecimalPlaces;
    BigDec result = BigDec.fromString("1");
    result.setDecimalPrecision(p);

    if (exponent == BigInt.zero) {
      // already 1
    } else if (exponent < BigInt.zero) {
      BigDec base = BigDec(integer: _integer, decimal: _decimal, decimalPlaces: _maxAmountOfDecimalPlaces);
      base.pow(-exponent, precisionOverride: p);
      result = result.divide(base, precisionOverride: p);
    } else {
      BigDec base = BigDec(integer: _integer, decimal: _decimal, decimalPlaces: _maxAmountOfDecimalPlaces);
      base.setDecimalPrecision(p);
      BigInt exp = exponent;
      while (exp > BigInt.zero) {
        if (exp % BigInt.two == BigInt.one) result = result.multiply(base, precisionOverride: p);
        base = base.multiply(base, precisionOverride: p);
        exp ~/= BigInt.two;
      }
    }
    _integer = result._integer;
    _decimal = result._decimal;
    _maxAmountOfDecimalPlaces = p;
  }

  void sqrt({Object? precisionOverride}) {
    if (_integer < BigInt.zero) throw Exception("Square root of negative number");
    if (_integer == BigInt.zero && _decimal == BigInt.zero) return;

    int p = (precisionOverride is int) ? precisionOverride : _maxAmountOfDecimalPlaces;

    // 1. Convert the current BigDec to a single flat BigInt at double the target precision
    // This allows us to extract 'p' decimal places accurately.
    BigInt scale = BigInt.from(10).pow(p);
    BigInt flatValue = (_integer * scale) + _normalize(this, p);
    
    // Shift the value left by 2*p to calculate the root at the desired scale
    BigInt valueToRoot = flatValue * BigInt.from(10).pow(p);

    // 2. Pure BigInt Integer Square Root (Newton's Method)
    // Initial guess: bit-shifting is a fast way to get close to the root
    BigInt x = BigInt.one << (valueToRoot.bitLength + 1) ~/ 2;
    BigInt y = (x + valueToRoot ~/ x) >> 1;

    while (y < x) {
      x = y;
      y = (x + valueToRoot ~/ x) >> 1;
    }

    // 3. Update internal state
    // x now contains (Integer + Decimal) as a flat BigInt at scale 10^p
    _integer = x ~/ scale;
    _decimal = x % scale;
    _maxAmountOfDecimalPlaces = p;
  }

  @override
  String toString() {
    return "${_integer.toString()}.${_decimal.toString().padLeft(_maxAmountOfDecimalPlaces, '0')}";
  }

  static BigDec fromBigInt(BigInt bigInteger) {
    return BigDec(integer: bigInteger, decimal: BigInt.zero, decimalPlaces: 0);
  }

  static BigDec fromString(String decimalNumber) {
    if (decimalNumber.contains(".")) {
      List<String> parts = decimalNumber.split(".");
      return BigDec(
        integer: BigInt.parse(parts[0]),
        decimal: BigInt.parse(parts[1]),
        decimalPlaces: parts[1].length,
      );
    }
    return BigDec(integer: BigInt.parse(decimalNumber), decimal: BigInt.zero, decimalPlaces: 0);
  }

  BigDec add(BigDec number, {int? precisionOverride}) {
    int p = precisionOverride ?? math.max(_maxAmountOfDecimalPlaces, number._maxAmountOfDecimalPlaces);
    BigInt limit = BigInt.from(10).pow(p);
    BigInt d1 = _normalize(this, p);
    BigInt d2 = _normalize(number, p);
    BigInt resI = _integer + number._integer;
    BigInt resD = d1 + d2;
    if (resD >= limit) {
      resI += BigInt.one;
      resD -= limit;
    }
    return BigDec(integer: resI, decimal: resD, decimalPlaces: p);
  }

  BigDec subtract(BigDec number, {int? precisionOverride}) {
    int p = precisionOverride ?? math.max(_maxAmountOfDecimalPlaces, number._maxAmountOfDecimalPlaces);
    BigInt limit = BigInt.from(10).pow(p);
    BigInt d1 = _normalize(this, p);
    BigInt d2 = _normalize(number, p);
    BigInt resI = _integer - number._integer;
    BigInt resD = d1 - d2;
    if (resD < BigInt.zero) {
      resI -= BigInt.one;
      resD += limit;
    }
    return BigDec(integer: resI, decimal: resD, decimalPlaces: p);
  }

  BigDec multiply(BigDec number, {int? precisionOverride}) {
    int p = precisionOverride ?? math.max(_maxAmountOfDecimalPlaces, number._maxAmountOfDecimalPlaces);
    BigInt scale = BigInt.from(10).pow(p);
    BigInt raw1 = (_integer * scale) + _normalize(this, p);
    BigInt raw2 = (number._integer * scale) + _normalize(number, p);
    BigInt prod = raw1 * raw2;
    BigInt fScale = scale * scale;
    return BigDec(integer: prod ~/ fScale, decimal: (prod % fScale) ~/ scale, decimalPlaces: p);
  }

  BigDec divide(BigDec divisor, {int? precisionOverride}) {
    int p = precisionOverride ?? math.max(_maxAmountOfDecimalPlaces, divisor._maxAmountOfDecimalPlaces);
    BigInt scale = BigInt.from(10).pow(p);
    BigInt num = (_integer * scale) + _normalize(this, p);
    BigInt den = (divisor._integer * scale) + _normalize(divisor, p);
    if (den == BigInt.zero) throw Exception("Division by zero");
    
    BigInt quotient = (num * scale) ~/ den;
    return BigDec(integer: quotient ~/ scale, decimal: quotient % scale, decimalPlaces: p);
  }
  BigDec abs() {
    return BigDec(
      integer: _integer.abs(),
      decimal: _decimal,
      decimalPlaces: _maxAmountOfDecimalPlaces,
    );
  }
}