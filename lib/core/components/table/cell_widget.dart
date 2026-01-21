import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/toast_service.dart';
import '../copyable_widget.dart';

class CellWidget extends StatelessWidget {
  const CellWidget({
    super.key,
    this.text,
    this.content,
    this.copyableContent,
    this.enableCopyOnTap = true
  });
  final String? text;
  final Widget? content;
  final String? copyableContent;
  final bool enableCopyOnTap;

  @override
  Widget build(BuildContext context) {
    return content ?? _buildHighlight(context);
  }

  Widget _buildHighlight(BuildContext context) {
    if(enableCopyOnTap) {
      return CopyableWidget(text: text ?? '', copyableContent: copyableContent,);
    }

    return _buildContent();
  }

  //#region UI
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: enableCopyOnTap ? Text(text ?? '') : SelectableText(text ?? ''),
    );
  }
  //#endregion

  //#region ACTION
  Future<void> onTap(BuildContext context) async {
    try {
      if(enableCopyOnTap) {
        await Clipboard.setData(ClipboardData(text: copyableContent ?? ''));
        ToastService.show(context: context, 'Đã copy $copyableContent', type: ToastType.info);
      }
    } catch (error, stackTrace) {
      ToastService.show(context: context, 'Đã có lỗi xảy ra, vui lòng thử lại', type: ToastType.error);
    }
  }
  //#endregion
}
