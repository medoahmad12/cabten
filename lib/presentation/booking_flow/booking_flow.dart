import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/booking_session.dart';
import './widgets/booking_summary_sheet.dart';
import './widgets/confirmation_step.dart';
import './widgets/date_time_step.dart';
import './widgets/payment_step.dart';
import './widgets/service_details_step.dart';
import './widgets/step_indicator.dart';

/// تدفق الحجز الكامل: تفاصيل الخدمة ← التاريخ والوقت ← الدفع ← التأكيد.
/// يقرأ مقدم الخدمة الفعلي من AppData بحسب المعرّف الممرَّر في arguments،
/// ويربط الدفع بطرق الدفع المُفعَّلة من لوحة مقدم الخدمة.
class BookingFlow extends StatefulWidget {
  const BookingFlow({Key? key}) : super(key: key);

  @override
  State<BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends State<BookingFlow> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  String? _vendorId;

  final List<String> stepTitles = ['الخدمة', 'التاريخ والوقت', 'الدفع', 'التأكيد'];

  Map<String, dynamic> formData = {
    'selectedService': null,
    'guestCount': 50,
    'specialRequirements': '',
    'selectedDate': null,
    'selectedTimeSlot': null,
    'selectedDuration': 4,
    'selectedPaymentMethod': null,
    'clientName': '',
    'clientPhone': '',
  };

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? id;
    DateTime? date;
    if (args is String) {
      id = args;
    } else if (args is Map) {
      id = args['vendorId'] as String?;
      date = args['date'] as DateTime?;
    }
    id ??= BookingSession.vendorId;
    date ??= BookingSession.date;
    if (id == null || AppData.instance.vendorById(id) == null) {
      final list = AppData.instance.search();
      id = list.isEmpty ? null : list.first['id'] as String;
    }
    _vendorId = id;
    if (date != null) formData['selectedDate'] = date;
  }

  Map<String, dynamic>? get _vendor =>
      _vendorId == null ? null : AppData.instance.vendorById(_vendorId!);

  bool get canContinue {
    switch (currentStep) {
      case 0:
        return formData['selectedService'] != null;
      case 1:
        return formData['selectedDate'] != null && formData['selectedTimeSlot'] != null;
      case 2:
        return formData['selectedPaymentMethod'] != null;
      case 3:
        return true;
      default:
        return false;
    }
  }

  double get totalAmount {
    final v = _vendor;
    if (v == null) return 0;
    final basePrice = ((v['basePrice'] as num?) ?? 0).toInt();
    final duration = (formData['selectedDuration'] as int?) ?? 4;
    final guestCount = (formData['guestCount'] as int?) ?? 50;
    double total = basePrice * duration.toDouble();
    if (guestCount > 100) total += (guestCount - 100) * 500;
    return total;
  }

  void _updateFormData(Map<String, dynamic> newData) => setState(() => formData = newData);

  void _nextStep() {
    if (canContinue && currentStep < stepTitles.length - 1) {
      setState(() => currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _showBookingSummary() {
    final v = _vendor;
    if (v == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingSummarySheet(formData: formData, vendor: v, totalAmount: totalAmount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _vendor;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الحجز')),
        body: const Center(child: Text('لا يوجد مقدم خدمة متاح للحجز حالياً')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('احجز الخدمة'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(2.w),
            decoration: BoxDecoration(color: AppTheme.lightTheme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
            child: const CustomIconWidget(iconName: 'arrow_forward', color: AppTheme.textPrimary, size: 20),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _showBookingSummary,
            child: Container(
              margin: EdgeInsets.only(left: 4.w),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(color: AppTheme.lightTheme.colorScheme.surface, borderRadius: BorderRadius.circular(8)),
              child: const CustomIconWidget(iconName: 'receipt_long', color: AppTheme.primary, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          StepIndicator(currentStep: currentStep, totalSteps: stepTitles.length, stepTitles: stepTitles),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ServiceDetailsStep(vendor: v, onDataChanged: _updateFormData, formData: formData),
                DateTimeStep(vendor: v, onDataChanged: _updateFormData, formData: formData),
                PaymentStep(onDataChanged: _updateFormData, formData: formData, totalAmount: totalAmount),
                ConfirmationStep(formData: formData, vendor: v, totalAmount: totalAmount),
              ],
            ),
          ),
          if (currentStep < 3)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [BoxShadow(color: AppTheme.shadowLight, blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 2.h)),
                          child: const Text('السابق'),
                        ),
                      ),
                    if (currentStep > 0) SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canContinue ? _nextStep : null,
                        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 2.h)),
                        child: Text(currentStep == 2 ? 'مراجعة الحجز' : 'متابعة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
