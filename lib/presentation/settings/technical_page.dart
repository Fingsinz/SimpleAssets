import 'package:flutter/material.dart';

class TechnicalPage extends StatelessWidget {
  const TechnicalPage({super.key});

  /// 技术说明的分节内容：后续补充直接往这个列表里追加即可。
  static const List<_TechSection> _sections = [
    _TechSection(
      icon: Icons.notes_rounded,
      title: '关于这个软件',
      body:
          '方寸有数是一个简单的个人持仓管理工具。'
          '目前仅支持安卓平台，行情数据也仅覆盖中国国内市场。\n\n'
          '我之所以做它，是因为我需要一个能汇总各平台持仓的工具，'
          '而市面上的软件用起来多少都有些不合手，于是借助 AI 写了这个软件。'
          '如果你好奇为什么没有某某功能，可以把上面这段当作借口。'
          '你也可以 fork 仓库，开发自己需要的功能。\n\n'
          '我认为理财管理是一件很有意思的事，也是一场持久战。'
          '我不提倡短线操作，因此软件的分析计算仅支持月度和年度维度。'
          '希望一起慢慢变富，慢慢自由。',
    ),
    _TechSection(
      icon: Icons.calculate_outlined,
      title: '收益口径 · 持仓',
      body:
          '持仓成本（摊薄）\n'
          '= 累计买入金额（含买入手续费） − 累计卖出回金（扣卖出手续费）\n'
          '成本单价 = 持仓成本 ÷ 剩余持有数量。清仓后归零，再买入重新起算；分红不计入成本。\n\n'
          '累计收益\n'
          '= 当前市值 + 累计卖出回金 + 累计分红净额 − 累计买入金额\n'
          '当前市值优先取「现价 × 数量」；未更新现价时按持仓成本计入，并在界面提示。'
          '现金不产生收益，恒为 0。\n\n'
          '收益率\n'
          '= 累计收益 ÷ 剩余持仓成本（摊薄后的净投入）\n'
          '清仓或净投入 ≤ 0 时，分母退回累计买入金额；分母仍 ≤ 0 时显示 0%。'
          '因此低买高卖后，成本单价下降，收益率会相应放大。\n\n'
          '年化收益率\n'
          '= (1 + 收益率)^(365 ÷ 持有天数) − 1\n'
          '持有天数从首笔交易日期（无流水时取买入日期）算起；'
          '持有天数 ≤ 0 或底数 ≤ 0 时不显示。\n\n'
          '累计投入 vs 持仓成本\n'
          '累计投入是历史买入总额；持仓成本是扣除卖出回金后的净投入。'
          '收益率的分母是持仓成本，不是累计投入。\n\n'
          '手续费与分红\n'
          '买入手续费计入买入成本；卖出手续费从卖出回金中扣除；'
          '分红按扣除手续费 / 税后的净额计入累计收益，不影响成本单价。\n\n'
          '拆股 / 折算\n'
          '只调整持有数量与成本单价，不产生现金；折算比例会同步回溯调整历史价格。\n\n'
          '现金\n'
          '现金按最新记录金额计入市值，没有涨跌，收益率为 0。',
    ),
    _TechSection(
      icon: Icons.pie_chart_outline_rounded,
      title: '收益口径 · 组合',
      body:
          '总投入\n'
          '= 各持仓累计买入金额（含买入手续费）之和。\n\n'
          '总市值\n'
          '= 各持仓当前市值之和；未更新现价的持仓按持仓成本计入。\n\n'
          '累计收益\n'
          '= 各持仓累计收益之和。\n\n'
          '组合收益率\n'
          '= 累计收益 ÷ 总投入。\n\n'
          '含现金\n'
          '关闭时，现金不计入统计；开启后，现金余额同时计入总市值与总投入，'
          '但现金本身不产生收益。该开关影响总览头部、组合收益率、资产配置与收益分析。\n\n'
          '品类表现\n'
          '品类收益率 = 品类累计收益 ÷ 品类累计买入金额。\n'
          '品类表现里的横条编码的是收益率，不是配置占比；配置占比显示在右侧百分比。\n\n'
          '收益排行与现价覆盖率\n'
          '收益排行按累计收益从高到低取前 5 项，只统计已更新现价、且仍有持仓的非现金资产；'
          '未更新现价的持仓不进入排行。\n'
          '现价覆盖率 = 已更新现价的非现金持仓数 ÷ 仍有持仓的非现金持仓数；'
          '现金与已清仓不计入。',
    ),
    _TechSection(
      icon: Icons.timeline_rounded,
      title: '收益口径 · 分析',
      body:
          '估值点\n'
          '从首笔非现金交易所在月开始，到当前月份；每月取该月最后一天（当前月取今天）。'
          '首笔交易的前一天作为起始点，市值为 0。\n'
          '每个估值点取该日期之前最近一次价格；如果价格观察之后发生过折算，'
          '会按累计折算比例回溯调整。没有可用价格时，用该持仓的毛成本均价估算市值，'
          '并标记为「估算」。现金按该日期之前最新一条现金记录的金额估值。\n\n'
          '区间收益\n'
          '= 期末市值 − 期初市值 − 区间净投入 − 现金余额变化 + 区间分红净额\n'
          '区间净投入 = 买入金额（含费） − 卖出回金（扣费）。\n'
          '现金余额变化只在开启「含现金」时计入；首笔交易之前已有的现金视为外部投入，'
          '从首段收益中扣除。\n'
          '买入、卖出与现金余额变化都视为外部现金流，不计入收益；分红净额计入收益。\n\n'
          '直接收益率\n'
          '= 区间收益 ÷ 期初市值\n'
          '期初市值为 0 时，改用 区间收益 ÷ 区间买入金额（首月常见）。\n'
          '年度用该年第一个估值点的期初市值（为 0 时用全年买入金额）；'
          '记录以来用「记录以来收益」÷（累计买入 + 当前现金，开启含现金时）。\n\n'
          '时间加权收益率（TWR）\n'
          '月度每段 r = 区间收益 ÷ 期初市值，TWR = (1 + r₁)(1 + r₂)… − 1。\n'
          '期初市值为 0 的区间（通常是首月）无法计算 r，不参与链乘。\n'
          '年度 / 记录以来：对相应区间内可计算的 r 连乘后减 1。\n\n'
          '年化收益率\n'
          '月度：按 (1 + 月度直接收益率)^12 − 1 折算。\n'
          '年度：当年按 (1 + 年度直接收益率)^(365 ÷ 已过天数) − 1；'
          '往年不再折算，直接等于年度直接收益率。\n'
          '记录以来：按 (1 + 直接收益率)^(365 ÷ 记录天数) − 1。\n'
          '底数 ≤ 0 时不显示。\n\n'
          '最大回撤\n'
          '用月末估值构造收益指数：有可计算 r 的区间乘以 (1 + r)，首月用 (1 + 直接收益率) 起算；'
          '记录历史峰值，回撤 = (当前指数 ÷ 峰值 − 1) × 100%。\n'
          '月度明细里的回撤取该月直接收益率与 0 的较小值；'
          '年度 / 记录以来的最大回撤取区间内各月末累计回撤的最小值；'
          '折线图的回撤曲线就是每个月末相对历史峰值的累计回撤。\n'
          '回撤按月末采样，不计算月内最高点到最低点的回撤。\n\n'
          '收益年历\n'
          '每格是该月的直接收益率；全年胶囊是该年的直接收益率。红涨绿跌，颜色越深幅度越大。\n'
          '如果某个月期末估值缺少价格、按成本估算，该月会标记，'
          '年历下方提示「部分月份按成本估算」。\n\n'
          '估算标记\n'
          '只要区间内任一估值点缺少价格、按成本估算，该月 / 年 / 记录以来都会标记为估算；'
          '图表和明细仍会展示，但结果不是实际成交价口径。\n\n'
          '显示精度\n'
          '金额 2 位小数、单价 4 位小数、收益率 2 位小数、年历 1 位小数；'
          '内部金额与份额使用 Decimal 计算，避免浮点误差。\n\n'
          '范围\n'
          '分析只做月度与年度，不做日内或短线；没有非现金交易流水时，不生成收益细节。',
    ),
    _TechSection(
      icon: Icons.cloud_outlined,
      title: '行情数据源',
      body:
          '基金：天天基金最新净值。\n'
          '股票 / ETF：新浪财经实时行情。\n'
          '贵金属现价请在详情页手动填写。\n'
          '网络异常时会保留上次价格。\n'
          '支持手动输入某月最后一个交易日的价格。',
    ),
    _TechSection(
      icon: Icons.architecture_rounded,
      title: '技术架构',
      body:
          'Flutter · Riverpod · Drift (SQLite) · Material 3\n'
          'Clean Architecture',
    ),
    _TechSection(
      icon: Icons.link,
      title: 'Github',
      body:
          'https://github.com/Fingsinz/SimpleAssets/tree/main\n'
          '本软件不收集用户数据，也不接入广告或统计 SDK。\n'
          '如需反馈问题或建议，请在 Github 提交 issue，或通过邮箱联系作者。',
    ),
    // 需要新增技术说明时，按上面的格式在列表末尾追加：
    // _TechSection(
    //   icon: Icons.notes_rounded,
    //   title: '补充说明',
    //   body: '在这里填写更多技术细节。',
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('技术说明')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in _sections)
              _Section(
                icon: section.icon,
                title: section.title,
                body: section.body,
              ),
          ],
        ),
      ),
    );
  }
}

class _TechSection {
  final IconData icon;
  final String title;
  final String body;

  const _TechSection({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
