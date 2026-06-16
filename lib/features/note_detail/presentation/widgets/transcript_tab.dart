import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TranscriptTab extends StatelessWidget {
  final String transcript;

  const TranscriptTab({super.key, required this.transcript});

  @override
  Widget build(BuildContext context) {
    if (transcript.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'No transcript available',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SelectableText(
        transcript,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.7,
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
      ),
    );
  }
}
