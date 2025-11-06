import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../shared/theme/app_theme.dart';

/// Professional earnings dashboard with charts, ticker, and payout history
class ProEarningsPage extends ConsumerStatefulWidget {
  const ProEarningsPage({super.key});

  @override
  ConsumerState<ProEarningsPage> createState() => _ProEarningsPageState();
}

class _ProEarningsPageState extends ConsumerState<ProEarningsPage> {
  String _selectedPeriod = 'Today'; // Today, Weekly, Monthly, All-Time

  // Mock data - in production, this would come from API
  final double _todayEarnings = 247.50;
  final double _weeklyEarnings = 1245.00;
  final double _monthlyEarnings = 4890.00;
  final double _allTimeEarnings = 23450.00;
  final double _pendingEarnings = 125.00;
  final int _todayJobs = 3;
  final int _weeklyJobs = 12;
  final int _monthlyJobs = 47;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // TODO: Refresh earnings data
          },
          child: CustomScrollView(
            slivers: [
              // Earnings Ticker
              SliverToBoxAdapter(
                child: _buildEarningsTicker(),
              ),
              
              // Period Selector
              SliverToBoxAdapter(
                child: _buildPeriodSelector(),
              ),
              
              // Stats Cards
              SliverToBoxAdapter(
                child: _buildStatsCards(),
              ),
              
              // Chart
              SliverToBoxAdapter(
                child: _buildChart(),
              ),
              
              // Payout History
              SliverToBoxAdapter(
                child: _buildPayoutHistory(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsTicker() {
    double earnings;
    switch (_selectedPeriod) {
      case 'Today':
        earnings = _todayEarnings;
        break;
      case 'Weekly':
        earnings = _weeklyEarnings;
        break;
      case 'Monthly':
        earnings = _monthlyEarnings;
        break;
      default:
        earnings = _allTimeEarnings;
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppTokens.spacingS),
          Text(
            '\$${earnings.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTokens.spacingM),
          Row(
            children: [
              Icon(Icons.arrow_upward, color: AppColors.success, size: 16),
              const SizedBox(width: AppTokens.spacingS),
              Text(
                '↑ 15% from last period',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'Weekly', 'Monthly', 'All-Time'];
    
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(period),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedPeriod = period);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards() {
    int jobs;
    switch (_selectedPeriod) {
      case 'Today':
        jobs = _todayJobs;
        break;
      case 'Weekly':
        jobs = _weeklyJobs;
        break;
      case 'Monthly':
        jobs = _monthlyJobs;
        break;
      default:
        jobs = _monthlyJobs;
    }

    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Jobs',
              value: jobs.toString(),
              icon: Icons.work_outline,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppTokens.spacingM),
          Expanded(
            child: _StatCard(
              label: 'Avg / Job',
              value: '\$${(_selectedPeriod == 'Today' ? _todayEarnings / _todayJobs : _weeklyEarnings / _weeklyJobs).toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppTokens.spacingM),
          Expanded(
            child: _StatCard(
              label: 'Pending',
              value: '\$${_pendingEarnings.toStringAsFixed(2)}',
              icon: Icons.pending,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // Mock data for chart
    final chartData = [
      {'day': 'Mon', 'earnings': 180.0},
      {'day': 'Tue', 'earnings': 220.0},
      {'day': 'Wed', 'earnings': 195.0},
      {'day': 'Thu', 'earnings': 250.0},
      {'day': 'Fri', 'earnings': 280.0},
      {'day': 'Sat', 'earnings': 320.0},
      {'day': 'Sun', 'earnings': 0.0},
    ];

    final maxEarnings = chartData.map((d) => d['earnings'] as double).reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.all(AppTokens.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Earnings Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingL),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxEarnings * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[index]['day'] as String,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: chartData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['earnings'] as double,
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistory() {
    // Mock payout history
    final payouts = [
      {'date': DateTime.now().subtract(const Duration(days: 1)), 'amount': 125.00, 'status': 'completed'},
      {'date': DateTime.now().subtract(const Duration(days: 3)), 'amount': 247.50, 'status': 'completed'},
      {'date': DateTime.now().subtract(const Duration(days: 5)), 'amount': 189.00, 'status': 'completed'},
      {'date': DateTime.now().subtract(const Duration(days: 7)), 'amount': 312.00, 'status': 'pending'},
    ];

    return Card(
      margin: const EdgeInsets.all(AppTokens.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payout History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spacingM),
            ...payouts.map((payout) {
              final date = payout['date'] as DateTime;
              final amount = payout['amount'] as double;
              final status = payout['status'] as String;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spacingM),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM d, y').format(date),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            status == 'completed' ? 'Completed' : 'Pending',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: status == 'completed' ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppTokens.spacingM),
            OutlinedButton(
              onPressed: () {
                // TODO: View all payouts
              },
              child: const Text('View All Payouts'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppTokens.spacingS),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

