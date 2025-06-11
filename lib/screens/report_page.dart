import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../providers/budget_provider.dart';
import '../models/category_score.dart';

class ReportPage extends StatefulWidget {
  static const String id = 'report_page';

  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always refresh receipts and budgets when this page becomes visible
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    receiptProvider.fetchAllReceipts();
    budgetProvider.loadUserBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer2<ReceiptProvider, BudgetProvider>(
          builder: (context, receiptProvider, budgetProvider, _) {
            final scoreResult = receiptProvider.calculateWeeklyWellnessScore(
              budgetProvider.monthlyBudget,
            );
            final weekRange = scoreResult['weekRange'] as String;
            final totalScore = scoreResult['totalScore'] as int;
            final categoryScores =
                scoreResult['categoryScores'] as List<CategoryScore>;

            return SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Weekly Financial',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Wellness',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              weekRange,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  totalScore.toString(),
                                  style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  totalScore > 85
                                      ? Icons.emoji_emotions
                                      : totalScore >= 75
                                          ? Icons.sentiment_satisfied
                                          : Icons.sentiment_dissatisfied,
                                  color: totalScore > 85
                                      ? Color(0xFF4CAF50)
                                      : totalScore >= 75
                                          ? Color(0xFFFFA726)
                                          : Color(0xFFEF5350),
                                  size: 40,
                                ),
                              ],
                            ),
                            const Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Category Bars
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 10),
                      child: Column(
                        children: categoryScores
                            .map((cat) => _CategoryBar(cat: cat))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Weekly Summary
                    const Text(
                      'Weekly Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalScore >= 80
                          ? 'You maintained a strong budget this week!'
                          : totalScore >= 60
                              ? 'You are close to your budget goals.'
                              : 'Try to improve your spending next week.',
                      style: const TextStyle(
                          fontSize: 16, color: Color.fromARGB(221, 0, 0, 0)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showWeeklyInsights(context,
                                receiptProvider, budgetProvider.monthlyBudget),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: StadiumBorder(),
                              shadowColor: Colors.black12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.insights,
                                    size: 26, color: Colors.amberAccent),
                                const SizedBox(width: 12),
                                Text(
                                  'Show Last Week Insights',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Trends Placeholder
                    // Container(
                    //   height: 60,
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(14),
                    //   ),
                    //   child: const Center(
                    //     child: Text(
                    //       'Trends (Coming Soon)',
                    //       style: TextStyle(color: Colors.grey, fontSize: 16),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWeeklyInsights(BuildContext context,
      ReceiptProvider receiptProvider, double monthlyBudget) {
    final thisWeek =
        receiptProvider.calculateWeeklyWellnessScore(monthlyBudget);
    final lastWeek = receiptProvider.calculateWeeklyWellnessScore(monthlyBudget,
        weekOffset: 1);
    final insights = _generateWeeklyInsights(thisWeek, lastWeek);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AnimatedInsightsSheet(insights: insights);
      },
    );
  }

  List<String> _generateWeeklyInsights(
      Map<String, dynamic> thisWeek, Map<String, dynamic> lastWeek) {
    final List<String> insights = [];
    final thisScores = thisWeek['categoryScores'] as List<CategoryScore>;
    final lastScores = lastWeek['categoryScores'] as List<CategoryScore>;
    for (int i = 0; i < thisScores.length; i++) {
      final cat = thisScores[i];
      final lastCat = lastScores[i];
      if (cat.name == 'Rent & Utilities') continue;
      if (cat.percent > lastCat.percent) {
        if (cat.percent > cat.maxPercentInt) {
          insights.add('You overspent in ${cat.name} compared to last week.');
        } else {
          insights.add(
              'You spent more in ${cat.name} than last week, but stayed within budget.');
        }
      } else if (cat.percent < lastCat.percent) {
        insights.add(
            'You improved your spending in ${cat.name} compared to last week.');
      }
    }
    return insights;
  }
}

class _CategoryBar extends StatelessWidget {
  final CategoryScore cat;
  const _CategoryBar({required this.cat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(cat.icon, color: cat.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${cat.percent}% / ${cat.maxPercent}',
                      style: const TextStyle(
                        fontSize: 11.7,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (cat.percent / 35.0).clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: cat.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${cat.points}/${cat.maxPoints}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cat.color,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedInsightsSheet extends StatefulWidget {
  final List<String> insights;
  const _AnimatedInsightsSheet({required this.insights});

  @override
  State<_AnimatedInsightsSheet> createState() => _AnimatedInsightsSheetState();
}

class _AnimatedInsightsSheetState extends State<_AnimatedInsightsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Group insights by type and extract category info
    final overspent = <_InsightEntry>[];
    final improved = <_InsightEntry>[];
    for (final s in widget.insights) {
      final match = RegExp(r'in (.+?)(?: compared| than)').firstMatch(s);
      final catName = match != null ? match.group(1) ?? '' : '';
      final cat = _findCategoryScoreByName(context, catName);
      if (s.contains('overspent')) {
        overspent.add(_InsightEntry(text: s, cat: cat));
      } else if (s.contains('improved')) {
        improved.add(_InsightEntry(text: s, cat: cat));
      }
    }
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.insights, color: theme.primaryColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Weekly Insights',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (overspent.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Overspent Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ...overspent.map((entry) => _InsightCategoryTile(
                entry: entry, highlightColor: Colors.redAccent)),
            if (improved.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18.0, bottom: 8.0),
                child: Text('Improved Categories',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ...improved.map((entry) => _InsightCategoryTile(
                entry: entry, highlightColor: Colors.green)),
            if (overspent.isEmpty && improved.isEmpty)
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 22),
                  const SizedBox(width: 8),
                  const Text('No significant changes compared to last week.',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Close',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CategoryScore? _findCategoryScoreByName(BuildContext context, String name) {
    final receiptProvider =
        Provider.of<ReceiptProvider>(context, listen: false);
    final scoreResult = receiptProvider.calculateWeeklyWellnessScore(
      Provider.of<BudgetProvider>(context, listen: false).monthlyBudget,
    );
    final scores = scoreResult['categoryScores'] as List<CategoryScore>;
    for (final c in scores) {
      if (c.name == name) return c;
    }
    return null;
  }
}

class _InsightEntry {
  final String text;
  final CategoryScore? cat;
  _InsightEntry({required this.text, required this.cat});
}

class _InsightCategoryTile extends StatelessWidget {
  final _InsightEntry entry;
  final Color highlightColor;
  const _InsightCategoryTile(
      {required this.entry, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    final cat = entry.cat;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: highlightColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (cat != null)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
          if (cat != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                  fontSize: 16,
                  color: highlightColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
