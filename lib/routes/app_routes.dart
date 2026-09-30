import 'package:flutter/material.dart';

import '../presentation/booking_flow/booking_flow.dart';
import '../presentation/booking_management/booking_management.dart';
import '../presentation/home_browse/home_browse.dart';
import '../presentation/provider_panel/provider_panel.dart';
import '../presentation/role_selection/role_selection.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/vendor_booking_management/vendor_booking_management.dart';
import '../presentation/vendor_detail_profile/vendor_detail_profile.dart';

class AppRoutes {
  static const String initial = '/';
  static const String roleSelection = '/role-selection';
  static const String home = '/home';
  static const String providerPanel = '/provider-panel';
  static const String vendorDashboard = '/vendor-dashboard';
  static const String vendorDetailProfile = '/vendor-detail-profile';
  static const String vendorBookingManagement = '/vendor-booking-management';
  static const String bookingFlow = '/booking-flow';
  static const String bookingManagement = '/booking-management';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    roleSelection: (context) => const RoleSelection(),
    home: (context) => const HomeBrowse(),
    providerPanel: (context) => const ProviderPanel(),
    vendorDashboard: (context) => const ProviderPanel(),
    vendorDetailProfile: (context) => const VendorDetailProfile(),
    vendorBookingManagement: (context) => const VendorBookingManagement(),
    bookingFlow: (context) => const BookingFlow(),
    bookingManagement: (context) => const BookingManagement(),
  };
}
