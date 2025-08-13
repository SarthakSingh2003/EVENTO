import 'package:flutter/material.dart';
import '../../../core/utils/constants.dart';

class ScannerControls extends StatelessWidget {
  final VoidCallback? onScan;
  final VoidCallback? onFlash;
  final bool isFlashOn;

  const ScannerControls({
    super.key,
    this.onScan,
    this.onFlash,
    this.isFlashOn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: onFlash,
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              size: 32,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: onScan,
            icon: const Icon(
              Icons.qr_code_scanner,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 