import 'package:flutter/material.dart';

import '../../style/app_colors.dart';

class BoxWidget extends StatelessWidget {
  const BoxWidget({
    super.key,
    this.contentKey,
    this.child,
    this.width,
    this.height,
    this.color,
    this.gradient,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1,
    this.shape = BoxShape.rectangle,
    this.radius,
    this.enableShadow = true,
    // this.shadowOffsetX = -1,
    // this.shadowOffsetY = 2,
    this.blurRadius = 0,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.clipBehaviour = Clip.none,
    this.onTap,
  });

  final GlobalKey? contentKey;
  final Widget? child;
  final double? width;
  final double? height;
  final Color? color;
  final Gradient? gradient;
  final Color borderColor;
  final double borderWidth;
  final BoxShape shape;
  ///Default is [EBorderRadius.all(8)]
  final BorderRadius? radius;
  // final double shadowOffsetX;
  // final double shadowOffsetY;
  final double blurRadius;
  final bool enableShadow;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Clip clipBehaviour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if(onTap != null) {
      return GestureDetector(
        onTap: () => onTap?.call(),
        child: _buildChild(),
      );
    }

    return _buildChild();
  }

  Widget _buildChild() {
    return Container(
      key: contentKey,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      clipBehavior: clipBehaviour,
      decoration: BoxDecoration(
        shape: shape,
        color: color == Colors.transparent ? null : (color ?? AppColors.backgroundLight),
        gradient: gradient,
        border: Border.fromBorderSide(
          BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        borderRadius: shape == BoxShape.circle ? null : radius ?? const BorderRadius.all(Radius.circular(8)),
        boxShadow: color == Colors.transparent || !enableShadow ? null : [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            // offset: Offset(shadowOffsetX, shadowOffsetY),
            blurRadius: blurRadius,
          ),
        ],
      ),
      child: ClipRRect(
        clipBehavior: clipBehaviour,
        borderRadius: shape == BoxShape.circle
            ? BorderRadius.zero
            : radius ?? BorderRadius.circular(10), // Content radius (inside the border)
        child: child,
      ),
    );
  }
}
