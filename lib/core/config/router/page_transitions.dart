import 'package:flutter/material.dart';

/// Saydamlaşarak geçiş (Fade)
Widget fadeTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child);

/// Sağdan sola kayarak geçiş (Slide)
Widget slideTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );

/// Büyüyerek gelme (Scale)
Widget scaleTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        child: FadeTransition(opacity: animation, child: child));
