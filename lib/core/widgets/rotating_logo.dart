import 'package:flutter/material.dart';

class RotatingLogo extends StatefulWidget {
  final double size;

  const RotatingLogo({super.key, this.size = 150.0});

  @override
  State<RotatingLogo> createState() => _RotatingLogoState();
}

class _RotatingLogoState extends State<RotatingLogo>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Rotation Controller: Smooth 10s planetary spin
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 2. Glow Controller: 3s breathing/pulsing effect
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 5.0, end: 20.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Atmospheric Glow using Mizan Accent Gold
              BoxShadow(
                color: const Color(0xFFC6A664).withOpacity(0.4),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
              // Inner depth shadow
              const BoxShadow(
                color: Colors.black38,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _rotationController,
                curve: Curves.linear,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logos/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1B5E20),
                    child: const Icon(
                      Icons.public,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
