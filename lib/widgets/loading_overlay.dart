import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _currentOverlay;

  static void show(BuildContext context) {
    if (_currentOverlay != null) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _currentOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.3),
          ),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  static void hide() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }
}
