import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/toast_service.dart';

class CopyableWidget extends StatelessWidget {
  const CopyableWidget({
    super.key,
    required this.text,
    this.copyableContent,
    this.copyOnClick = true,
  });

  final String text;
  final bool copyOnClick;
  final String? copyableContent;

  @override
  Widget build(BuildContext context) {
    if(!copyOnClick) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SelectableText(text),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => onTap(context),
        hoverColor: Colors.blue.withOpacity(0.08),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(padding: const EdgeInsets.all(8), child: Text(text));
  }

  //#region ACTION
  Future<void> onTap(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: copyableContent ?? text));
      ToastService.show(
        context: context,
        'Đã copy ${copyableContent ?? text}',
        type: ToastType.info,
      );
    } catch (error, stackTrace) {
      ToastService.show(
        context: context,
        'Đã có lỗi xảy ra, vui lòng thử lại',
        type: ToastType.error,
      );
    }
  }

  //#endregion
}
