import 'dart:async';
import 'package:flutter/material.dart';

import 'model/loading_progress.dart';

class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({
    super.key,
    required this.progressStream,
  });

  final Stream<LoadingProgress> progressStream;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  LoadingProgress _p = LoadingProgress.idle;
  StreamSubscription<LoadingProgress>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.progressStream.listen((p) {
      if (!mounted) return;
      setState(() => _p = p);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_p.isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading files', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('${_p.current} / ${_p.total}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_p.fileName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _p.fileName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 14),
                  LinearProgressIndicator(value: _p.ratio),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
