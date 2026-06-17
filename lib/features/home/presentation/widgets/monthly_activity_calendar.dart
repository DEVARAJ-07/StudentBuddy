import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/dashboard_service.dart';

class MonthlyActivityCalendar extends StatefulWidget {
  const MonthlyActivityCalendar({super.key});

  @override
  State<MonthlyActivityCalendar> createState() =>
      _MonthlyActivityCalendarState();
}

class _MonthlyActivityCalendarState extends State<MonthlyActivityCalendar> {
  final DashboardService _dashboardService = DashboardService();
  DateTime _currentMonth = DateTime.now();
  Set<int> _loginDays = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoginDates();
  }

  Future<void> _loadLoginDates() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _dashboardService.fetchLoginDatesForMonth(
        _currentMonth.year,
        _currentMonth.month,
      );
      if (mounted) {
        setState(() {
          _loginDays = sessions
              .map((s) {
                try {
                  final startTime = s['start_time'];
                  if (startTime == null) return null;
                  final date = DateTime.parse(startTime.toString());
                  return date.day;
                } catch (e) {
                  return null;
                }
              })
              .whereType<int>()
              .toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _loadLoginDates();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        blur: 15,
        opacity: 0.08,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with month and navigation
            _buildHeader(),
            const SizedBox(height: 16),
            // Calendar grid (dates only)
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppPallete.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _buildCalendarGrid(),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildHeader() {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPallete.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppPallete.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
              style: const TextStyle(
                color: AppPallete.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildNavButton(Icons.chevron_left_rounded, () => _changeMonth(-1)),
            const SizedBox(width: 8),
            _buildNavButton(Icons.chevron_right_rounded, () => _changeMonth(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppPallete.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = index + 1;
        final isLoginDay = _loginDays.contains(day);
        final isToday =
            _currentMonth.year == today.year &&
            _currentMonth.month == today.month &&
            day == today.day;

        return Container(
          decoration: BoxDecoration(
            color: isLoginDay
                ? AppPallete.success.withValues(alpha: 0.3)
                : AppPallete.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: AppPallete.primary, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isLoginDay
                    ? AppPallete.success
                    : AppPallete.textSecondary,
                fontWeight: isLoginDay || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }
}
