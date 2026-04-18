import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';

class PaymentScreen extends StatefulWidget {
  final Appointment appointment;
  const PaymentScreen({super.key, required this.appointment});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  static const _tag = 'PaymentScreen';

  static const _methods = [
    _PaymentMethod(id: 'esewa', label: 'eSewa', icon: Icons.account_balance_wallet_rounded, color: Color(0xFF4CAF50)),
    _PaymentMethod(id: 'khalti', label: 'Khalti', icon: Icons.wallet_rounded, color: Color(0xFF7C3AED)),
    _PaymentMethod(id: 'cash', label: 'Cash on Arrival', icon: Icons.payments_rounded, color: Color(0xFFF59E0B)),
  ];

  String _selectedMethod = 'esewa';
  _ScreenState _state = _ScreenState.selecting;
  Payment? _payment;
  String? _error;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    AppLogger.info(_tag, 'Processing $_selectedMethod payment');
    setState(() { _state = _ScreenState.processing; _error = null; });

    // Simulate network + gateway processing delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final payment = await ApiService.recordPayment(
        appointmentId: widget.appointment.id,
        paymentMethod: _selectedMethod,
      );
      setState(() { _payment = payment; _state = _ScreenState.success; });
    } on AppException catch (e) {
      setState(() { _error = e.message; _state = _ScreenState.selecting; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _state != _ScreenState.processing,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: primaryGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: Row(
                      children: [
                        if (_state != _ScreenState.processing)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment',
                                style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            Text('Secure mock checkout',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: switch (_state) {
                  _ScreenState.selecting => _SelectingView(
                      appointment: widget.appointment,
                      methods: _methods,
                      selectedMethod: _selectedMethod,
                      error: _error,
                      onMethodChanged: (m) => setState(() => _selectedMethod = m),
                      onPay: _pay,
                    ),
                  _ScreenState.processing => _ProcessingView(pulse: _pulseAnim),
                  _ScreenState.success => _SuccessView(
                      payment: _payment!,
                      appointment: widget.appointment,
                      onDone: () => Navigator.pop(context),
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ScreenState { selecting, processing, success }

// ── Data class for payment methods ────────────────────────────────────────────

class _PaymentMethod {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _PaymentMethod({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ── Method selection view ─────────────────────────────────────────────────────

class _SelectingView extends StatelessWidget {
  final Appointment appointment;
  final List<_PaymentMethod> methods;
  final String selectedMethod;
  final String? error;
  final void Function(String) onMethodChanged;
  final VoidCallback onPay;

  const _SelectingView({
    required this.appointment,
    required this.methods,
    required this.selectedMethod,
    required this.error,
    required this.onMethodChanged,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Order summary card
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Summary',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              _SummaryRow(
                label: 'Service',
                value: appointment.service.name,
                bold: false,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Date',
                value: appointment.formattedDate,
                bold: false,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Time',
                value: appointment.formattedTime,
                bold: false,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              _SummaryRow(
                label: 'Total',
                value: 'NPR ${appointment.service.price.toStringAsFixed(0)}',
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment method selection
        Text('Select Payment Method',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ...methods.map((m) => _MethodTile(
              method: m,
              selected: selectedMethod == m.id,
              onTap: () => onMethodChanged(m.id),
            )),

        if (error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(error!,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.error)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        GradientButton(
          label: 'Pay NPR ${appointment.service.price.toStringAsFixed(0)}',
          icon: Icons.lock_rounded,
          onPressed: onPay,
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 13, color: AppColors.textHint),
              const SizedBox(width: 5),
              Text('Prototype demo — no real charges',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, required this.bold});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: bold ? AppColors.primary : AppColors.textPrimary)),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? method.color.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? method.color : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: method.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, color: method.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(method.label,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? method.color : AppColors.textPrimary)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? method.color : AppColors.textHint,
                  width: 2,
                ),
                color: selected ? method.color : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Processing view ───────────────────────────────────────────────────────────

class _ProcessingView extends StatelessWidget {
  final Animation<double> pulse;
  const _ProcessingView({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: pulse,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 28),
            Text('Processing Payment…',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Please wait, do not close the app',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final Payment payment;
  final Appointment appointment;
  final VoidCallback onDone;

  const _SuccessView({
    required this.payment,
    required this.appointment,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Success icon
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 56, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          Text('Payment Successful!',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Your booking is confirmed',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Transaction details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Service', value: appointment.service.name),
                const SizedBox(height: 10),
                _DetailRow(label: 'Amount',
                    value: 'NPR ${payment.amount.toStringAsFixed(0)}'),
                const SizedBox(height: 10),
                _DetailRow(label: 'Method', value: payment.methodLabel),
                const SizedBox(height: 10),
                _DetailRow(label: 'Status', value: 'Completed',
                    valueColor: AppColors.success),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _DetailRow(
                  label: 'Transaction ID',
                  value: payment.transactionRef,
                  mono: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Done',
            icon: Icons.check_rounded,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: mono
              ? GoogleFonts.sourceCodePro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)
              : GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary),
        ),
      ],
    );
  }
}
