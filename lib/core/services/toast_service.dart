import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class ToastService {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration? duration = const Duration(seconds: 2),
    Alignment alignment = Alignment.topRight, // or Alignment.bottomRight
  }) {
    // remove current toast if any
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.of(context);

    final (bg, icon) = _style(type);

    _entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        backgroundColor: bg,
        icon: icon,
        alignment: alignment,
        onClose: () {
          _timer?.cancel();
          _entry?.remove();
          _entry = null;
        },
      ),
    );

    overlay.insert(_entry!);

    if(duration != null) {
      _timer = Timer(duration, () {
        _entry?.remove();
        _entry = null;
      });
    }
  }

  static void hide() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
  }

  static (Color, IconData) _style(ToastType type) {
    switch (type) {
      case ToastType.success:
        return (Colors.green.shade700, Icons.check_circle);
      case ToastType.error:
        return (Colors.red.shade700, Icons.error);
      case ToastType.warning:
        return (Colors.orange.shade700, Icons.warning);
      case ToastType.info:
      default:
        return (Colors.black87, Icons.info);
    }
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Alignment alignment;
  final VoidCallback onClose;

  const _ToastView({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.alignment,
    required this.onClose,
  });

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    // slide in from right a bit
    _slide = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final isTop = widget.alignment.y <= 0;

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: widget.alignment,
          child: Padding(
            padding: EdgeInsets.only(
              top: isTop ? 16 : 0,
              bottom: isTop ? 0 : 16,
              right: 16,
              left: 16,
            ),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _close,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: widget.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 14,
                              color: Colors.black26,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _close,
                              splashRadius: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
