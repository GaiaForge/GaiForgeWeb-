import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../widgets/common/app_background.dart';

class FertigationDetailScreen extends StatelessWidget {
  final Zone zone;

  const FertigationDetailScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fertigation Monitor', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insights, size: 64, color: Colors.tealAccent.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Fertigation History & Analytics',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Charts for pH and EC trends will appear here.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
