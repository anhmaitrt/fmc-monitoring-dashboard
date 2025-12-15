import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/style/app_text_styles.dart';
import 'package:sidebarx/sidebarx.dart';

import '../style/app_colors.dart';

class SideBarWidget extends StatelessWidget {
  SideBarWidget({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;


  final primaryColor = Color(0xFF685BFF);
  final canvasColor = Color(0xFF2E2E48);
  final scaffoldBackgroundColor = Color(0xFF464667);
  final accentCanvasColor = Color(0xFF3E3E61);
  final white = Colors.white;
  final actionColor = Color(0xFF5F5FA7).withOpacity(0.6);
  final divider = Divider(color: Colors.white.withOpacity(0.3), height: 1);

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: canvasColor,
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: scaffoldBackgroundColor,
        textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        selectedTextStyle: const TextStyle(color: Colors.white),
        hoverTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: canvasColor),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actionColor.withOpacity(0.37),
          ),
          gradient: LinearGradient(
            colors: [accentCanvasColor, canvasColor],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 30,
            )
          ],
        ),
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.white,
          size: 20,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(
          color: canvasColor,
        ),
      ),
      footerDivider: divider,
      headerBuilder: (context, extended) {
        return SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: /*Image.asset('assets/images/avatar.png')*/Center(
              child: Text('Monitoring Board', style: TextStyle(
                // fontFamily: FontFamily.sFPro,
                color: Colors.white,
                fontStyle: FontStyle.normal,
                fontSize: 16,
                // fontWeight: normalWeight,
                // height: _getLineHeight(fontSize: 16.fontSize, lineHeight: 24),
                // letterSpacing: _getLetterSpacing(10),
              ),),
            ),
          ),
        );
      },
      items: [
        SidebarXItem(
          icon: Icons.home,
          label: 'Overview',
          onTap: () {
            debugPrint('Overview');
          },
        ),
        const SidebarXItem(
          icon: Icons.summarize,
          label: 'Tổng khách dùng CGM',
        ),
        // SidebarXItem(
        //   icon: Icons.favorite,
        //   label: 'Favorites',
        //   selectable: false,
        //   onTap: () => _showDisabledAlert(context),
        // ),
        // const SidebarXItem(
        //   iconWidget: FlutterLogo(size: 20),
        //   label: 'Flutter',
        // ),
      ],
    );
  }

  void _showDisabledAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Item disabled for selecting',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}