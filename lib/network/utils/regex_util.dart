class RegexUtil {
  static bool isLocalImagePath(String path) {
    return RegExp(r'^/.+').hasMatch(path);
  }

  static bool isNetworkImagePath(String path) {
    return RegExp(r'^(http|https)://.+').hasMatch(path);
  }

  static bool isAssetPath(String path) {
    return RegExp(r'^[a-zA-Z0-9]+://').hasMatch(path);
  }

  ///身份证号码正则
  static final RegExp _idCardRegExp = RegExp(
    r'^[1-9]\d{5}(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}(\d|X)$',
  );

  ///校验码权重因子
  static const List<int> _weightFactors = [
    7,
    9,
    10,
    5,
    8,
    4,
    2,
    1,
    6,
    3,
    7,
    9,
    10,
    5,
    8,
    4,
    2,
  ];

  ///校验码对应的值
  static const List<String> _checkCodes = [
    '1',
    '0',
    'X',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2',
  ];

  ///验证身份证号码是否合法
  static bool isValidIdCard(String idNumber) {
    if (idNumber.length != 18 || !_idCardRegExp.hasMatch(idNumber)) {
      return false;
    }

    // 计算校验码
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      sum += int.parse(idNumber[i]) * _weightFactors[i];
    }
    int mod = sum % 11;
    String expectedCheckCode = _checkCodes[mod];

    return idNumber[17] == expectedCheckCode;
  }
}
