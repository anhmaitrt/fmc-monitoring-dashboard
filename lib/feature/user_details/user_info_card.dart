import 'package:flutter/material.dart';

import '../../core/components/copyable_widget.dart';
import '../../core/utils/extension/string_extension.dart';
import '../../model/user_model.dart';

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    required this.user,
    super.key,
    this.customizeFullName,
    this.note,
    this.actionTitle,
    this.onActionPressed,
    this.enableVIPTag = true,
    this.showId = false,
  });

  final UserModel? user;
  final String? customizeFullName;
  final String? note;
  final String? actionTitle;
  final VoidCallback? onActionPressed;
  final bool enableVIPTag;
  final bool showId;

  @override
  Widget build(BuildContext context) {
    return user == null ? const Text('Không có thông tin khách') : ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                customizeFullName ?? '${user!.fullName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              CopyableWidget(
                text: ' | ${user!.phoneNumber.maskPhone()}',
                copyableContent: user!.phoneNumber,
                padding: EdgeInsets.zero,
              ),
              if(enableVIPTag && user!.isVIP)
                Row(
                  children: [
                    const Text(' | '),
                    Icon(Icons.star, color: Colors.yellow[700], size: 18,),
                  ],
                ),
            ],
          ),
          if(showId)
            CopyableWidget(
              text: user!.userId.maskUuid(),
              copyableContent: user!.userId,
              padding: EdgeInsets.zero,
            ),
          if (!user!.vipNote.isNullOrEmpty)
            Text(
              user!.vipNote ?? '',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 4),
          CopyableWidget(
            text:
                '${user!.platform} | ${user!.platformVersion /*.approxIosFromDarwinKernel()*/} | ${user?.deviceModel} | ${user?.appVersion}',
            copyOnClick: false,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      subtitle: note.isNullOrEmpty ? null : Text(
        note!,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      trailing: actionTitle.isNullOrEmpty ? null : TextButton(
        onPressed: onActionPressed,
        child: Text(actionTitle!),
      ),
    );
  }
}
