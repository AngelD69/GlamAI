import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_stats.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/exceptions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminStats? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await ApiService.getAdminDashboard();
      setState(() { _stats = stats; _loading = false; });
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(gradient: primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Row(
                    children: [
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
                          Text('Admin Dashboard',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('Business analytics overview',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _load,
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
                      const Icon(Icons.error_outline_rounded,
                          size: 52, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      GradientButton(label: 'Retry', onPressed: _load),
                    ],
                  ),
                ),
              ),
            )
          else if (_stats != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _topStatCards(_stats!),
                  const SizedBox(height: 20),
                  _statusBreakdown(_stats!),
                  const SizedBox(height: 20),
                  _sentimentSection(_stats!),
                  const SizedBox(height: 20),
                  _bookingsByService(_stats!),
                  const SizedBox(height: 20),
                  _peakHoursChart(_stats!),
                  const SizedBox(height: 20),
                  _peakDaysChart(_stats!),
                  const SizedBox(height: 20),
                  _recentAppointments(_stats!),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Stat cards row ────────────────────────────────────────────────────────────

  Widget _topStatCards(AdminStats s) {
    final avgRating = s.averageRating != null
        ? s.averageRating!.toStringAsFixed(1)
        : '—';
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total Users', value: '${s.totalUsers}',
            icon: Icons.people_rounded, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Total Bookings', value: '${s.totalBookings}',
            icon: Icons.calendar_month_rounded, color: AppColors.secondary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Avg Rating', value: avgRating,
            icon: Icons.star_rounded, color: const Color(0xFFF59E0B))),
      ],
    );
  }

  // ── Status breakdown ──────────────────────────────────────────────────────────

  Widget _statusBreakdown(AdminStats s) {
    final total = s.statusBreakdown.fold(0, (sum, e) => sum + e.count);
    final colorMap = {
      'pending': AppColors.warning,
      'confirmed': AppColors.success,
      'cancelled': AppColors.error,
      'completed': AppColors.success,
    };
    return _SectionCard(
      title: 'Booking Status',
      icon: Icons.donut_large_rounded,
      child: Column(
        children: s.statusBreakdown.map((e) {
          final color = colorMap[e.status.toLowerCase()] ?? AppColors.textHint;
          final pct = total > 0 ? e.count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    e.status[0].toUpperCase() + e.status.substring(1),
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.count}',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sentiment ─────────────────────────────────────────────────────────────────

  Widget _sentimentSection(AdminStats s) {
    if (s.sentimentSummary.isEmpty) {
      return _SectionCard(
        title: 'Review Sentiment',
        icon: Icons.sentiment_satisfied_alt_rounded,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No reviews yet',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textHint)),
          ),
        ),
      );
    }
    final total = s.sentimentSummary.fold(0, (sum, e) => sum + e.count);
    final colorMap = {
      'positive': AppColors.success,
      'neutral': AppColors.warning,
      'negative': AppColors.error,
    };
    final iconMap = {
      'positive': Icons.sentiment_very_satisfied_rounded,
      'neutral': Icons.sentiment_neutral_rounded,
      'negative': Icons.sentiment_very_dissatisfied_rounded,
    };
    return _SectionCard(
      title: 'Review Sentiment',
      icon: Icons.sentiment_satisfied_alt_rounded,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: s.sentimentSummary.map((e) {
          final color = colorMap[e.sentimentLabel] ?? AppColors.textHint;
          final icon = iconMap[e.sentimentLabel] ?? Icons.help_outline;
          final pct = total > 0 ? (e.count / total * 100).round() : 0;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text('${e.count}',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text('$pct%',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(
                e.sentimentLabel[0].toUpperCase() + e.sentimentLabel.substring(1),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Bookings by service ───────────────────────────────────────────────────────

  Widget _bookingsByService(AdminStats s) {
    if (s.bookingsByService.isEmpty) {
      return _SectionCard(
        title: 'Bookings by Service',
        icon: Icons.spa_rounded,
        child: Center(
          child: Text('No booking data yet',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
        ),
      );
    }
    final max = s.bookingsByService.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return _SectionCard(
      title: 'Bookings by Service',
      icon: Icons.spa_rounded,
      child: Column(
        children: s.bookingsByService.map((e) {
          final pct = max > 0 ? e.count / max : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(e.serviceName,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.count}',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Peak hours bar chart ──────────────────────────────────────────────────────

  Widget _peakHoursChart(AdminStats s) {
    if (s.bookingsByHour.isEmpty) {
      return _SectionCard(
        title: 'Peak Hours',
        icon: Icons.schedule_rounded,
        child: Center(
          child: Text('No data yet',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
        ),
      );
    }
    final max = s.bookingsByHour.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return _SectionCard(
      title: 'Peak Booking Hours',
      icon: Icons.schedule_rounded,
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: s.bookingsByHour.map((e) {
            final frac = max > 0 ? e.count / max : 0.0;
            final isTop = e.count == max;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isTop)
                  Text('${e.count}',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                const SizedBox(height: 2),
                Container(
                  width: 22,
                  height: 80 * frac + 4,
                  decoration: BoxDecoration(
                    color: isTop ? AppColors.primary : AppColors.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.label,
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: AppColors.textSecondary)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Peak days chart ───────────────────────────────────────────────────────────

  Widget _peakDaysChart(AdminStats s) {
    if (s.bookingsByDay.isEmpty) {
      return _SectionCard(
        title: 'Bookings by Day',
        icon: Icons.calendar_today_rounded,
        child: Center(
          child: Text('No data yet',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint)),
        ),
      );
    }
    final max = s.bookingsByDay.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return _SectionCard(
      title: 'Bookings by Day of Week',
      icon: Icons.calendar_today_rounded,
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: s.bookingsByDay.map((e) {
            final frac = max > 0 ? e.count / max : 0.0;
            final isTop = e.count == max;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isTop)
                  Text('${e.count}',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary)),
                const SizedBox(height: 2),
                Container(
                  width: 28,
                  height: 80 * frac + 4,
                  decoration: BoxDecoration(
                    color: isTop
                        ? AppColors.secondary
                        : AppColors.secondary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(e.shortName,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Recent appointments ───────────────────────────────────────────────────────

  Widget _recentAppointments(AdminStats s) {
    final colorMap = {
      'pending': AppColors.warning,
      'confirmed': AppColors.success,
      'cancelled': AppColors.error,
      'completed': AppColors.success,
    };
    return _SectionCard(
      title: 'Recent Bookings',
      icon: Icons.history_rounded,
      child: s.recentAppointments.isEmpty
          ? Center(
              child: Text('No bookings yet',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textHint)))
          : Column(
              children: s.recentAppointments.map((a) {
                final color =
                    colorMap[a.status.toLowerCase()] ?? AppColors.textHint;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.userName,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            Text(a.serviceName,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(a.appointmentDate,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textSecondary)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.status[0].toUpperCase() + a.status.substring(1),
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
