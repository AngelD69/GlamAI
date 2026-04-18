import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  final int userId;
  const AppointmentsScreen({super.key, required this.userId});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _tag = 'AppointmentsScreen';

  List<Appointment> _appointments = [];
  Set<int> _reviewedAppointmentIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    AppLogger.info(_tag, 'Loading appointments');
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiService.getMyAppointments(),
        ApiService.getMyFeedback(),
      ]);
      final appointments = results[0] as List<Appointment>;
      final feedbacks = results[1] as List;
      setState(() {
        _appointments = appointments;
        _reviewedAppointmentIds = feedbacks.map((f) => f.appointmentId as int).toSet();
        _loading = false;
      });
    } on AuthException {
      _redirectToLogin();
    } on NetworkException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  Future<void> _openReview(Appointment appt) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FeedbackScreen(appointment: appt)),
    );
    if (submitted == true) _loadAppointments();
  }

  Future<void> _cancel(Appointment appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Appointment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17)),
        content: Text(
          'Cancel ${appt.service.name} on ${appt.formattedDate} at ${appt.formattedTime}?',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep it',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ApiService.cancelAppointment(appt.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled')),
      );
      _loadAppointments();
    } on AuthException {
      _redirectToLogin();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Bookings',
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('Manage your appointments',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                      GestureDetector(
                        onTap: _loadAppointments,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      GradientButton(
                          label: 'Retry',
                          onPressed: _loadAppointments,
                          icon: Icons.refresh_rounded),
                    ],
                  ),
                ),
              ),
            )
          else if (_appointments.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_month_rounded,
                          size: 52, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text('No appointments yet',
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Book a service to get started',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _AppointmentCard(
                    appt: _appointments[i],
                    onCancel: _cancel,
                    onReview: _openReview,
                    hasReview: _reviewedAppointmentIds.contains(_appointments[i].id),
                  ),
                  childCount: _appointments.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final void Function(Appointment) onCancel;
  final void Function(Appointment) onReview;
  final bool hasReview;

  const _AppointmentCard({
    required this.appt,
    required this.onCancel,
    required this.onReview,
    required this.hasReview,
  });

  Color get _statusColor => switch (appt.status.toLowerCase()) {
        'confirmed' => AppColors.success,
        'cancelled' => AppColors.error,
        _ => AppColors.warning,
      };

  IconData get _statusIcon => switch (appt.status.toLowerCase()) {
        'confirmed' => Icons.check_circle_rounded,
        'cancelled' => Icons.cancel_rounded,
        _ => Icons.schedule_rounded,
      };

  String get _statusLabel =>
      appt.status[0].toUpperCase() + appt.status.substring(1);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top strip with status color
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.spa_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appt.service.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text('NPR ${appt.service.price.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text(_statusLabel,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(appt.formattedDate,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(appt.formattedTime,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(appt.notes!,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                if (appt.status.toLowerCase() != 'cancelled') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Cancel button (left)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onCancel(appt),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  size: 16, color: AppColors.error),
                              const SizedBox(width: 5),
                              Text('Cancel',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.error)),
                            ],
                          ),
                        ),
                      ),
                      // Divider between actions
                      if (appt.isPast) ...[
                        Container(width: 1, height: 18, color: AppColors.textHint),
                        // Review button (right)
                        Expanded(
                          child: hasReview
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        size: 16, color: AppColors.success),
                                    const SizedBox(width: 5),
                                    Text('Reviewed',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.success)),
                                  ],
                                )
                              : GestureDetector(
                                  onTap: () => onReview(appt),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.rate_review_rounded,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 5),
                                      Text('Leave Review',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
