import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/common/lazy_branch.dart';

void main() {
  testWidgets('非当前分支推迟到首次选中才构建，激活后保持挂载', (tester) async {
    final index = ValueNotifier<int>(0);
    addTearDown(index.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: index,
          builder: (context, value, child) => ShellBranchScope(
            index: value,
            child: const LazyBranch(
              index: 1,
              child: Text('迟到的页面'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('迟到的页面'), findsNothing);

    index.value = 1;
    await tester.pump();
    expect(find.text('迟到的页面'), findsOneWidget);

    // 切走后不再构建，但已经激活过的分支保持挂载（IndexedStack 自己保存状态）。
    index.value = 0;
    await tester.pump();
    expect(find.text('迟到的页面'), findsOneWidget);
  });

  testWidgets('没有 shell 作用域时直接构建', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LazyBranch(index: 2, child: Text('独立页面'))),
    );

    expect(find.text('独立页面'), findsOneWidget);
  });
}
