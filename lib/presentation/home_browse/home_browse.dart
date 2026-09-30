import 'package:flutter/material.dart';

import '../../core/app_export.dart';

class HomeBrowse extends StatefulWidget {
  const HomeBrowse({super.key});

  @override
  State<HomeBrowse> createState() => _HomeBrowseState();
}

class _HomeBrowseState extends State<HomeBrowse> {
  String _category = 'all';
  String _query = '';

  static const List<Map<String, String>> _allCategories = [
    {'id': 'all', 'name': 'الكل', 'icon': 'apps'},
    ...AppData.categories,
  ];

  void _openVendor(Map<String, dynamic> v) {
    Navigator.pushNamed(context, AppRoutes.vendorDetailProfile,
        arguments: v['id']);
  }

  void _book(Map<String, dynamic> v) {
    Navigator.pushNamed(context, AppRoutes.bookingFlow, arguments: v['id']);
  }

  Widget _categoryStrip() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _allCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = _allCategories[i];
          final selected = _category == c['id'];
          return GestureDetector(
            onTap: () => setState(() => _category = c['id']!),
            child: SizedBox(
              width: 74,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: selected ? AppTheme.primaryGradient : null,
                      color: selected ? null : AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: c['icon']!,
                        color: selected ? Colors.white : AppTheme.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c['name']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          selected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _vendorCard(Map<String, dynamic> v) {
    final tt = Theme.of(context).textTheme;
    final images = AppData.imagesOf(v);
    final price = (v['basePrice'] as num?) ?? 0;
    final rating = (v['rating'] as num?)?.toDouble() ?? 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openVendor(v),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppImage(
                  src: images.isEmpty ? null : images.first,
                  width: double.infinity,
                  height: 170,
                ),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppData.categoryName(v['category'] as String?),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (v['isVerified'] == true)
                  const PositionedDirectional(
                    top: 10,
                    end: 10,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.verified,
                          size: 20, color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(v['name'] as String? ?? '',
                            style: tt.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(Icons.star, size: 18, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: tt.labelLarge),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${v['city'] ?? ''} - ${v['address'] ?? ''}',
                          style: tt.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ابتداءً من ${AppData.formatNumber(price)} ل.س / ساعة',
                          style: tt.titleSmall
                              ?.copyWith(color: AppTheme.primary),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _book(v),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                        ),
                        child: const Text('احجز الآن'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/app_logo.png',
                  width: 32, height: 32),
            ),
            const SizedBox(width: 8),
            const Text('كابتن بارتي'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: AppData.instance,
        builder: (context, _) {
          final list =
              AppData.instance.search(category: _category, query: _query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  onChanged: (q) => setState(() => _query = q),
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن قاعة أو خدمة أو مدينة...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              _categoryStrip(),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('لا توجد نتائج مطابقة',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _vendorCard(list[i]),
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, AppRoutes.bookingManagement);
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية'),
          BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'حجوزاتي'),
        ],
      ),
    );
  }
}
