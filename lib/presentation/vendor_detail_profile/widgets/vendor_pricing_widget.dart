import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VendorPricingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> packages;
  final VoidCallback onBookNowPressed;
  final VoidCallback onRequestQuotePressed;

  const VendorPricingWidget({
    Key? key,
    required this.packages,
    required this.onBookNowPressed,
    required this.onRequestQuotePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("الباقات والأسعار", style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: packages.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) => _buildPackageCard(packages[index], index == 1),
          ),
          SizedBox(height: 3.h),
          _buildPricingNote(),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package, bool isPopular) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? AppTheme.primary : AppTheme.lightTheme.dividerColor, width: isPopular ? 2 : 1),
        boxShadow: isPopular ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 1.h),
              decoration: const BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
              child: Text("الأكثر طلباً", textAlign: TextAlign.center,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(package["name"] as String? ?? "باقة", style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (package["originalPrice"] != null)
                          Text("${package["originalPrice"]} ل.س",
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary, decoration: TextDecoration.lineThrough)),
                        Text("${package["price"] ?? 0} ل.س",
                            style: AppTheme.getDataTextStyle(isLight: true, fontSize: 18, fontWeight: FontWeight.bold).copyWith(color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
                if (package["description"] != null) ...[
                  SizedBox(height: 2.h),
                  Text(package["description"] as String, style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary, height: 1.4)),
                ],
                if (package["features"] != null && (package["features"] as List).isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Column(
                    children: (package["features"] as List).map((feature) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        child: Row(children: [
                          const CustomIconWidget(iconName: 'check_circle', color: AppTheme.success, size: 16),
                          SizedBox(width: 2.w),
                          Expanded(child: Text(feature as String, style: AppTheme.lightTheme.textTheme.bodyMedium)),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: onRequestQuotePressed, child: const Text("طلب عرض سعر"))),
                    SizedBox(width: 3.w),
                    Expanded(child: ElevatedButton(onPressed: onBookNowPressed, child: const Text("احجز الآن"))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingNote() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const CustomIconWidget(iconName: 'info', color: AppTheme.warning, size: 20),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ملاحظة مهمة", style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                SizedBox(height: 0.5.h),
                Text("الأسعار تقديرية وقد تختلف حسب تفاصيل الحدث. يتطلب دفع عربون لتأكيد الحجز.",
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(color: AppTheme.warning, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
