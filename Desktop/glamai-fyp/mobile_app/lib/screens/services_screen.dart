import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'book_appointment_screen.dart';

class ServicesScreen extends StatefulWidget {
  final int userId;
  const ServicesScreen({super.key, required this.userId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const _tag = 'ServicesScreen';

  List<Service> _services = [];
  bool _loading = true;
  String? _error;

  final List<Map<String, dynamic>> _iconMap = [
    {'icon': Icons.content_cut_rounded, 'color': Color(0xFFE91E8C)},
    {'icon': Icons.face_retouching_natural, 'color': Color(0xFF9C27B0)},
    {'icon': Icons.color_lens_rounded, 'color': Color(0xFFFF6D00)},
    {'icon': Icons.brush_rounded, 'color': Color(0xFF00897B)},
    {'icon': Icons.spa_rounded, 'color': Color(0xFF1565C0)},
    {'icon': Icons.water_drop_rounded, 'color': Color(0xFFAD1457)},
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    AppLogger.info(_tag, 'Loading services');
    setState(() { _loading = true; _error = null; });
    try {
      final services = await ApiService.getServices();
      setState(() { _services = services; _loading = false; });
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error', e);
      setState(() { _error = e.message; _loading = false; });
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error', e);
      setState(() { _error = e.message; _loading = false; });
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Services',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('Book your favourite treatment',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
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
                          onPressed: _loadServices,
                          icon: Icons.refresh_rounded),
                    ],
                  ),
                ),
              ),
            )
          else if (_services.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.spa_rounded, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No services available',
                        style: GoogleFonts.poppins(
                            fontSize: 15, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final s = _services[i];
                    final ic = _iconMap[i % _iconMap.length];
                    final color = ic['color'] as Color;
                    final icon = ic['icon'] as IconData;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(
                            userId: widget.userId,
                            service: s,
                          ),
                        ),
                      ),
                      child: Container(
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: color, size: 26),
                            ),
                            const Spacer(),
                            Text(s.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (s.description != null) ...[
                              const SizedBox(height: 2),
                              Text(s.description!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('NPR ${s.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: color)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Book',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: color)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _services.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
