import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/face_shape_result.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'login_screen.dart';

class RecommendationScreen extends StatefulWidget {
  final int userId;
  const RecommendationScreen({super.key, required this.userId});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  static const _tag = 'RecommendationScreen';

  final _occasionController = TextEditingController();
  final _concernsController = TextEditingController();
  String? _faceShape;
  String? _hairType;
  String? _result;
  bool _loading = false;
  bool _detecting = false;
  String? _error;
  double? _detectionConfidence;

  static const _faceShapes = ['Heart', 'Oblong', 'Oval', 'Round', 'Square'];
  static const _hairTypes = ['Straight', 'Wavy', 'Curly', 'Coily'];

  @override
  void dispose() {
    _occasionController.dispose();
    _concernsController.dispose();
    super.dispose();
  }

  Future<void> _autoDetectFaceShape() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Choose Photo Source',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _SourceTile(
              icon: Icons.camera_alt_rounded,
              label: 'Take a selfie',
              subtitle: 'Use your camera',
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              subtitle: 'Pick an existing photo',
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 640);
    if (picked == null) return;

    AppLogger.info(_tag, 'Running face shape detection');
    setState(() { _detecting = true; _error = null; });

    try {
      final FaceShapeResult result =
          await ApiService.detectFaceShape(File(picked.path));
      setState(() {
        _faceShape = result.faceShape;
        _detectionConfidence = result.confidence;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Detected: ${result.faceShape} (${result.confidence.toStringAsFixed(1)}% confidence)'),
          ),
        );
      }
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } on ServerException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _detecting = false);
    }
  }

  Future<void> _getRecommendation() async {
    AppLogger.info(_tag, 'Fetching recommendation');
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final body = await ApiService.getRecommendation(
        faceShape: _faceShape,
        hairType: _hairType,
        occasion: _occasionController.text.trim().isEmpty
            ? null
            : _occasionController.text.trim(),
        concerns: _concernsController.text.trim().isEmpty
            ? null
            : _concernsController.text.trim(),
      );
      setState(() => _result = body);
    } on AuthException {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on NetworkException catch (e) {
      setState(() => _error = e.message);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
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
                      Text('AI Stylist',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('Personalised recommendations just for you',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ── Face detect card ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                    Icons.face_retouching_natural,
                                    color: Colors.white,
                                    size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Auto-Detect Face Shape',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                    Text('Upload a selfie for AI analysis',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_faceShape != null && _detectionConfidence != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: AppColors.primary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Detected: $_faceShape face  •  ${_detectionConfidence!.toStringAsFixed(1)}% confidence',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _detecting
                                    ? const LinearGradient(
                                        colors: [Colors.grey, Colors.grey])
                                    : primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _detecting ? null : _autoDetectFaceShape,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _detecting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 18),
                                label: Text(
                                    _detecting ? 'Detecting…' : 'Detect My Face Shape',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Manual selections card ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Details',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Or select manually below',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),

                          // Face shape
                          _SectionLabel(label: 'Face Shape'),
                          const SizedBox(height: 8),
                          _ChipSelector(
                            options: _faceShapes,
                            selected: _faceShape,
                            onSelect: (val) => setState(() {
                              _faceShape = val;
                              _detectionConfidence = null;
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Hair type
                          _SectionLabel(label: 'Hair Type'),
                          const SizedBox(height: 8),
                          _ChipSelector(
                            options: _hairTypes,
                            selected: _hairType,
                            onSelect: (val) =>
                                setState(() => _hairType = val),
                          ),
                          const SizedBox(height: 16),

                          _SectionLabel(label: 'Occasion'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _occasionController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Wedding, casual outing…',
                              prefixIcon: Icon(Icons.event_rounded,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _SectionLabel(label: 'Hair & Skin Concerns'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _concernsController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Dry hair, oily skin, dandruff…',
                              prefixIcon: Icon(Icons.info_outline_rounded,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: AppColors.error)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    GradientButton(
                      label: 'Get My Recommendations',
                      onPressed: _getRecommendation,
                      loading: _loading,
                      icon: Icons.auto_awesome_rounded,
                    ),

                    // ── Result card ────────────────────────────────────────
                    if (_result != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.05),
                              AppColors.secondary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text('Your AI Recommendations',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(),
                            const SizedBox(height: 10),
                            Text(_result!,
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    height: 1.7,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));
}

class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? primaryGradient : null,
              color: isSelected ? null : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.textHint.withValues(alpha: 0.5),
              ),
            ),
            child: Text(opt,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
