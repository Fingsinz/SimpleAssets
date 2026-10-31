import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
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

  testWidgets('横坐标最右侧保留安全区域', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const points = [
      ChartPoint(label: '2026-01', value: 0),
      ChartPoint(label: '2026-02', value: 1),
      ChartPoint(label: '2026-03', value: 2),
      ChartPoint(label: '2026-04', value: 3),
      ChartPoint(label: '2026-05', value: 4),
      ChartPoint(label: '2026-06', value: 5),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PerformanceChart(points: points, color: Colors.red),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final lastX = chart.data.lineBarsData.single.spots.last.x;
    // 安全区应由右侧标题区让出，而不是把数据区继续向右拉伸：
    // 否则水平网格线仍然画满整个绘图区，安全区看起来没有生效。
    expect(chart.data.maxX, lastX, reason: '数据区应止于最后一个估值点');
    final rightTitles = chart.data.titlesData.rightTitles.sideTitles;
    expect(
      rightTitles.showTitles && rightTitles.reservedSize > 0,
      isTrue,
      reason: '右侧需要为最后一个横坐标标签预留安全区',
    );
  });

  testWidgets('水平网格线随右侧安全区一起收窄', (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const points = [
      ChartPoint(label: '2026-01', value: 0),
      ChartPoint(label: '2026-02', value: 1),
      ChartPoint(label: '2026-03', value: 2),
      ChartPoint(label: '2026-04', value: 3),
      ChartPoint(label: '2026-05', value: 4),
      ChartPoint(label: '2026-06', value: 5),
    ];
    const shotKey = Key('grid-shot');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue).copyWith(
            outlineVariant: const Color(0xFF808080),
          ),
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: shotKey,
            // RepaintBoundary 不包含 Scaffold 的背景，必须自带白底，
            // 否则半透明网格线与透明像素混在一起无法区分。
            child: const ColoredBox(
              color: Colors.white,
              child: PerformanceChart(points: points, color: Colors.red),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chartWidth = tester.getSize(find.byType(PerformanceChart)).width;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(shotKey),
    );

    var rightmostGridX = 0;
    var gridPixels = 0;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final data = bytes!.buffer.asUint8List();
      final width = image.width;
      for (var y = 10; y < 160; y++) {
        for (var x = width ~/ 2; x < width; x++) {
          final offset = (y * width + x) * 4;
          final r = data[offset];
          final g = data[offset + 1];
          final b = data[offset + 2];
          final maxChannel = math.max(r, math.max(g, b));
          final minChannel = math.min(r, math.min(g, b));
          // 网格线是灰色半透明细线；白底、红色曲线和浅红填充都不满足。
          final isGridGray = maxChannel - minChannel < 12 &&
              maxChannel > 140 &&
              maxChannel < 235;
          if (isGridGray) {
            rightmostGridX = x;
            gridPixels++;
          }
        }
      }
    });

    expect(gridPixels, greaterThan(0), reason: '测试应能识别到水平网格线');
    expect(
      chartWidth - rightmostGridX,
      greaterThan(20),
      reason: '水平网格线应止于最后一个估值点，为右侧安全区让位',
    );
  });
}
