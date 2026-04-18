import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/appointment.dart';
import '../models/feedback.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';

class FeedbackScreen extends StatefulWidget {
  final Appointment appointment;
  const FeedbackScreen({super.key, required this.appointment});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const _tag = 'FeedbackScreen';

  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _submitting = false;
  AppFeedback? _result;
  String? _error;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }
    if (_reviewController.text.trim().length < 5) {
      setState(() => _error = 'Review must be at least 5 characters.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    AppLogger.info(_tag, 'Submitting feedback for appointment ${widget.appointment.id}');
    try {
      final feedback = await ApiService.submitFeedback(
        appointmentId: widget.appointment.id,
        rating: _rating,
        reviewText: _reviewController.text.trim(),
      );
      setState(() { _result = feedback; _submitting = false; });
    } on AppException catch (e) {
      setState(() { _error = e.message; _submitting = false; });
    }
  }

  Color get _sentimentColor => switch (_result?.sentimentLabel) {
        'positive' => AppColors.success,
        'negative' => AppColors.error,
        _ => AppColors.warning,
      };

  IconData get _sentimentIcon => switch (_result?.sentimentLabel) {
        'positive' => Icons.sentiment_very_satisfied_rounded,
        'negative' => Icons.sentiment_very_dissatisfied_rounded,
        _ => Icons.sentiment_neutral_rounded,
      };

  String get _sentimentTitle => switch (_result?.sentimentLabel) {
        'positive' => 'Positive Review',
        'negative' => 'Negative Review',
        _ => 'Neutral Review',
      };

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
                          Text('Leave a Review',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(widget.appointment.service.name,
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
              child: _result != null ? _SuccessCard(
                result: _result!,
                sentimentColor: _sentimentColor,
                sentimentIcon: _sentimentIcon,
                sentimentTitle: _sentimentTitle,
                onDone: () => Navigator.pop(context, true),
              ) : _FormCard(
                appointment: widget.appointment,
                rating: _rating,
                reviewController: _reviewController,
                submitting: _submitting,
                error: _error,
                onRatingChanged: (r) => setState(() { _rating = r; _error = null; }),
                onSubmit: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Appointment appointment;
  final int rating;
  final TextEditingController reviewController;
  final bool submitting;
  final String? error;
  final void Function(int) onRatingChanged;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.appointment,
    required this.rating,
    required this.reviewController,
    required this.submitting,
    required this.error,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appointment summary
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.spa_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.service.name,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(
                      '${appointment.formattedDate}  ·  ${appointment.formattedTime}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Star rating
        Text('Your Rating',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => onRatingChanged(star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 44,
                  color: star <= rating ? const Color(0xFFF59E0B) : AppColors.textHint,
                ),
              ),
            );
          }),
        ),
        if (rating > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][rating],
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.warning),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Review text
        Text('Your Review',
            style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        TextField(
          controller: reviewController,
          maxLines: 4,
          maxLength: 1000,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Share your experience with this service…',
            hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(error!,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.error)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        GradientButton(
          label: 'Submit Review',
          icon: Icons.rate_review_rounded,
          loading: submitting,
          onPressed: submitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final AppFeedback result;
  final Color sentimentColor;
  final IconData sentimentIcon;
  final String sentimentTitle;
  final VoidCallback onDone;

  const _SuccessCard({
    required this.result,
    required this.sentimentColor,
    required this.sentimentIcon,
    required this.sentimentTitle,
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 52, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          Text('Thank you!',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Your review has been submitted.',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),

          // Star rating display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Icon(
              i < result.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 28,
              color: i < result.rating ? const Color(0xFFF59E0B) : AppColors.textHint,
            )),
          ),
          const SizedBox(height: 20),

          // Sentiment badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: sentimentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sentimentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(sentimentIcon, color: sentimentColor, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sentiment Analysis',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    Text(sentimentTitle,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: sentimentColor)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Review text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '"${result.reviewText}"',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
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
