import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/toast_service.dart';

class CellWidget extends StatelessWidget {
  const CellWidget({
    super.key,
    required this.text,
    this.enableCopyOnTap = true
  });
  final String text;
  final bool enableCopyOnTap;

  @override
  Widget build(BuildContext context) {
    return _buildHighlight(context);
  }

  Widget _buildHighlight(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => onTap(context),
        hoverColor: Colors.blue.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text),
        ),
      ),
    );
  }

  //#region ACTION
  Future<void> onTap(BuildContext context) async {
    try {
      print('Copy $text, $enableCopyOnTap');
      if(enableCopyOnTap) {
        await Clipboard.setData(ClipboardData(text: text));
        ToastService.show(context, 'Đã copy $text', type: ToastType.info);
      }
    } catch (error, stackTrace) {
      ToastService.show(context, 'Đã có lỗi xảy ra, vui lòng thử lại', type: ToastType.error);
    }
  }
  //#endregion
}
