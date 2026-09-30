import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/booking_session.dart';
import './widgets/vendor_availability_widget.dart';
import './widgets/vendor_gallery_widget.dart';
import './widgets/vendor_header_widget.dart';
import './widgets/vendor_overview_widget.dart';
import './widgets/vendor_pricing_widget.dart';
import './widgets/vendor_reviews_widget.dart';
import './widgets/vendor_sticky_bottom_bar_widget.dart';

/// صفحة تفاصيل مقدم الخدمة.
/// تقرأ كل بياناتها (الاسم، الصور، الأسعار، أيام الحجز) من AppData،
/// فأي تعديل في لوحة مقدم الخدمة يظهر هنا مباشرة.
/// تم حذف أزرار التواصل (اتصال / رسالة / الاتجاهات / الموقع).
class VendorDetailProfile extends StatefulWidget {
  const VendorDetailProfile({Key? key}) : super(key: key);

  @override
  State<VendorDetailProfile> createState() => _VendorDetailProfileState();
}

class _VendorDetailProfileState extends State<VendorDetailProfile>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  bool _isFavorite = false;
  String? _vendorId;

  // تقييمات تجريبية (لا يوجد لها مصدر بيانات بعد)
  final List<Map<String, dynamic>> _reviewsData = [
    {
      "id": "review_001",
      "userName": "أحمد محمد",
      "userAvatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rating": 5,
      "date": "منذ أسبوع",
      "comment":
          "خدمة ممتازة وفريق عمل محترف ومتعاون. أنصح بها بشدة لحفلات الزفاف.",
      "helpfulCount": 12,
      "images": [],
    },
    {
      "id": "review_002",
      "userName": "فاطمة أحمد",
      "userAvatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rating": 4,
      "date": "منذ أسبوعين",
      "comment":
          "الخدمة جيدة، لكن الأسعار مرتفعة قليلاً. بشكل عام تجربة إيجابية.",
      "helpfulCount": 8,
      "images": [],
    },
    {
      "id": "review_003",
      "userName": "محمد علي",
      "userAvatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rating": 5,
      "date": "منذ شهر",
      "comment": "تنظيم رائع وأجواء مميزة. شكراً لكم على جعل حفلنا مميزاً.",
      "helpfulCount": 15,
      "images": [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vendorId != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? id;
    if (args is String) {
      id = args;
    } else if (args is Map) {
      id = args['vendorId'] as String?;
    }
    if (id == null || AppData.instance.vendorById(id) == null) {
      final list = AppData.instance.search();
      id = list.isEmpty ? null : list.first['id'] as String;
    }
    _vendorId = id;
    BookingSession.vendorId = id;
    BookingSession.date = null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 25.h && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 25.h && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  // ---------------------------------------------------------------------------
  // تحويل بيانات AppData إلى الشكل الذي تتوقعه الويدجت الحالية
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _buildVendorData(Map<String, dynamic> v) {
    final hours = (v['workingHours'] as String?) ?? '9:00 ص - 11:00 م';
    final desc = (v['description'] as String?)?.trim();
    return {
      "id": v['id'],
      "name": v['name'],
      "category": AppData.categoryName(v['category'] as String?),
      "rating": ((v['rating'] as num?) ?? 4.5).toDouble(),
      "reviewCount": ((v['reviewCount'] as num?) ?? 0).toInt(),
      "isVerified": v['isVerified'] == true,
      "description": (desc == null || desc.isEmpty) ? null : desc,
      "address": '${v['city'] ?? ''}، ${v['address'] ?? ''}',
      "images": AppData.imagesOf(v),
      "amenities": [
        for (final s in AppData.servicesOf(v))
          {"name": s, "icon": "check_circle"},
      ],
      "workingHours": {
        for (final d in [
          'sunday',
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday'
        ])
          d: hours,
      },
    };
  }

  List<Map<String, dynamic>> _buildPackages(Map<String, dynamic> v) {
    final base = ((v['basePrice'] as num?) ?? 0).toInt();
    final services = AppData.servicesOf(v);
    String f(int n) => AppData.formatNumber(n);
    return [
      {
        "id": "p1",
        "name": "باقة 4 ساعات",
        "price": f(base * 4),
        "description": "مناسبة للمناسبات الصغيرة والقصيرة",
        "features": ["مدة الخدمة 4 ساعات", ...services.take(2)],
      },
      {
        "id": "p2",
        "name": "باقة 8 ساعات",
        "price": f(base * 8),
        "originalPrice": f((base * 8 * 1.15).round()),
        "description": "الخيار الأنسب لمعظم المناسبات",
        "features": ["مدة الخدمة 8 ساعات", ...services],
      },
      {
        "id": "p3",
        "name": "باقة اليوم الكامل",
        "price": f(base * 12),
        "description": "خدمة متواصلة طوال اليوم مع أولوية في الحجز",
        "features": ["مدة الخدمة 12 ساعة", ...services, "أولوية في الحجز"],
      },
    ];
  }

  List<DateTime> _bookedDates(Map<String, dynamic> v) => [
        for (final k in AppData.bookedDatesOf(v))
          if (DateTime.tryParse(k) != null) DateTime.parse(k),
      ];

  List<DateTime> _availableDates(Map<String, dynamic> v) {
    final booked = AppData.bookedDatesOf(v).toSet();
    final now = DateTime.now();
    return [
      for (var i = 0; i <= 365; i++)
        if (!booked.contains(AppData.dateKey(now.add(Duration(days: i)))))
          now.add(Duration(days: i)),
    ];
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppData.instance,
      builder: (context, _) {
        final vendor =
            _vendorId == null ? null : AppData.instance.vendorById(_vendorId!);
        if (vendor == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('مقدم الخدمة غير متوفر')),
          );
        }

        final vendorData = _buildVendorData(vendor);
        final packages = _buildPackages(vendor);

        return Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: VendorHeaderWidget(
                      vendorData: vendorData,
                      onBackPressed: _onBackPressed,
                      onSharePressed: _onSharePressed,
                      onFavoritePressed: _onFavoritePressed,
                      isFavorite: _isFavorite,
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        tabs: const [
                          Tab(text: "نظرة عامة"),
                          Tab(text: "المعرض"),
                          Tab(text: "التقييمات"),
                          Tab(text: "الأسعار"),
                          Tab(text: "التوفر"),
                        ],
                      ),
                    ),
                  ),

                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.only(top: 2.h, bottom: 12.h),
                          child: VendorOverviewWidget(vendorData: vendorData),
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.only(top: 2.h, bottom: 12.h),
                          child: VendorGalleryWidget(
                            images:
                                (vendorData["images"] as List).cast<String>(),
                          ),
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.only(top: 2.h, bottom: 12.h),
                          child: VendorReviewsWidget(
                            reviews: _reviewsData,
                            averageRating: vendorData["rating"] as double,
                            totalReviews: vendorData["reviewCount"] as int,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.only(top: 2.h, bottom: 12.h),
                          child: VendorPricingWidget(
                            packages: packages,
                            onBookNowPressed: _onBookServicePressed,
                            onRequestQuotePressed: _onRequestQuotePressed,
                          ),
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.only(top: 2.h, bottom: 12.h),
                          child: VendorAvailabilityWidget(
                            availableDates: _availableDates(vendor),
                            bookedDates: _bookedDates(vendor),
                            onDateSelected: _onDateSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // شريط علوي شفاف يظهر عند التمرير
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _showAppBarTitle ? 12.h : 0,
                  decoration: BoxDecoration(
                    color: _showAppBarTitle
                        ? AppTheme.lightTheme.scaffoldBackgroundColor
                            .withValues(alpha: 0.95)
                        : Colors.transparent,
                    boxShadow: _showAppBarTitle
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: _showAppBarTitle
                      ? SafeArea(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _onBackPressed,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: CustomIconWidget(
                                        iconName: 'arrow_back',
                                        color: AppTheme.textPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    vendorData["name"] as String? ?? "",
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _onSharePressed,
                                  child: Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: AppTheme
                                          .lightTheme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: CustomIconWidget(
                                        iconName: 'share',
                                        color: AppTheme.textPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              // شريط الحجز السفلي
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VendorStickyBottomBarWidget(
                  onBookServicePressed: _onBookServicePressed,
                  onRequestQuotePressed: _onRequestQuotePressed,
                  startingPrice: packages.first["price"] as String?,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  void _onBackPressed() => Navigator.of(context).pop();

  void _onSharePressed() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: "تم نسخ رابط مقدم الخدمة",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onFavoritePressed() {
    HapticFeedback.lightImpact();
    setState(() => _isFavorite = !_isFavorite);
    Fluttertoast.showToast(
      msg: _isFavorite
          ? "تمت الإضافة إلى المفضلة"
          : "تمت الإزالة من المفضلة",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onBookServicePressed() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(
      context,
      '/booking-flow',
      arguments: {'vendorId': _vendorId, 'date': BookingSession.date},
    );
  }

  void _onRequestQuotePressed() {
    HapticFeedback.lightImpact();
    Fluttertoast.showToast(
      msg: "تم إرسال طلب عرض السعر بنجاح",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onDateSelected(DateTime selectedDate) {
    HapticFeedback.selectionClick();
    BookingSession.date = selectedDate;
    BookingSession.vendorId = _vendorId;
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.lightTheme.scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
