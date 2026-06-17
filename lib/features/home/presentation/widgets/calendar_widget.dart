import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_pallete.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDateSelected;

  const CalendarWidget({super.key, this.onDateSelected});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateWeekDays();
  }

  void _generateWeekDays() {
    final now = DateTime.now();
    // Get the start of the week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'MON';
      case 2:
        return 'TUE';
      case 3:
        return 'WED';
      case 4:
        return 'THU';
      case 5:
        return 'FRI';
      case 6:
        return 'SAT';
      case 7:
        return 'SUN';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Text(
            '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
            style: const TextStyle(
              color: AppPallete.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          // Week Days Row
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final day = _weekDays[index];
                final isSelected =
                    day.day == _selectedDate.day &&
                    day.month == _selectedDate.month;
                final isToday =
                    day.day == now.day &&
                    day.month == now.month &&
                    day.year == now.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                    });
                    widget.onDateSelected?.call(day);
                  },
                  child:
                      AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 55,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppPallete.primary
                                  : AppPallete.surface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: AppPallete.primary,
                                      width: 2,
                                    )
                                  : Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppPallete.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getDayName(day.weekday),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppPallete.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppPallete.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Event indicator dot
                                if (isToday)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : AppPallete.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          )
                          .animate(delay: Duration(milliseconds: index * 50))
                          .fadeIn()
                          .slideX(begin: 0.2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
