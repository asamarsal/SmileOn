import 'dart:async';
import 'package:flutter/material.dart';

export 'smile_ctacard_normal.dart';
export 'smile_ctacard_event.dart';
export 'smile_ctacard_lastactivity.dart';

/// Komponen Kontainer / Carousel CTA Card
/// Menampilkan daftar kartu CTA (misalnya SmileCtaCardNormal dan SmileCtaCardEvent)
/// dengan kemampuan slide otomatis (auto-slide) dan transisi gesture horizontal.
class SmileCtaCard extends StatefulWidget {
  final List<Widget> cards;
  final bool autoSlide;
  final Duration autoSlideInterval;
  final Duration animationDuration;
  final Curve curve;
  final bool showIndicator;
  final double height;
  final ValueChanged<int>? onPageChanged;
  final int initialIndex;

  const SmileCtaCard({
    super.key,
    required this.cards,
    this.height = 220.0,
    this.autoSlide = true,
    this.autoSlideInterval = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 650),
    this.curve = Curves.easeInOutCubic,
    this.showIndicator = true,
    this.onPageChanged,
    this.initialIndex = 0,
  });

  @override
  State<SmileCtaCard> createState() => _SmileCtaCardState();
}

class _SmileCtaCardState extends State<SmileCtaCard> {
  late PageController _pageController;
  late int _currentPage;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(initialPage: _currentPage);

    if (widget.autoSlide && widget.cards.length > 1) {
      _startAutoSlideTimer();
    }
  }

  @override
  void didUpdateWidget(SmileCtaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoSlide != oldWidget.autoSlide ||
        widget.cards.length != oldWidget.cards.length) {
      _stopAutoSlideTimer();
      if (widget.autoSlide && widget.cards.length > 1) {
        _startAutoSlideTimer();
      }
    }
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(widget.autoSlideInterval, (timer) {
      if (!mounted || widget.cards.isEmpty) return;
      final nextPage = (_currentPage + 1) % widget.cards.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: widget.animationDuration,
          curve: widget.curve,
        );
      }
    });
  }

  void _stopAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _restartAutoSlideTimer() {
    if (widget.autoSlide && widget.cards.length > 1) {
      _startAutoSlideTimer();
    }
  }

  @override
  void dispose() {
    _stopAutoSlideTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.cards.length == 1) {
      return widget.cards.first;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PageView untuk slide kartu CTA
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _stopAutoSlideTimer();
            } else if (notification is ScrollEndNotification) {
              _restartAutoSlideTimer();
            }
            return false;
          },
          child: SizedBox(
            // Menyesuaikan tinggi dengan kartu CTA (default 220.0 agar bebas overflow)
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.cards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                widget.onPageChanged?.call(index);
              },
              itemBuilder: (context, index) {
                return widget.cards[index];
              },
            ),
          ),
        ),

        // Indikator Titik / Dot Slider di bawah
        if (widget.showIndicator && widget.cards.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.cards.length, (index) {
              final isSelected = _currentPage == index;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: widget.animationDuration,
                    curve: widget.curve,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3.5),
                  height: 6,
                  width: isSelected ? 20 : 6,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF1475)
                        : const Color(0xFFD1D5DB).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
