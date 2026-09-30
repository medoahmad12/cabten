import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ServiceDetailsStep extends StatefulWidget {
  final Map<String, dynamic> vendor;
  final Function(Map<String, dynamic>) onDataChanged;
  final Map<String, dynamic> formData;

  const ServiceDetailsStep({Key? key, required this.vendor, required this.onDataChanged, required this.formData}) : super(key: key);

  @override
  State<ServiceDetailsStep> createState() => _ServiceDetailsStepState();
}

class _ServiceDetailsStepState extends State<ServiceDetailsStep> {
  String? selectedService;
  int guestCount = 50;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _requirements = TextEditingController();
  final int maxLen = 500;

  @override
  void initState() {
    super.initState();
    selectedService = widget.formData['selectedService'];
    guestCount = widget.formData['guestCount'] ?? 50;
    _name.text = widget.formData['clientName'] ?? '';
    _phone.text = widget.formData['clientPhone'] ?? '';
    _requirements.text = widget.formData['specialRequirements'] ?? '';
  }

  void _update() {
    widget.onDataChanged({
      ...widget.formData,
      'selectedService': selectedService,
      'guestCount': guestCount,
      'clientName': _name.text,
      'clientPhone': _phone.text,
      'specialRequirements': _requirements.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = AppData.servicesOf(widget.vendor);
    final images = AppData.imagesOf(widget.vendor);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppImage(src: images.isEmpty ? null : images.first, width: 15.w, height: 15.w),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.vendor['name'] as String? ?? '', style: AppTheme.lightTheme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          const CustomIconWidget(iconName: 'star', color: AppTheme.warning, size: 16),
                          SizedBox(width: 1.w),
                          Text('${widget.vendor['rating'] ?? 4.5}', style: AppTheme.lightTheme.textTheme.bodySmall),
                          SizedBox(width: 2.w),
                          const CustomIconWidget(iconName: 'location_on', color: AppTheme.textSecondary, size: 14),
                          SizedBox(width: 1.w),
                          Expanded(child: Text('${widget.vendor['city'] ?? ''}', style: AppTheme.lightTheme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text('اختر الخدمة', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedService,
                hint: Text('اختر خدمة', style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.lightTheme.colorScheme.onSurfaceVariant)),
                isExpanded: true,
                icon: const CustomIconWidget(iconName: 'keyboard_arrow_down', color: AppTheme.textSecondary, size: 24),
                items: services.map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppTheme.lightTheme.textTheme.bodyMedium))).toList(),
                onChanged: (v) {
                  setState(() => selectedService = v);
                  _update();
                },
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text('بيانات التواصل', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'الاسم الكامل'),
            onChanged: (_) => _update(),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            onChanged: (_) => _update(),
          ),
          SizedBox(height: 3.h),
          Text('عدد الضيوف', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الضيوف', style: AppTheme.lightTheme.textTheme.bodyMedium),
                Row(
                  children: [
                    _stepper('remove', guestCount > 1, () {
                      if (guestCount > 1) {
                        setState(() => guestCount--);
                        _update();
                      }
                    }),
                    SizedBox(width: 4.w),
                    SizedBox(width: 15.w, child: Text('$guestCount', textAlign: TextAlign.center, style: AppTheme.lightTheme.textTheme.titleMedium)),
                    SizedBox(width: 4.w),
                    _stepper('add', guestCount < 1000, () {
                      if (guestCount < 1000) {
                        setState(() => guestCount++);
                        _update();
                      }
                    }),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text('متطلبات خاصة', style: AppTheme.lightTheme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _requirements,
              maxLines: 4,
              maxLength: maxLen,
              decoration: InputDecoration(hintText: 'اذكر أي متطلبات خاصة لحدثك...', border: InputBorder.none, contentPadding: EdgeInsets.all(4.w)),
              onChanged: (_) {
                setState(() {});
                _update();
              },
            ),
          ),
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

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _requirements.dispose();
    super.dispose();
  }
}
