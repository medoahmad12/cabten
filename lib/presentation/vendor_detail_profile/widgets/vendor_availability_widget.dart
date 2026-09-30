import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/app_export.dart';

class VendorAvailabilityWidget extends StatefulWidget {
  final List<DateTime> availableDates;
  final List<DateTime> bookedDates;
  final Function(DateTime) onDateSelected;

  const VendorAvailabilityWidget({
    Key? key,
    required this.availableDates,
    required this.bookedDates,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<VendorAvailabilityWidget> createState() => _VendorAvailabilityWidgetState();
}

class _VendorAvailabilityWidgetState extends State<VendorAvailabilityWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("التوفر والحجز",
              style: AppTheme.lightTheme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          _buildLegend(),
          SizedBox(height: 2.h),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightTheme.dividerColor),
            ),
            child: TableCalendar<DateTime>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.saturday,
              locale: 'ar',
              availableGestures: AvailableGestures.horizontalSwipe,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTheme.lightTheme.textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
                leftChevronIcon:
                    const CustomIconWidget(iconName: 'chevron_left', color: AppTheme.primary, size: 20),
                rightChevronIcon:
                    const CustomIconWidget(iconName: 'chevron_right', color: AppTheme.primary, size: 20),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (_isDateAvailable(selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  widget.onDateSelected(selectedDay);
                }
              },
              onPageChanged: (f) => _focusedDay = f,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (_isDateBooked(day)) {
                    return _dayCell(day, AppTheme.error);
                  } else if (_isDateAvailable(day)) {
                    return _dayCell(day, AppTheme.success);
                  }
                  return null;
                },
                selectedBuilder: (context, day, focusedDay) => Container(
                  margin: EdgeInsets.all(1.w),
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${day.day}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          if (_selectedDay != null) ...[_buildSelectedDateInfo(), SizedBox(height: 2.h)],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDay != null && _isDateAvailable(_selectedDay!)
                  ? _confirmAndBook
                  : null,
              child: Text(_selectedDay != null
                  ? "احجز ليوم ${_formatDate(_selectedDay!)}"
                  : "اختر تاريخاً للحجز"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(DateTime day, Color color) => Container(
        margin: EdgeInsets.all(1.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text('${day.day}', style: TextStyle(color: color)),
        ),
      );

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightTheme.dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(AppTheme.success, "متاح", 'check_circle'),
          _legendItem(AppTheme.error, "محجوز", 'cancel'),
          _legendItem(AppTheme.primary, "مختار", 'radio_button_checked'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, String icon) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 16),
          SizedBox(width: 1.w),
          Text(label,
              style: AppTheme.lightTheme.textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildSelectedDateInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const CustomIconWidget(iconName: 'event', color: AppTheme.primary, size: 24),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("التاريخ المختار",
                    style: AppTheme.lightTheme.textTheme.labelMedium
                        ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                SizedBox(height: 0.5.h),
                Text(_formatDate(_selectedDay!),
                    style: AppTheme.lightTheme.textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDateAvailable(DateTime date) =>
      widget.availableDates.any((d) => isSameDay(d, date));
  bool _isDateBooked(DateTime date) =>
      widget.bookedDates.any((d) => isSameDay(d, date));

  String _formatDate(DateTime date) {
    const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    const weekdays = ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _confirmAndBook() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد الاختيار"),
        content: Text("هل تريد المتابعة للحجز ليوم ${_formatDate(_selectedDay!)}؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/booking-flow');
            },
            child: const Text("متابعة الحجز"),
          ),
        ],
      ),
    );
  }
}
