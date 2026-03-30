import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/attendance/application/attendance_notifier.dart';
import 'package:sheetstorm/features/attendance/presentation/widgets/attendance_chart.dart';
import 'package:sheetstorm/features/attendance/presentation/widgets/attendance_stat_card.dart';
import 'package:sheetstorm/features/attendance/presentation/widgets/export_button.dart';
import 'package:sheetstorm/features/attendance/presentation/widgets/register_breakdown.dart';

class AttendanceDashboardScreen extends ConsumerStatefulWidget {
  const AttendanceDashboardScreen({super.key, required this.bandId});

  final String bandId;

  @override
  ConsumerState<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState
    extends ConsumerState<AttendanceDashboardScreen> {
  int _selectedTab = 0;
  String? _selectedEventType;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(attendanceProvider(widget.bandId));
    final dashboardState = asyncState.value;
    final notifier =
        ref.read(attendanceProvider(widget.bandId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheitsstatistik'),
        actions: [
          ExportButton(
            onExport: (format) async {
              final result = await notifier.exportData(format);
              if (result != null && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export wird vorbereitet...'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: CustomScrollView(
          slivers: [
            // Date Range Picker
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildDateRangePicker(context, dashboardState, notifier),
              ),
            ),

            // Event Type Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _buildEventTypeFilter(),
              ),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildTabBar(),
              ),
            ),

            // Content
            if (asyncState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (asyncState.hasError)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    asyncState.error?.toString() ?? 'Unbekannter Fehler',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else if (dashboardState != null)
              _buildTabContent(dashboardState),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker(
    BuildContext context,
    AttendanceDashboardState? state,
    AttendanceNotifier notifier,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.date_range),
        title: Text(
          'Zeitraum: ${_formatDate(state?.startDate)} - ${_formatDate(state?.endDate)}',
          style: const TextStyle(fontSize: AppTypography.fontSizeSm),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showDateRangePicker(context, state, notifier),
      ),
    );
  }

  Widget _buildEventTypeFilter() {
    final eventTypes = ['Alle', 'Proben', 'Konzerte', 'Marschmusik'];

    return Wrap(
      spacing: AppSpacing.sm,
      children: eventTypes.map((type) {
        final isSelected = _selectedEventType == type ||
            (_selectedEventType == null && type == 'Alle');
        return FilterChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedEventType = selected && type != 'Alle' ? type : null;
            });
            ref
                .read(attendanceProvider(widget.bandId).notifier)
                .setEventType(_selectedEventType);
          },
        );
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Musiker', 'Register', 'Trends'];

    return SegmentedButton<int>(
      segments: List.generate(
        tabs.length,
        (index) => ButtonSegment(
          value: index,
          label: Text(tabs[index]),
        ),
      ),
      selected: {_selectedTab},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _selectedTab = newSelection.first;
        });
      },
    );
  }

  Widget _buildTabContent(AttendanceDashboardState state) {
    switch (_selectedTab) {
      case 0:
        return _buildMemberTab(state);
      case 1:
        return _buildRegisterTab(state);
      case 2:
        return _buildTrendsTab(state);
      default:
        return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
  }

  Widget _buildMemberTab(AttendanceDashboardState state) {
    if (state.stats == null) {
      return const SliverFillRemaining(
        child: Center(child: Text('Keine Daten verfügbar')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          AttendanceStatCard(
            title: 'Gesamtanwesenheit',
            percentage: state.stats!.overallPercentage,
            subtitle:
                '${state.stats!.totalAttendances} Zusagen / ${state.stats!.totalAbsences} Absagen',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMemberTable(state.stats!.memberStats,
              totalEvents: state.stats!.totalEvents),
        ]),
      ),
    );
  }

  Widget _buildRegisterTab(AttendanceDashboardState state) {
    if (state.stats == null) {
      return const SliverFillRemaining(
        child: Center(child: Text('Keine Daten verfügbar')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverToBoxAdapter(
        child: RegisterBreakdown(registers: state.stats!.registerStats),
      ),
    );
  }

  Widget _buildTrendsTab(AttendanceDashboardState state) {
    if (state.trend == null) {
      return const SliverFillRemaining(
        child: Center(child: Text('Keine Daten verfügbar')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverToBoxAdapter(
        child: AttendanceChart(trend: state.trend!),
      ),
    );
  }

  Widget _buildMemberTable(List memberStats, {required int totalEvents}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anwesenheit pro Musiker',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Text('Name',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Text('Teil',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Text('Abs',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Text('Quote',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...memberStats.map((member) {
                  final color = _getPercentageColor(member.percentage);
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text(member.name),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text('${member.attendances}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text('${member.absences}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            Text(
                              '${member.percentage.toStringAsFixed(0)}%',
                              style: TextStyle(color: color),
                            ),
                            const SizedBox(width: 4),
                            Icon(_getPercentageIcon(member.percentage),
                                size: 16, color: color),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'ℹ️ Basis: $totalEvents Termine im Zeitraum',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage > 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getPercentageIcon(double percentage) {
    if (percentage > 80) return Icons.check_circle;
    if (percentage >= 60) return Icons.warning;
    return Icons.cancel;
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    AttendanceDashboardState? state,
    AttendanceNotifier notifier,
  ) async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state?.startDate ?? DateTime.now(),
        end: state?.endDate ?? DateTime.now(),
      ),
    );

    if (result != null) {
      await notifier.setDateRange(result.start, result.end);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}.${date.month}.${date.year}';
  }
}
