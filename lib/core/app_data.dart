import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مخزن بيانات التطبيق (مقدمو الخدمة + طرق الدفع).
/// كل ما يُعدَّل من لوحة مقدم الخدمة يُحفظ هنا ويظهر فوراً للعميل.
/// حالياً يُحفظ على الجهاز (shared_preferences)، وعند ربط الخادم لاحقاً
/// يكفي استبدال load() و _save() بنداءات API.
class AppData extends ChangeNotifier {
  AppData._();
  static final AppData instance = AppData._();

  static const String _storageKey = 'captain_party_data_v1';

  /// فئات الخدمات: من القاعات حتى أصغر التفاصيل
  static const List<Map<String, String>> categories = [
    {'id': 'venues', 'name': 'قاعات أفراح', 'icon': 'celebration'},
    {'id': 'photography', 'name': 'تصوير', 'icon': 'photo_camera'},
    {'id': 'catering', 'name': 'ضيافة وطعام', 'icon': 'restaurant'},
    {'id': 'decor', 'name': 'ديكور وزهور', 'icon': 'local_florist'},
    {'id': 'music', 'name': 'فرق وموسيقى', 'icon': 'music_note'},
    {'id': 'beauty', 'name': 'تجميل وعرائس', 'icon': 'spa'},
    {'id': 'fashion', 'name': 'فساتين وبدلات', 'icon': 'checkroom'},
    {'id': 'sweets', 'name': 'حلويات وكيك', 'icon': 'cake'},
    {'id': 'cars', 'name': 'سيارات زفاف', 'icon': 'directions_car'},
    {'id': 'gifts', 'name': 'دعوات وهدايا', 'icon': 'card_giftcard'},
  ];

  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _bookings = [];

  List<Map<String, dynamic>> get vendors => List.unmodifiable(_vendors);
  List<Map<String, dynamic>> get paymentMethods =>
      List.unmodifiable(_paymentMethods);
  List<Map<String, dynamic>> get enabledPaymentMethods =>
      _paymentMethods.where((m) => m['enabled'] == true).toList();
  List<Map<String, dynamic>> get bookings => List.unmodifiable(_bookings);

  // ---------------------------------------------------------------------------
  // التحميل والحفظ
  // ---------------------------------------------------------------------------
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _vendors = (data['vendors'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _paymentMethods = (data['payments'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _bookings = ((data['bookings'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return;
      }
    } catch (_) {
      // بيانات تالفة: نرجع للبيانات الافتراضية
    }
    _vendors = _seedVendors();
    _paymentMethods = _seedPayments();
    _bookings = [];
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'vendors': _vendors,
          'payments': _paymentMethods,
          'bookings': _bookings,
        }),
      );
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    _vendors = _seedVendors();
    _paymentMethods = _seedPayments();
    _bookings = [];
    await _save();
  }

  // ---------------------------------------------------------------------------
  // مقدمو الخدمة
  // ---------------------------------------------------------------------------
  Map<String, dynamic>? vendorById(String id) {
    for (final v in _vendors) {
      if (v['id'] == id) return v;
    }
    return null;
  }

  List<Map<String, dynamic>> search({String category = 'all', String query = ''}) {
    final q = query.trim();
    return _vendors.where((v) {
      if (v['isActive'] == false) return false;
      if (category != 'all' && v['category'] != category) return false;
      if (q.isEmpty) return true;
      final hay = '${v['name']} ${v['city']} ${v['address']} '
          '${categoryName(v['category'] as String?)} '
          '${servicesOf(v).join(' ')}';
      return hay.contains(q);
    }).toList();
  }

  void upsertVendor(Map<String, dynamic> vendor) {
    final copy = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(vendor)) as Map<String, dynamic>);
    final i = _vendors.indexWhere((v) => v['id'] == copy['id']);
    if (i == -1) {
      _vendors.add(copy);
    } else {
      _vendors[i] = copy;
    }
    _save();
  }

  void deleteVendor(String id) {
    _vendors.removeWhere((v) => v['id'] == id);
    _save();
  }

  void setVendorActive(String id, bool active) {
    final v = vendorById(id);
    if (v == null) return;
    v['isActive'] = active;
    _save();
  }

  bool isBooked(String vendorId, DateTime day) {
    final v = vendorById(vendorId);
    if (v == null) return false;
    return bookedDatesOf(v).contains(dateKey(day));
  }

  /// يضيف يوم حجز (مثلاً عند تأكيد حجز جديد من العميل)
  void markBooked(String vendorId, DateTime day) {
    final v = vendorById(vendorId);
    if (v == null) return;
    final set = bookedDatesOf(v).toSet()..add(dateKey(day));
    v['bookedDates'] = set.toList()..sort();
    _save();
  }

  // ---------------------------------------------------------------------------
  // الحجوزات (تربط طلب العميل بلوحة مقدم الخدمة)
  // ---------------------------------------------------------------------------
  /// ينشئ حجزاً جديداً بحالة "قيد المراجعة" ويحجز التاريخ عند مقدم الخدمة.
  String createBooking({
    required String vendorId,
    required String clientName,
    required String clientPhone,
    required String service,
    required DateTime eventDate,
    required int guestCount,
    required int durationHours,
    required double totalAmount,
    required String paymentMethodId,
    String specialRequirements = '',
  }) {
    final id = 'booking_${DateTime.now().millisecondsSinceEpoch}';
    _bookings.insert(0, {
      'id': id,
      'vendorId': vendorId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'service': service,
      'eventDate': dateKey(eventDate),
      'guestCount': guestCount,
      'durationHours': durationHours,
      'totalAmount': totalAmount,
      'paymentMethodId': paymentMethodId,
      'specialRequirements': specialRequirements,
      'status': 'pending', // pending | confirmed | completed | cancelled
      'createdAt': DateTime.now().toIso8601String(),
    });
    markBooked(vendorId, eventDate);
    _save();
    return id;
  }

  void updateBookingStatus(String bookingId, String status) {
    final i = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (i == -1) return;
    _bookings[i] = {..._bookings[i], 'status': status};
    _save();
  }

  List<Map<String, dynamic>> bookingsForVendor(String vendorId) =>
      _bookings.where((b) => b['vendorId'] == vendorId).toList();

  // ---------------------------------------------------------------------------
  // طرق الدفع
  // ---------------------------------------------------------------------------
  void updatePaymentMethod(String id, Map<String, dynamic> changes) {
    final i = _paymentMethods.indexWhere((m) => m['id'] == id);
    if (i == -1) return;
    _paymentMethods[i] = {..._paymentMethods[i], ...changes};
    _save();
  }

  // ---------------------------------------------------------------------------
  // مساعدات
  // ---------------------------------------------------------------------------
  static String newId() => 'vendor_${DateTime.now().millisecondsSinceEpoch}';

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<String> imagesOf(Map<String, dynamic> v) =>
      List<String>.from((v['images'] as List?) ?? const []);
  static List<String> servicesOf(Map<String, dynamic> v) =>
      List<String>.from((v['services'] as List?) ?? const []);
  static List<String> bookedDatesOf(Map<String, dynamic> v) =>
      List<String>.from((v['bookedDates'] as List?) ?? const []);

  static String categoryName(String? id) {
    for (final c in categories) {
      if (c['id'] == id) return c['name']!;
    }
    return 'أخرى';
  }

  static String formatNumber(num n) {
    final s = n.round().toString();
    return s.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  /// يحوّل الأرقام العربية (٠١٢٣) إلى لاتينية لتقبلها int.tryParse
  static String toLatinDigits(String s) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var out = s;
    for (var i = 0; i < arabic.length; i++) {
      out = out.replaceAll(arabic[i], i.toString());
    }
    return out.replaceAll(',', '').replaceAll('،', '').trim();
  }

  // ---------------------------------------------------------------------------
  // البيانات الافتراضية (يمكن تعديلها كلها من لوحة مقدم الخدمة)
  // ---------------------------------------------------------------------------
  static String _u(String id) =>
      'https://images.unsplash.com/$id?fm=jpg&q=60&w=1000';

  static List<String> _daysFromNow(List<int> days) => days
      .map((d) => dateKey(DateTime.now().add(Duration(days: d))))
      .toList();

  static List<Map<String, dynamic>> _seedVendors() {
    final u1 = _u('photo-1519167758481-83f550bb49b3');
    final u2 = _u('photo-1464366400600-7168b8af9bc3');
    final u3 = _u('photo-1511795409834-ef04bbd61622');
    final u4 = _u('photo-1465495976277-4387d4b0e4a6');
    final u5 = _u('photo-1478146896981-b80fe463b330');
    final u6 = _u('photo-1507003211169-0a1dd7228f2d');

    Map<String, dynamic> v({
      required String id,
      required String name,
      required String category,
      required String city,
      required String address,
      required String description,
      required int price,
      required List<String> images,
      required List<String> services,
      required List<int> booked,
      double rating = 4.8,
      int reviews = 120,
    }) =>
        {
          'id': id,
          'name': name,
          'category': category,
          'city': city,
          'address': address,
          'phone': '',
          'description': description,
          'basePrice': price,
          'workingHours': '9:00 ص - 11:00 م',
          'images': images,
          'services': services,
          'bookedDates': _daysFromNow(booked),
          'rating': rating,
          'reviewCount': reviews,
          'isVerified': true,
          'isActive': true,
        };

    return [
      v(
        id: 'vendor_001',
        name: 'قاعة الأحلام الذهبية',
        category: 'venues',
        city: 'دمشق',
        address: 'شارع بغداد',
        description:
            'من أفخم قاعات الأفراح في دمشق بتصميم أنيق وعصري، تتسع لـ 500 ضيف وتوفر كل الخدمات اللازمة لحفل لا يُنسى.',
        price: 150000,
        images: [u1, u2, u3],
        services: ['حفل زفاف', 'خطوبة', 'عيد ميلاد', 'مناسبات شركات'],
        booked: [3, 10, 15, 22],
      ),
      v(
        id: 'vendor_002',
        name: 'قاعة الياسمين',
        category: 'venues',
        city: 'دمشق',
        address: 'المالكي',
        description: 'قاعة راقية بإطلالة جميلة وحديقة خارجية مناسبة لحفلات النهار والمساء.',
        price: 120000,
        images: [u4, u5],
        services: ['حفل زفاف', 'خطوبة', 'حفل تخرج'],
        booked: [5, 12],
        rating: 4.6,
        reviews: 89,
      ),
      v(
        id: 'vendor_003',
        name: 'استوديو النور للتصوير',
        category: 'photography',
        city: 'دمشق',
        address: 'المزة',
        description: 'تصوير فوتوغرافي وسينمائي احترافي للأفراح والمناسبات مع خدمة الدرون.',
        price: 60000,
        images: [u6, u3],
        services: ['تصوير فوتوغرافي', 'تصوير فيديو', 'تصوير جوي', 'جلسة ما قبل الزفاف'],
        booked: [4, 9],
        rating: 4.9,
        reviews: 210,
      ),
      v(
        id: 'vendor_004',
        name: 'مطعم الشام الأصيل للضيافة',
        category: 'catering',
        city: 'دمشق',
        address: 'الصالحية',
        description: 'بوفيهات ومقبلات وحلويات شرقية وغربية لجميع أنواع المناسبات.',
        price: 200000,
        images: [u5, u2],
        services: ['بوفيه مفتوح', 'مقبلات', 'قهوة وضيافة'],
        booked: [7, 14],
        rating: 4.7,
        reviews: 143,
      ),
      v(
        id: 'vendor_005',
        name: 'فرقة الأنغام الموسيقية',
        category: 'music',
        city: 'حلب',
        address: 'الفرقان',
        description: 'فرقة موسيقية ودي جي وزفة عروس بأجواء تراثية وعصرية.',
        price: 90000,
        images: [u3, u1],
        services: ['فرقة حية', 'دي جي', 'زفة عروس'],
        booked: [6],
        rating: 4.5,
        reviews: 64,
      ),
      v(
        id: 'vendor_006',
        name: 'لمسات للديكور والزهور',
        category: 'decor',
        city: 'اللاذقية',
        address: 'الزراعة',
        description: 'تنسيق ورود وكوشات وديكورات مخصصة لكل مناسبة.',
        price: 80000,
        images: [u2, u4],
        services: ['كوشة', 'تنسيق ورود', 'إضاءة'],
        booked: [8, 20],
        rating: 4.8,
        reviews: 97,
      ),
      v(
        id: 'vendor_007',
        name: 'بيت العروس للتجميل',
        category: 'beauty',
        city: 'دمشق',
        address: 'أبو رمانة',
        description: 'مكياج وتسريحات ورعاية بشرة للعروس والمدعوات.',
        price: 50000,
        images: [u6, u5],
        services: ['مكياج عروس', 'تسريحة', 'باقة العناية'],
        booked: [11],
        rating: 4.9,
        reviews: 178,
      ),
      v(
        id: 'vendor_008',
        name: 'حلويات السلطان',
        category: 'sweets',
        city: 'حمص',
        address: 'الحمراء',
        description: 'كيك مناسبات وتورتات مخصصة وحلويات عربية فاخرة.',
        price: 40000,
        images: [u4, u3],
        services: ['تورتة زفاف', 'كيك مناسبات', 'حلويات عربية'],
        booked: [13],
        rating: 4.7,
        reviews: 76,
      ),
    ];
  }

  static List<Map<String, dynamic>> _seedPayments() => [
        {
          'id': 'mtn_cash',
          'name': 'MTN كاش',
          'icon': 'account_balance_wallet',
          'fee': 2.5,
          'description': 'الدفع عبر محفظة MTN كاش',
          'enabled': true,
          'account': '',
        },
        {
          'id': 'syriatel_cash',
          'name': 'سيرياتيل كاش',
          'icon': 'account_balance_wallet',
          'fee': 2.0,
          'description': 'الدفع عبر محفظة سيرياتيل كاش',
          'enabled': true,
          'account': '',
        },
        {
          'id': 'sham_cash',
          'name': 'شام كاش',
          'icon': 'account_balance_wallet',
          'fee': 1.5,
          'description': 'الدفع عبر محفظة شام كاش',
          'enabled': true,
          'account': '',
        },
        {
          'id': 'bank_transfer',
          'name': 'دفع بنكي',
          'icon': 'account_balance',
          'fee': 0.0,
          'description': 'تحويل إلى الحساب البنكي',
          'enabled': true,
          'account': '',
        },
        {
          'id': 'cash_delivery',
          'name': 'الدفع عند التسليم',
          'icon': 'local_atm',
          'fee': 0.0,
          'description': 'ادفع نقداً عند تقديم الخدمة',
          'enabled': true,
          'account': '',
        },
      ];
}
