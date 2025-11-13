/// 解绑操作返回数据
class UnbindResult {
  final int reasonId;
  final String? supplementReason;

  const UnbindResult({required this.reasonId, this.supplementReason});
}
