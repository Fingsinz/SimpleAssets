import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/presentation/analysis/widgets/performance_chart.dart';

void main() {
  group('统计曲线纵轴刻度', () {
    test('边界标签不再与整刻度重叠', () {
      const cases = [
        [0.2, 0.9, 1.6, 2.4],
        [-0.4, -1.2, -0.7, -2.1],
        [1.2, 3.7, 6.1, 9.4],
        [-12.5, 3.4, 0.0, 8.8],
        [0.0, 0.0, 0.0],
      ];
      for (final values in cases) {
        final scale = ChartAxisScale.fromValues(values);
        final labels = scale.labels;
        final tag = values.toString();

        expect(scale.interval, greaterThan(0), reason: tag);
        for (var i = 0; i < labels.length; i++) {
          expect(labels[i], greaterThan(scale.min), reason: tag);
          expect(labels[i], lessThan(scale.max), reason: tag);
          if (i > 0) {
            expect(
              labels[i] - labels[i - 1],
              closeTo(scale.interval, scale.interval * 0.001),
              reason: '$tag 刻度间距不均',
            );
          }
        }
        // 最上沿的标签至少离顶边一个刻度，文字不会被压到图表外沿。
        if (labels.isNotEmpty) {
          expect(
            scale.max - labels.last,
            greaterThanOrEqualTo(scale.interval * 0.999),
            reason: '$tag 顶部标签离顶边太近',
          );
          expect(
            labels.first - scale.min,
            greaterThanOrEqualTo(scale.interval * 0.999),
            reason: '$tag 底部标签离底边太近',
          );
        }
        expect(scale.min, lessThanOrEqualTo(0), reason: tag);
        expect(scale.max, greaterThanOrEqualTo(0), reason: tag);
      }
    });

    test('数据范围被完整包住，且顶部留白不小于 15% 刻度', () {
      const values = [0.2, 2.4];
      final scale = ChartAxisScale.fromValues(values);
      expect(scale.min, lessThanOrEqualTo(0.2));
      expect(scale.max, greaterThanOrEqualTo(2.4));
      expect(scale.max - 2.4, greaterThanOrEqualTo(scale.interval * 0.15));
    });
  });
}
