import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_widget.dart';
import 'loading_widget.dart';

/// 统一处理 AsyncValue 的 loading / error / data 三态。
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final VoidCallback? onRetry;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.builder,
    this.loading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: builder,
      loading: () => loading ?? const LoadingWidget(),
      error: (error, stackTrace) => AppErrorWidget(
        message: '$error',
        onRetry: onRetry,
      ),
    );
  }
}
