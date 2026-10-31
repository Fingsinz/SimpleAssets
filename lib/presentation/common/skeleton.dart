import 'package:flutter/material.dart';

import '../theme/theme_presets.dart';

/// 纸色占位块：加载时先搭出最终卡片的骨架，避免居中 spinner 造成的跳变。
class SkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// 概览页加载骨架：大色块 → 配置卡片 → 三行持仓。
class OverviewSkeleton extends StatelessWidget {
  const OverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final preset = Theme.of(context).extension<AppPalette>()?.preset;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SkeletonBlock(height: 158, radius: preset?.headerRadius ?? 24),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkeletonBlock(width: 80, height: 14),
                    Spacer(),
                    SkeletonBlock(width: 56, height: 11),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: SkeletonBlock(width: 132, height: 132, radius: 66),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: SkeletonBlock(height: 32)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBlock(height: 32)),
                  ],
                ),
                const SizedBox(height: 9),
                const Row(
                  children: [
                    Expanded(child: SkeletonBlock(height: 32)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonBlock(height: 32)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(width: 96, height: 20, radius: 6),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < 3; i++) ...[
          const _AssetCardSkeleton(),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// 持仓页加载骨架：与最终资产卡片同形。
class HoldingsSkeleton extends StatelessWidget {
  const HoldingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      children: [
        for (var i = 0; i < 6; i++) ...[
          const _AssetCardSkeleton(),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// 分析页加载骨架：收益概览 → 年历 → 统计曲线。
class AnalysisSkeleton extends StatelessWidget {
  const AnalysisSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkeletonBlock(width: 80, height: 14),
                    Spacer(),
                    SkeletonBlock(width: 54, height: 18, radius: 9),
                  ],
                ),
                const SizedBox(height: 16),
                const SkeletonBlock(width: 150, height: 24, radius: 6),
                const SizedBox(height: 14),
                const SkeletonBlock(height: 1, radius: 0),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(child: SkeletonBlock(height: 28)),
                    SizedBox(width: 18),
                    Expanded(child: SkeletonBlock(height: 28)),
                  ],
                ),
                const SizedBox(height: 14),
                const SkeletonBlock(height: 8, radius: 4),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(width: 84, height: 20, radius: 6),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkeletonBlock(width: 80, height: 14),
                    Spacer(),
                    SkeletonBlock(width: 72, height: 24, radius: 8),
                  ],
                ),
                const SizedBox(height: 12),
                for (var row = 0; row < 3; row++) ...[
                  const Row(
                    children: [
                      Expanded(child: SkeletonBlock(height: 50, radius: 8)),
                      SizedBox(width: 6),
                      Expanded(child: SkeletonBlock(height: 50, radius: 8)),
                      SizedBox(width: 6),
                      Expanded(child: SkeletonBlock(height: 50, radius: 8)),
                      SizedBox(width: 6),
                      Expanded(child: SkeletonBlock(height: 50, radius: 8)),
                    ],
                  ),
                  if (row < 2) const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Align(
          alignment: Alignment.centerLeft,
          child: SkeletonBlock(width: 84, height: 20, radius: 6),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    SkeletonBlock(width: 80, height: 14),
                    Spacer(),
                    SkeletonBlock(width: 96, height: 30, radius: 8),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonBlock(height: 26, radius: 8),
                const SizedBox(height: 12),
                const SkeletonBlock(height: 220, radius: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetCardSkeleton extends StatelessWidget {
  const _AssetCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            const SkeletonBlock(width: 40, height: 40, radius: 12),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 96, height: 14, radius: 5),
                  SizedBox(height: 7),
                  SkeletonBlock(width: 64, height: 10, radius: 4),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SkeletonBlock(width: 76, height: 14, radius: 5),
                SizedBox(height: 7),
                SkeletonBlock(width: 52, height: 10, radius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
