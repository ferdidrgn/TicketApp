import 'package:flutter/material.dart';

class ScrollDownIndicator extends StatelessWidget {
  const ScrollDownIndicator({super.key});

  @override
  Widget build(final BuildContext context) {
    return _AnimatedArrow();
  }
}

class _AnimatedArrow extends StatefulWidget {
  @override
  State<_AnimatedArrow> createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<_AnimatedArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: const [
          Text(
            'Aşağı kaydır',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(blurRadius: 8, color: Colors.black),
              ],
            ),
          ),
          SizedBox(height: 8),
          Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
        ],
      ),
    );
  }
}
