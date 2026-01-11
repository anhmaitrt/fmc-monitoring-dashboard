import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fmc_monitoring_dashboard/core/components/scaffold_widget.dart';

class ExternalLogReaderScreen extends StatelessWidget {
  const ExternalLogReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      // showBackButton: true,
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://luugiakhanh689.github.io/portal_log/')),
      ),
    );
  }
}
