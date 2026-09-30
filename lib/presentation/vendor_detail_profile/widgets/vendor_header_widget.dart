import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VendorHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> vendorData;
  final VoidCallback onBackPressed;
  final VoidCallback onSharePressed;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  const VendorHeaderWidget({
    Key? key,
    required this.vendorData,
    required this.onBackPressed,
    required this.onSharePressed,
    required this.onFavoritePressed,
    required this.isFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final images = (vendorData["images"] as List?) ?? const [];
    return SizedBox(
      height: 35.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppImage(
              src: images.isEmpty ? null : images.first as String,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 6.h,
            right: 4.w,
            left: 4.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onBackPressed,
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                    child: const Center(child: CustomIconWidget(iconName: 'arrow_forward', color: Colors.white, size: 20)),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onSharePressed,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: CustomIconWidget(iconName: 'share', color: Colors.white, size: 20)),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    GestureDetector(
                      onTap: onFavoritePressed,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: isFavorite ? 'favorite' : 'favorite_border',
                            color: isFavorite ? AppTheme.error : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 2.h,
            right: 4.w,
            left: 4.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vendorData["name"] as String? ?? "اسم مقدم الخدمة",
                        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (vendorData["isVerified"] == true) ...[
                      SizedBox(width: 2.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CustomIconWidget(iconName: 'verified', color: Colors.white, size: 12),
                            SizedBox(width: 1.w),
                            Text("موثق", style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    const CustomIconWidget(iconName: 'star', color: AppTheme.warning, size: 16),
                    SizedBox(width: 1.w),
                    Text("${vendorData["rating"] ?? 4.5}",
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    SizedBox(width: 1.w),
                    Text("(${vendorData["reviewCount"] ?? 0} تقييم)",
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text(vendorData["category"] as String? ?? "",
                          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
