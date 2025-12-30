import 'package:flutter/material.dart';
import '../../models/zone.dart';
import '../../services/database_helper.dart';
import '../../widgets/common/sprigrig_background.dart';
import '../../widgets/cards/glass_card.dart';
import 'guardian_chat_screen.dart';
import '../setup/guardian_setup_screen.dart';

class GuardianScreen extends StatefulWidget {
  final int zoneId;

  const GuardianScreen({super.key, required this.zoneId});

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Zone? _zone;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final zone = await _db.getZone(widget.zoneId);
    if (mounted) {
      setState(() {
        _zone = zone;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Guardian AI', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_zone != null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GuardianSetupScreen(zone: _zone!),
                ),
              ).then((_) => _loadData()),
            ),
        ],
      ),
      body: SprigrigBackground(
        primaryColor: Colors.deepPurple,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _zone == null
                  ? const Center(child: Text('Zone not found', style: TextStyle(color: Colors.white)))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Card
                          GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.psychology, size: 64, color: Colors.purpleAccent),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Guardian Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.purpleAccent.withOpacity(0.5),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Monitoring system health and optimizing growth.',
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Chat Button
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GuardianChatScreen(zone: _zone!),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat with Guardian'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quick Actions / Status (Placeholder)
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                _buildStatusCard(
                                  icon: Icons.security,
                                  title: 'Security',
                                  status: 'Active',
                                  color: Colors.green,
                                ),
                                _buildStatusCard(
                                  icon: Icons.analytics,
                                  title: 'Analysis',
                                  status: 'Running',
                                  color: Colors.blue,
                                ),
                                _buildStatusCard(
                                  icon: Icons.notifications,
                                  title: 'Alerts',
                                  status: 'None',
                                  color: Colors.grey,
                                ),
                                _buildStatusCard(
                                  icon: Icons.history,
                                  title: 'History',
                                  status: 'View',
                                  color: Colors.orange,
                                  onTap: () {
                                    // Navigate to history
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String status,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text(status, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
