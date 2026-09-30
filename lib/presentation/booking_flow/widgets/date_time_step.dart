import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/app_export.dart';

class DateTimeStep extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic> formData;

  const DateTimeStep({Key? key, required this.vendor, required this.onDataChanged, required this.formData}) : super(key: key);

  @override
  State<DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends State<DateTimeStep> {
  DateTime? selectedDate;
  String? selectedTimeSlot;
  int selectedDuration = 4;

  final List<String> timeSlots = [
    '09:00','09:30','10:00','10:30','11:00','11:30','12:00','12:30','13:00','13:30',
    '14:00','14:30','15:00','15:30','16:00','16:30','17:00','17:30','18:00','18:30',
    '19:00','19:30','20:00','20:30','21:00','21:30','22:00','22:30',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.formData['selectedDate'];
    selectedTimeSlot = widget.formData['selectedTimeSlot'];
    selectedDuration = widget.formData['selectedDuration'] ?? 4;
  }

  void _update() {
    widget.onDataChanged({
      ...widget.formData,
      'selectedDate': selectedDate,
      'selectedTimeSlot': selectedTimeSlot,
      'selectedDuration': selectedDuration,
    });
  }

  bool _isDateBooked(DateTime date) {
    final booked = AppData.bookedDatesOf(widget.vendor);
    return booked.contains(AppData.dateKey(date));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اختر التاريخ', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: TableCalendar<DateTime>(
              locale: 'ar',
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: selectedDate ?? DateTime.now(),
              startingDayOfWeek: StartingDayOfWeek.saturday,
              selectedDayPredicate: (day) => selectedDate != null && isSameDay(selectedDate!, day),
              enabledDayPredicate: (day) => day.isAfter(DateTime.now().subtract(const Duration(days: 1))) && !_isDateBooked(day),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTheme.lightTheme.textTheme.titleMedium!,
                leftChevronIcon: const CustomIconWidget(iconName: 'chevron_left', color: AppTheme.primary, size: 24),
                rightChevronIcon: const CustomIconWidget(iconName: 'chevron_right', color: AppTheme.primary, size: 24),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
                disabledDecoration: BoxDecoration(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1), shape: BoxShape.circle),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!_isDateBooked(selectedDay)) {
                  setState(() {
                    selectedDate = selectedDay;
                    selectedTimeSlot = null;
                  });
                  _update();
                }
              },
            ),
          ),
          if (selectedDate != null) ...[
            SizedBox(height: 3.h),
            Text('اختر الوقت', style: AppTheme.lightTheme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 2.w, mainAxisSpacing: 1.h, childAspectRatio: 2.5),
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  final slot = timeSlots[index];
                  final isSelected = selectedTimeSlot == slot;
                  return GestureDetector(
                    onTap: () {
                      setState(() => selectedTimeSlot = slot);
                      _update();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.lightTheme.colorScheme.surface,
                        border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(slot,
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: isSelected ? Colors.white : AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 3.h),
            Text('مدة الحدث', style: AppTheme.lightTheme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('عدد الساعات', style: AppTheme.lightTheme.textTheme.bodyMedium),
                  Row(
                    children: [
                      _stepper('remove', selectedDuration > 1, () {
                        if (selectedDuration > 1) {
                          setState(() => selectedDuration--);
                          _update();
                        }
                      }),
                      SizedBox(width: 4.w),
                      SizedBox(width: 15.w, child: Text('$selectedDuration', textAlign: TextAlign.center, style: AppTheme.lightTheme.textTheme.titleMedium)),
                      SizedBox(width: 4.w),
                      _stepper('add', selectedDuration < 12, () {
                        if (selectedDuration < 12) {
                          setState(() => selectedDuration++);
                          _update();
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _stepper(String icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.primary : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: CustomIconWidget(iconName: icon, color: enabled ? Colors.white : AppTheme.textSecondary, size: 16),
      ),
    );
  }
}
