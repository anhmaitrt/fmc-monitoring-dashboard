import 'package:flutter/material.dart';

import '../style/app_colors.dart';

class ScaffoldWidget extends StatelessWidget {
  const ScaffoldWidget({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      backgroundColor: AppColors.backgroundDisable,
      body: body,
    );
  }
}
