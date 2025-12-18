import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class CustomElevatedButton extends StatefulWidget {
  final String text;
  final IconData? iconData;
  final Widget? iconAsset;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? arrowColor;
  final bool showArrow;

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.iconData,
    this.iconAsset,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.arrowColor,
    this.showArrow = true,
  });

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    setState(() => _isPressed = true);
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _isPressed = false);
    await Future.delayed(const Duration(milliseconds: 100));
    widget.onPressed();
  }

  @override
  Widget build(final BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 4)),
                ],
        ),
        child: Material(
          color: widget.backgroundColor ?? context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            // 👇 Hover & Splash efektlerini tamamen devre dışı bırakıyoruz
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.all(18),
              transform: _isPressed
                  ? (Matrix4.identity()..scale(0.98))
                  : Matrix4.identity(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.iconData != null)
                    Icon(widget.iconData,
                        color: widget.iconColor ??
                            context.theme.bottomNavigationBarTheme
                                .selectedItemColor,
                        size: 24)
                  else if (widget.iconAsset != null)
                    widget.iconAsset!
                  else
                    const SizedBox(width: 0),
                  Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            widget.text,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: widget.textColor ??
                                    context.theme.textTheme.bodyLarge?.color),
                          ))),
                  if (widget.showArrow)
                    Icon(Icons.arrow_forward_ios,
                        size: 20,
                        color: widget.arrowColor ??
                            context.theme.iconTheme.color?.withOpacity(0.6)),
                ],
              ),
            ),
          ),
        ),
      );
}
