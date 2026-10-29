import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/analysis/widgets/performance_chart.dart';

void main() {
  testWidgets('统计曲线不会越出图表区域遮挡上方内容', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 单品持仓常见的形状：横盘后单月大幅波动。
    // 平滑曲线会在拐点处越过自动缩放的 Y 轴范围。
    const points = [
      ChartPoint(label: '2026-01', value: 0),
      ChartPoint(label: '2026-02', value: 1),
      ChartPoint(label: '2026-03', value: 2),
      ChartPoint(label: '2026-04', value: -60),
      ChartPoint(label: '2026-05', value: -55),
      ChartPoint(label: '2026-06', value: -50),
    ];
    const shotKey = Key('chart-shot');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: RepaintBoundary(
            key: shotKey,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 100),
                PerformanceChart(points: points, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chartTop =
        tester.getTopLeft(find.byType(PerformanceChart)).dy.floor();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(shotKey),
    );

    var redPixels = 0;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final data = bytes!.buffer.asUint8List();
      final width = image.width;
      for (var y = 0; y < chartTop; y++) {
        for (var x = 0; x < width; x++) {
          final offset = (y * width + x) * 4;
          final r = data[offset];
          final g = data[offset + 1];
          final b = data[offset + 2];
          // 图表以外的区域是纯白背景，出现红色说明曲线画出了图表范围。
          if (r > 180 && g < 120 && b < 120) {
            redPixels++;
          }
        }
      }
    });

    expect(redPixels, 0, reason: '曲线越出图表顶部会遮挡上方的「收益 / 回撤」切换按钮');
  });
}
