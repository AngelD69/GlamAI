import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/face_shape_result.dart';
import '../services/api_service.dart';
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

  // Face shape classes must match the trained model (Heart, Oblong, Oval, Round, Square)
  static const _faceShapes = ['Heart', 'Oblong', 'Oval', 'Round', 'Square'];
  static const _hairTypes = ['Straight', 'Wavy', 'Curly', 'Coily'];

  Future<void> _autoDetectFaceShape() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 640,
    );
    if (picked == null) return;

    AppLogger.info(_tag, 'Running face shape detection on ${picked.path}');
    setState(() { _detecting = true; _error = null; });

    try {
      final FaceShapeResult result = await ApiService.detectFaceShape(File(picked.path));
      setState(() {
        _faceShape = result.faceShape;
        _detectionConfidence = result.confidence;
      });
      AppLogger.info(_tag, 'Face shape detected: ${result.faceShape} (${result.confidence}%)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Detected: $_faceShape (${_detectionConfidence?.toStringAsFixed(1)}% confidence)',
            ),
            backgroundColor: const Color(0xFFE91E8C),
          ),
        );
      }
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error during detection', e);
      setState(() => _error = e.message);
    } on ServerException catch (e) {
      // 503 means model not ready yet
      AppLogger.warning(_tag, 'Model not ready: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Detection error', e);
      setState(() => _error = e.message);
    } finally {
      setState(() => _detecting = false);
    }
  }

  Future<void> _getRecommendation() async {
    AppLogger.info(
        _tag, 'Fetching recommendation (faceShape=$_faceShape, hairType=$_hairType)');
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final String body = await ApiService.getRecommendation(
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
      AppLogger.info(_tag, 'Recommendation received');
    } on AuthException catch (e) {
      AppLogger.warning(_tag, 'Auth expired: $e');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error fetching recommendation', e);
      setState(() => _error = e.message);
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error fetching recommendation', e);
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Recommendation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFE91E8C)),
                SizedBox(width: 8),
                Text('Personalised for you',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Use AI to detect your face shape, or select it manually.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // ── Auto-detect banner ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E8C).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFE91E8C).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.face_retouching_natural,
                      size: 36, color: Color(0xFFE91E8C)),
                  const SizedBox(height: 8),
                  const Text(
                    'Auto-detect your face shape',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Take a selfie or upload a photo and our AI model will classify your face shape.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _detecting ? null : _autoDetectFaceShape,
                    icon: _detecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(_detecting ? 'Detecting…' : 'Detect Face Shape'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E8C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_faceShape != null && _detectionConfidence != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Detected: $_faceShape (${_detectionConfidence!.toStringAsFixed(1)}%)',
                      style: const TextStyle(
                          color: Color(0xFFE91E8C),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Or select manually',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 13)),
            const SizedBox(height: 12),

            // ── Face shape dropdown ───────────────────────────────────────
            InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Face Shape',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.face),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
              child: DropdownButton<String>(
                value: _faceShape,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Select face shape'),
                items: _faceShapes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() {
                  _faceShape = val;
                  _detectionConfidence = null;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // ── Hair type dropdown ────────────────────────────────────────
            InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Hair Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.spa),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
              child: DropdownButton<String>(
                value: _hairType,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Select hair type'),
                items: _hairTypes
                    .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                    .toList(),
                onChanged: (val) => setState(() => _hairType = val),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _occasionController,
              decoration: const InputDecoration(
                  labelText: 'Occasion (e.g. wedding, casual)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _concernsController,
              decoration: const InputDecoration(
                  labelText: 'Hair / skin concerns',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline)),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _getRecommendation,
                icon: const Icon(Icons.auto_awesome),
                label: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Get Recommendation',
                        style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E8C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          const Color(0xFFE91E8C).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Color(0xFFE91E8C), size: 18),
                        SizedBox(width: 8),
                        Text('Your Recommendations',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE91E8C))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_result!, style: const TextStyle(height: 1.6)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
