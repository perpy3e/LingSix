import 'package:flutter/material.dart';

class Responsive {
  Responsive._(this.size);

  final Size size;

  static Responsive of(BuildContext context) {
    return Responsive._(MediaQuery.sizeOf(context));
  }

  bool get isTablet => size.shortestSide >= 600;

  double scale(num base, {double minScale = 0.85, double maxScale = 1.25}) {
    final widthScale = size.width / 390;
    final heightScale = size.height / 844;
    final baseScale = ((widthScale + heightScale) / 2).clamp(
      minScale,
      maxScale,
    );
    final tabletBoost = isTablet ? 1.08 : 1.0;
    return base.toDouble() * baseScale * tabletBoost;
  }

  double spacing(num base) => scale(base, minScale: 0.8, maxScale: 1.35);

  double text(num base) => scale(base, minScale: 0.9, maxScale: 1.2);

  double icon(num base) => scale(base, minScale: 0.85, maxScale: 1.25);

  double buttonHeight([double base = 56]) {
    return spacing(base).clamp(48, 72).toDouble();
  }

  double contentMaxWidth({double phone = 520, double tablet = 720}) {
    return isTablet ? tablet : phone;
  }

  EdgeInsets pagePadding({
    double horizontal = 24,
    double vertical = 0,
    double min = 12,
    double maxPhone = 28,
    double maxTablet = 56,
  }) {
    final max = isTablet ? maxTablet : maxPhone;
    return EdgeInsets.symmetric(
      horizontal: spacing(horizontal).clamp(min, max).toDouble(),
      vertical: spacing(vertical),
    );
  }
}

extension ResponsiveX on BuildContext {
  Responsive get responsive => Responsive.of(this);
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? r.contentMaxWidth()),
        child: child,
      ),
    );
  }
}
