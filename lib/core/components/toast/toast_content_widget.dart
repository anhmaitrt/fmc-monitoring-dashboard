import 'package:flutter/material.dart';

import '../../style/app_colors.dart';
import '../../style/app_text_styles.dart';
import '../../utils/app_size.dart';
import '../container/box_widget.dart';

class ToastContentWidget extends StatefulWidget {
  const ToastContentWidget({
    super.key,
    this.message,
    this.messageWidget,
    this.icon,
    this.messageColor,
    this.style,
    this.textAlign = TextAlign.center,
    this.textOverflow = TextOverflow.fade,
    this.backgroundColor,
  }) : assert(message != null || messageWidget != null);

  final String? message;
  ///For rich text,...
  final Widget? messageWidget;
  final Widget? icon;
  final Color? messageColor;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? textOverflow;
  final Color? backgroundColor;

  @override
  State<ToastContentWidget> createState() => _ToastContentWidgetState();
}

class _ToastContentWidgetState extends State<ToastContentWidget> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> position;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000),);
    position = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24).copyWith(top: 10),
        child: SlideTransition(
          position: position,
          child: Column(
            children: [
              BoxWidget(
                color: widget.backgroundColor/* ?? AppColors.successBackground*/,
                radius: AppSize.defaultRadius,
                padding: EEdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: IntrinsicWidth(
                  child: Row(
                    children: [
                      if(widget.icon != null)
                        Padding(
                          padding: EEdgeInsets.only(right: 12),
                          child: widget.icon,
                        ),
                      Expanded(
                        child: widget.messageWidget ?? Text(
                          widget.message ?? '',
                          textAlign: widget.textAlign,
                          overflow: widget.textOverflow,
                          style: (widget.style ?? AppTextStyle.bo16Primary)
                              .copyWith(
                            color: widget.messageColor ??
                                AppColors.success,
                            height: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
