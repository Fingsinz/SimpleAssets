/// 轻量 Result 类型，避免在业务代码中到处抛异常。
class Result<T> {
  final T? data;
  final String? error;

  const Result.success(this.data) : error = null;

  const Result.failure(this.error) : data = null;

  bool get isSuccess => error == null;

  bool get isFailure => error != null;

  /// 与 Kotlin 的 `fold` 类似，统一处理成功/失败分支。
  R fold<R>(R Function(String error) onFailure, R Function(T data) onSuccess) {
    if (isSuccess) {
      return onSuccess(data as T);
    }
    return onFailure(error!);
  }
}
