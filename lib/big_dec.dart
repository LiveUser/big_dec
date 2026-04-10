import 'dart:math' as math;

class BigDec {
  final BigInt _integer;
  final BigInt _decimal;
  final int _maxAmountOfDecimalPlaces;

  BigDec({
    required BigInt integer,
    required BigInt decimal,
    required int decimalPlaces,
  })  : _integer = integer,
        _decimal = decimal,
        _maxAmountOfDecimalPlaces = decimalPlaces;

  BigInt get integer => _integer;
  BigInt get decimal => _decimal;
  int get decimalPlaces => _maxAmountOfDecimalPlaces;

  static int getMaxAmountOfDecimalPlaces() => 15;

  // --- IMMUTABLE UTILITIES ---

  BigDec setDecimalPrecision(int precision) {
    BigInt newDecimal = _decimal;
    if (precision > _maxAmountOfDecimalPlaces) {
      newDecimal *= BigInt.from(10).pow(precision - _maxAmountOfDecimalPlaces);
    } else if (precision < _maxAmountOfDecimalPlaces) {
      newDecimal ~/= BigInt.from(10).pow(_maxAmountOfDecimalPlaces - precision);
    }
    return BigDec(integer: _integer, decimal: newDecimal, decimalPlaces: precision);
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

  // --- MATH OPERATIONS (CPU) ---

  BigDec abs() => BigDec(integer: _integer.abs(), decimal: _decimal, decimalPlaces: _maxAmountOfDecimalPlaces);

  BigDec ceil() {
    if (BigInt.zero < _decimal) {
      return BigDec(integer: _integer + BigInt.one, decimal: BigInt.zero, decimalPlaces: _maxAmountOfDecimalPlaces);
    }
    return this;
  }

  BigDec floor() => BigDec(integer: _integer, decimal: BigInt.zero, decimalPlaces: _maxAmountOfDecimalPlaces);

  BigDec round() => BigDec.fromString(toStringAsFixed(0));

  BigDec sqrt({int? precisionOverride}) {
    if (_integer < BigInt.zero) throw Exception("Square root of negative number");
    if (_integer == BigInt.zero && _decimal == BigInt.zero) return this;
    int p = precisionOverride ?? _maxAmountOfDecimalPlaces;
    BigInt scale = BigInt.from(10).pow(p);
    BigInt flatValue = (_integer * scale) + _normalize(this, p);
    BigInt valueToRoot = flatValue * BigInt.from(10).pow(p);
    BigInt x = BigInt.one << (valueToRoot.bitLength + 1) ~/ 2;
    BigInt y = (x + valueToRoot ~/ x) >> 1;
    while (y < x) { x = y; y = (x + valueToRoot ~/ x) >> 1; }
    return BigDec(integer: x ~/ scale, decimal: x % scale, decimalPlaces: p);
  }

  BigDec pow(BigInt exponent, {int? precisionOverride}) {
    int p = precisionOverride ?? _maxAmountOfDecimalPlaces;
    if (exponent == BigInt.zero) return BigDec.fromString("1").setDecimalPrecision(p);
    if (exponent < BigInt.zero) {
      return BigDec.fromString("1").setDecimalPrecision(p).divide(this.pow(-exponent, precisionOverride: p), precisionOverride: p);
    }
    BigDec result = BigDec.fromString("1").setDecimalPrecision(p);
    BigDec base = this.setDecimalPrecision(p);
    BigInt exp = exponent;
    while (exp > BigInt.zero) {
      if (exp % BigInt.two == BigInt.one) result = result.multiply(base, precisionOverride: p);
      base = base.multiply(base, precisionOverride: p);
      exp ~/= BigInt.two;
    }
    return result;
  }

  BigDec add(BigDec number, {int? precisionOverride}) {
    int p = precisionOverride ?? math.max(_maxAmountOfDecimalPlaces, number._maxAmountOfDecimalPlaces);
    BigInt limit = BigInt.from(10).pow(p);
    BigInt resI = _integer + number._integer;
    BigInt resD = _normalize(this, p) + _normalize(number, p);
    if (resD >= limit) { resI += BigInt.one; resD -= limit; }
    return BigDec(integer: resI, decimal: resD, decimalPlaces: p);
  }

  BigDec subtract(BigDec number, {int? precisionOverride}) {
    int p = precisionOverride ?? math.max(_maxAmountOfDecimalPlaces, number._maxAmountOfDecimalPlaces);
    BigInt limit = BigInt.from(10).pow(p);
    BigInt resI = _integer - number._integer;
    BigInt resD = _normalize(this, p) - _normalize(number, p);
    if (resD < BigInt.zero) { resI -= BigInt.one; resD += limit; }
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

  // --- CONSTRUCTORS & FORMATTING ---

  static BigDec fromBigInt(BigInt bigInteger) => BigDec(integer: bigInteger, decimal: BigInt.zero, decimalPlaces: 0);

  static BigDec fromString(String decimalNumber) {
    if (decimalNumber.contains(".")) {
      List<String> parts = decimalNumber.split(".");
      return BigDec(integer: BigInt.parse(parts[0]), decimal: BigInt.parse(parts[1]), decimalPlaces: parts[1].length);
    }
    return BigDec(integer: BigInt.parse(decimalNumber), decimal: BigInt.zero, decimalPlaces: 0);
  }

  @override
  String toString() => "${_integer.toString()}.${_decimal.toString().padLeft(_maxAmountOfDecimalPlaces, '0')}";

  String toStringAsFixed(int decimalPlaces) {
    BigInt integerPart = _integer;
    String decimalAsString = _decimal.toString().padLeft(_maxAmountOfDecimalPlaces, '0');
    if (decimalAsString.length > _maxAmountOfDecimalPlaces) decimalAsString = decimalAsString.substring(0, _maxAmountOfDecimalPlaces);
    List<int> decimalsList = decimalAsString.split('').map(int.parse).toList();
    if (decimalPlaces < decimalsList.length) {
      for (int i = decimalsList.length - 1; i >= decimalPlaces; i--) {
        if (decimalsList[i] >= 5) {
          if (i > 0) {
            bool carried = false;
            for (int j = i - 1; j >= 0; j--) {
              if (decimalsList[j] < 9) { decimalsList[j] += 1; carried = true; break; } 
              else { decimalsList[j] = 0; }
            }
            if (!carried) integerPart += BigInt.one;
          } else { integerPart += BigInt.one; }
        }
      }
      decimalsList = decimalsList.sublist(0, decimalPlaces);
    }
    decimalAsString = decimalsList.join().padRight(decimalPlaces, '0');
    return decimalPlaces == 0 ? integerPart.toString() : "${integerPart.toString()}.$decimalAsString";
  }
}