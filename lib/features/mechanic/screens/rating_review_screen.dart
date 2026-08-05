import 'package:flutter/material.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/widgets/review_star.dart';
import 'package:mecha_connect/features/mechanic/widgets/primary_action_button.dart';

class RatingReviewScreen extends StatefulWidget {
  final MechanicInfo mechanic;

  const RatingReviewScreen({super.key, required this.mechanic});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitted = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _submitReview() {
    setState(() => _isSubmitted = true);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) return _buildThankYouScreen(context);

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Rate Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
      ),
      body: ConstrainedContent(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: AppSpacing.xxxl),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.brandOrangeSoft, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.star_rounded, size: 40, color: AppColors.brandOrange),
            ),
            SizedBox(height: AppSpacing.lg),
            Text('How was your service?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
            SizedBox(height: AppSpacing.sm),
            Text('Tap a star to rate ${widget.mechanic.name}', style: TextStyle(fontSize: 14, color: context.textTertiary)),
            SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return Padding(
                  padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                  child: ReviewStar(starIndex: starIndex, currentRating: _rating, onTap: (v) => setState(() => _rating = v)),
                );
              }),
            ),
            SizedBox(height: AppSpacing.xxxl),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                hintStyle: TextStyle(fontSize: 14, color: context.textTertiary),
                filled: true,
                fillColor: context.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.brandOrange, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: TextStyle(fontSize: 14, color: context.textPrimary),
            ),
            SizedBox(height: AppSpacing.xxxl),
            PrimaryActionButton(
              label: _rating > 0 ? 'Submit Review' : 'Skip',
              onPressed: _submitReview,
            ),
            SizedBox(height: AppSpacing.md),
            if (_rating == 0)
              TextButton(
                onPressed: _submitReview,
                child: Text('Submit without rating', style: TextStyle(fontSize: 14, color: context.textTertiary)),
              ),
            SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildThankYouScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: ConstrainedContent(
        child: SafeArea(
          child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.brandOrangeSoft,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.brandOrange.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.favorite_rounded, size: 52, color: AppColors.brandOrange),
                ),
                SizedBox(height: AppSpacing.xxxl),
                Text('Thank You!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Space Grotesk', color: context.textPrimary)),
                SizedBox(height: AppSpacing.sm),
                Text('Your feedback helps us improve', style: TextStyle(fontSize: 15, color: context.textTertiary)),
                SizedBox(height: AppSpacing.xxxl),
                if (_rating > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_rating, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.star_rounded, size: 28, color: const Color(0xFFF59E0B)),
                    )),
                  ),
                  SizedBox(height: AppSpacing.base),
                  if (_commentController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderSoft),
                      ),
                      child: Text(_commentController.text, style: TextStyle(fontSize: 14, color: context.textSecondary, fontStyle: FontStyle.italic)),
                    ),
                ],
                const Spacer(),
                PrimaryActionButton(
                  label: 'Back to Home',
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
                SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
