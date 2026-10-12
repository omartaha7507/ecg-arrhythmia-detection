import 'package:ecg_analysis2/Layout/root-layout.dart';
import 'package:ecg_analysis2/Widgets/mat-file-uploader.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const String path = "/";

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RootLayout(
      showAppBar: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monitor_heart_rounded,
                size: 72,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              const Text(
                'ECG Analyzer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload a .mat file to analyze ECG signals\nand classify the heartbeats automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white60),
              ),
              const SizedBox(height: 32),
              MatFileUploader(),
              const SizedBox(height: 16),
              Text(
                'Supported format: MIT-BIH .mat files',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
