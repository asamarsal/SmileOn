import 'package:flutter/material.dart';

class ThreeDotsIndicator extends StatefulWidget {
  final double dotSize;
  final double spacing;

  const ThreeDotsIndicator({
    super.key,
    this.dotSize = 14.0,
    this.spacing = 12.0,
  });

  @override
  State<ThreeDotsIndicator> createState() => _ThreeDotsIndicatorState();
}

class _ThreeDotsIndicatorState extends State<ThreeDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const List<Color> _dotColors = [
    Color(0xFFFF2D75), // Hot Pink / Active
    Color(0xFFFF85A1), // Soft Pink / Medium
    Color(0xFF4A4A4A), // Muted Dark Grey
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final step = (_controller.value * 3).floor() % 3;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Rotasi warna untuk memberikan efek pulsing 3 titik berjalan
            final colorIndex = (index - step + 3) % 3;
            final color = _dotColors[colorIndex];
            final isHighlighted = colorIndex == 0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: _dotColors[0].withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            );
          }),
        );
      },
    );
  }
}
