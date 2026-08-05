import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mecha_connect/features/marketplace/models/offer.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';

/// Auto-advancing hero banner carousel over the marketplace offers.
class MarketplaceHeroBanner extends StatefulWidget {
  final List<Offer> offers;
  final void Function(Offer offer) onTap;

  const MarketplaceHeroBanner({
    super.key,
    required this.offers,
    required this.onTap,
  });

  @override
  State<MarketplaceHeroBanner> createState() => _MarketplaceHeroBannerState();
}

class _MarketplaceHeroBannerState extends State<MarketplaceHeroBanner> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _startAutoPlay();
      }
    });
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.offers.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % widget.offers.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Semantics(
          label:
              'Promotion banner, offer ${_page + 1} of ${widget.offers.length}',
          child: SizedBox(
            height: AppResponsive.responsive<double>(context,
                mobile: 176, tablet: 176, desktop: 180),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.offers.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final offer = widget.offers[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? AppResponsive.horizontalPadding(context) : 4,
                    right: AppResponsive.horizontalPadding(context),
                  ),
                  child: _HeroSlide(
                    offer: offer,
                    onTap: () => widget.onTap(offer),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.offers.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.offers.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? AppColors.brandOrange
                        : AppColors.grey300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final Offer offer;
  final VoidCallback onTap;

  const _HeroSlide({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [offer.gradientStart, offer.gradientEnd],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        offer.title,
                        style: TextStyle(
                          fontFamily: 'Space Grotesk',
                          fontSize: AppResponsive.scaleFont(context, 18),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        offer.subtitle,
                        style: TextStyle(
                          fontSize: AppResponsive.scaleFont(context, 12),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Use code ${offer.code}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
