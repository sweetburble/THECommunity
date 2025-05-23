import 'package:flutter/material.dart';

/**
 * 약간 둥근 정사각형 Container 위젯을 쉽게 만드는 클래스
 */
class RoundedContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double radiusValue;
  final BorderRadiusGeometry? radius;

  const RoundedContainer({
    super.key,
    this.padding,
    this.margin,
    this.color,
    this.radiusValue = 10,
    this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? BorderRadius.circular(radiusValue),
      ),
      child: child,
    );
  }
}
