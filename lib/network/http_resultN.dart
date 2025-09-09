/// HTTP请求结果封装类
///
/// 简化版本，专注于核心功能
///
/// 使用示例:
/// ```dart
/// // 创建成功结果
/// final result = HttpResultN<User>.success(userData);
///
/// // 创建失败结果
/// final result = HttpResultN<User>.failure(404, '用户不存在');
///
/// // 检查结果
/// if (result.isSuccess) {
///   print('数据: ${result.data}');
/// } else {
///   print('错误: ${result.msg}');
/// }
/// ```
class HttpResultN<T> {
  /// 请求是否成功
  final bool isSuccess;

  /// 响应状态码
  final int code;

  /// 响应消息
  final String? msg;

  /// 强类型数据
  final T? data;

  /// 数据列表
  final List<T>? dataList;

  /// 原始JSON数据
  final dynamic dataJson;

  /// 原始JSON列表
  final List<dynamic>? listJson;

  /// 构造函数
  const HttpResultN({
    required this.isSuccess,
    required this.code,
    this.msg,
    this.data,
    this.dataList,
    this.dataJson,
    this.listJson,
  });

  /// 创建成功结果
  factory HttpResultN.success({
    T? data,
    List<T>? dataList,
    dynamic dataJson,
    List<dynamic>? listJson,
    int code = 200,
    String? msg,
  }) {
    return HttpResultN(
      isSuccess: true,
      code: code,
      msg: msg,
      data: data,
      dataList: dataList,
      dataJson: dataJson,
      listJson: listJson,
    );
  }

  /// 创建失败结果
  factory HttpResultN.failure(int code, String msg, {dynamic dataJson}) {
    return HttpResultN(
      isSuccess: false,
      code: code,
      msg: msg,
      dataJson: dataJson,
    );
  }

  // ==================== 便利属性 ====================

  /// 是否失败
  bool get isFailure => !isSuccess;

  /// 是否有数据
  bool get hasData => data != null || dataJson != null;

  /// 是否有数据列表
  bool get hasDataList =>
      dataList != null && dataList!.isNotEmpty ||
      listJson != null && listJson!.isNotEmpty;

  /// 是否为空结果
  bool get isEmpty => !hasData && !hasDataList;

  // ==================== 数据访问方法 ====================

  /// 获取JSON数据
  Map<String, dynamic> getDataJson() {
    if (dataJson is Map<String, dynamic>) {
      return dataJson as Map<String, dynamic>;
    }
    return {};
  }

  /// 获取JSON列表
  List<dynamic> getListJson() {
    return listJson ?? [];
  }

  /// 获取动态数据
  dynamic getDataDynamic() => dataJson;

  // ==================== JSON-Model 转换方法 ====================

  /// 将结果转换为指定模型
  ///
  /// 使用示例:
  /// ```dart
  /// final userResult = result.asModel<User>(User.fromJson);
  /// final user = userResult.data; // User对象
  /// ```
  HttpResultN<R> asModel<R>(R Function(Map<String, dynamic>) fromJson) {
    if (isFailure) {
      return HttpResultN<R>.failure(code, msg ?? 'Request failed');
    }

    try {
      final jsonData = getDataJson();
      if (jsonData.isEmpty) {
        return HttpResultN<R>.failure(-1, 'No data to convert');
      }

      final model = fromJson(jsonData);
      return HttpResultN<R>.success(
        data: model,
        code: code,
        msg: msg,
        dataJson: dataJson,
      );
    } catch (e) {
      return HttpResultN<R>.failure(-1, 'Model conversion failed: $e');
    }
  }

  /// 将结果转换为指定模型列表
  ///
  /// 使用示例:
  /// ```dart
  /// final usersResult = result.asModelList<User>(User.fromJson);
  /// final users = usersResult.dataList; // List<User>
  /// ```
  HttpResultN<R> asModelList<R>(R Function(Map<String, dynamic>) fromJson) {
    if (isFailure) {
      return HttpResultN<R>.failure(code, msg ?? 'Request failed');
    }

    try {
      final jsonList = getListJson();
      if (jsonList.isEmpty) {
        return HttpResultN<R>.success(
          dataList: <R>[],
          code: code,
          msg: msg,
          listJson: listJson,
        );
      }

      final models = jsonList
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();

      return HttpResultN<R>.success(
        dataList: models,
        code: code,
        msg: msg,
        listJson: listJson,
      );
    } catch (e) {
      return HttpResultN<R>.failure(-1, 'Model list conversion failed: $e');
    }
  }

  /// 安全获取转换后的模型，失败时返回null
  ///
  /// 使用示例:
  /// ```dart
  /// final user = result.tryAsModel(User.fromJson);
  /// if (user != null) {
  ///   print('用户名: ${user.name}');
  /// }
  /// ```
  R? tryAsModel<R>(R Function(Map<String, dynamic>) fromJson) {
    if (isFailure) return null;

    try {
      final jsonData = getDataJson();
      if (jsonData.isEmpty) return null;
      return fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// 安全获取转换后的模型列表，失败时返回空列表
  ///
  /// 使用示例:
  /// ```dart
  /// final users = result.tryAsModelList(User.fromJson);
  /// print('用户数量: ${users.length}');
  /// ```
  List<R> tryAsModelList<R>(R Function(Map<String, dynamic>) fromJson) {
    if (isFailure) return <R>[];

    try {
      final jsonList = getListJson();
      if (jsonList.isEmpty) return <R>[];

      return jsonList.cast<Map<String, dynamic>>().map(fromJson).toList();
    } catch (e) {
      return <R>[];
    }
  }

  // ==================== 向后兼容方法 ====================

  /// 向后兼容的convert方法
  ///
  /// 旧版本使用模式：
  /// ```dart
  /// return result.convert(data: modelData);
  /// return result.convert(list: modelList);
  /// return result.convert(); // 保持原结果
  /// ```
  HttpResultN<R> convert<R>({R? data, List<R>? list}) {
    if (isFailure) {
      return HttpResultN<R>.failure(code, msg ?? 'Request failed');
    }

    if (data != null) {
      return HttpResultN<R>.success(
        data: data,
        code: code,
        msg: msg,
        dataJson: dataJson,
      );
    }

    if (list != null) {
      return HttpResultN<R>.success(
        dataList: list,
        code: code,
        msg: msg,
        listJson: listJson,
      );
    }

    // 无参数时，返回类型转换的结果（保持原有数据）
    return HttpResultN<R>(
      isSuccess: isSuccess,
      code: code,
      msg: msg,
      dataJson: dataJson,
      listJson: listJson,
    );
  }

  // ==================== 实用方法 ====================

  /// 创建副本
  HttpResultN<T> copyWith({
    bool? isSuccess,
    int? code,
    String? msg,
    T? data,
    List<T>? dataList,
    dynamic dataJson,
    List<dynamic>? listJson,
  }) {
    return HttpResultN(
      isSuccess: isSuccess ?? this.isSuccess,
      code: code ?? this.code,
      msg: msg ?? this.msg,
      data: data ?? this.data,
      dataList: dataList ?? this.dataList,
      dataJson: dataJson ?? this.dataJson,
      listJson: listJson ?? this.listJson,
    );
  }

  @override
  String toString() {
    final status = isSuccess ? 'Success' : 'Failure';
    final dataInfo = hasData
        ? 'hasData: true'
        : hasDataList
        ? 'hasDataList: true'
        : 'noData';

    return 'HttpResultN<$T>($status, code: $code, $dataInfo, msg: $msg)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HttpResultN<T>) return false;

    return isSuccess == other.isSuccess &&
        code == other.code &&
        msg == other.msg &&
        data == other.data &&
        dataList == other.dataList;
  }

  @override
  int get hashCode {
    return Object.hash(isSuccess, code, msg, data, dataList);
  }
}
