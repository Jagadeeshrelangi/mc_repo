import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/widgets/review_star.dart';
import 'package:mecha_connect/features/mechanic/widgets/primary_action_button.dart';
import 'package:mecha_connect/services/api_client.dart';

class RatingReviewScreen extends StatefulWidget {
  final String bookingId;
  final MechanicInfo? mechanic;
  final String? serviceName;

  const RatingReviewScreen({
    super.key,
    required this.bookingId,
    this.mechanic,
    this.serviceName,
  });

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitted = false;
  bool _isLoadingInitial = true;
  bool _isSubmitting = false;
  String? _validationError;
  String? _initialLoadError;
  String? _submitError;
  BookingRating? _existingRating;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingRating();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    setState(() {
      _isLoadingInitial = true;
      _initialLoadError = null;
    });

    try {
      final provider = Provider.of<MechanicProvider>(context, listen: false);
      final existing = await provider.fetchRating(widget.bookingId);
      if (mounted) {
        setState(() {
          _existingRating = existing;
          if (existing != null) {
            _rating = existing.rating.round();
            if (existing.review != null && existing.review!.isNotEmpty) {
              _commentController.text = existing.review!;
            }
          }
          _isLoadingInitial = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
          _initialLoadError = e is ApiException
              ? e.message
              : 'Failed to load rating details. Please check your connection.';
        });
      }
    }
  }

  Future<void> _submitReview() async {
    setState(() {
      _validationError = null;
      _submitError = null;
    });

    if (_rating < 1 || _rating > 5) {
      setState(() {
        _validationError = 'Please select a rating between 1 and 5 stars.';
      });
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.length > 2000) {
      setState(() {
        _validationError = 'Review cannot exceed 2,000 characters.';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<MechanicProvider>(context, listen: false);
      final result = await provider.submitRating(
        widget.bookingId,
        rating: _rating.toDouble(),
        review: comment.isNotEmpty ? comment : null,
      );

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _existingRating = result;
          _isSubmitting = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitError = e is ApiException
              ? e.message
              : 'Failed to submit review. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) return _buildThankYouScreen(context);

    final title = widget.mechanic?.name ?? widget.serviceName ?? 'Service';

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Rate Service',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
            color: context.textPrimary,
          ),
        ),
      ),
      body: ConstrainedContent(
        child: _isLoadingInitial
            ? _buildLoadingState(context)
            : _initialLoadError != null && _existingRating == null
                ? _buildInitialErrorState(context)
                : _existingRating != null
                    ? _buildAlreadyReviewedState(context, title)
                    : _buildReviewForm(context, title),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.brandOrange),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Checking service details...',
            style: TextStyle(fontSize: 14, color: context.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Unable to Load Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Space Grotesk',
                color: context.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              _initialLoadError ?? 'An error occurred while loading.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textTertiary),
            ),
            SizedBox(height: AppSpacing.xxxl),
            SizedBox(
              width: 160,
              child: PrimaryActionButton(
                label: 'Retry',
                onPressed: _loadExistingRating,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyReviewedState(BuildContext context, String title) {
    final rating = _existingRating!;
    final stars = rating.rating.round();

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppSpacing.xxxl),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 40,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Review Submitted',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'You have already rated this service for $title',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.textTertiary),
          ),
          SizedBox(height: AppSpacing.xxxl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starIndex <= stars
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 32,
                        color: starIndex <= stars
                            ? AppColors.warning
                            : context.textTertiary,
                      ),
                    );
                  }),
                ),
                SizedBox(height: AppSpacing.base),
                Text(
                  '${rating.rating.toStringAsFixed(1)} out of 5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (rating.review != null && rating.review!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.bgTertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      rating.review!,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xxxl),
          PrimaryActionButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildReviewForm(BuildContext context, String title) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppSpacing.xxxl),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.brandOrangeSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 40,
              color: AppColors.brandOrange,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'How was your service?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Space Grotesk',
              color: context.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Tap a star to rate $title',
            style: TextStyle(fontSize: 14, color: context.textTertiary),
          ),
          SizedBox(height: AppSpacing.xxxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return Padding(
                padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                child: ReviewStar(
                  starIndex: starIndex,
                  currentRating: _rating,
                  onTap: (v) {
                    setState(() {
                      _rating = v;
                      _validationError = null;
                    });
                  },
                ),
              );
            }),
          ),
          if (_validationError != null) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              _validationError!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xxxl),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 2000,
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
                borderSide: const BorderSide(
                  color: AppColors.brandOrange,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(fontSize: 14, color: context.textPrimary),
          ),
          if (_submitError != null) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _submitReview,
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xxxl),
          if (_isSubmitting)
            const Center(
              child: CircularProgressIndicator(color: AppColors.brandOrange),
            )
          else
            PrimaryActionButton(
              label: 'Submit Review',
              onPressed: _submitReview,
            ),
          SizedBox(height: AppSpacing.xxxl),
        ],
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.brandOrangeSoft,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandOrange.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 52,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                  Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Space Grotesk',
                      color: context.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your feedback helps us improve',
                    style: TextStyle(fontSize: 15, color: context.textTertiary),
                  ),
                  SizedBox(height: AppSpacing.xxxl),
                  if (_rating > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _rating,
                        (i) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            Icons.star_rounded,
                            size: 28,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
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
                        child: Text(
                          _commentController.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: context.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                  const Spacer(),
                  PrimaryActionButton(
                    label: 'Back to Home',
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
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
