import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/wifi_service.dart';
import '../../widgets/common/virtual_keyboard_wrapper.dart';

class WifiSettingsTab extends StatefulWidget {
  const WifiSettingsTab({super.key});

  @override
  State<WifiSettingsTab> createState() => _WifiSettingsTabState();
}

class _WifiSettingsTabState extends State<WifiSettingsTab> {
  final WifiService _wifiService = WifiService.instance;
  List<WifiNetwork> _networks = [];
  bool _isLoading = false;
  bool _isWifiEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkWifiStatus();
  }

  Future<void> _checkWifiStatus() async {
    final enabled = await _wifiService.isWifiEnabled();
    setState(() => _isWifiEnabled = enabled);
    if (enabled) {
      _scanNetworks();
    }
  }

  Future<void> _scanNetworks() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final networks = await _wifiService.scanNetworks();
      if (mounted) {
        setState(() {
          _networks = networks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error scanning networks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connectToNetwork(WifiNetwork network) async {
    String? password;
    
    if (network.isSecure) {
      final controller = TextEditingController();
      password = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text('Connect to ${network.ssid}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VirtualKeyboardTextField(
                controller: controller,
                label: 'Password',
                obscureText: true,
                textColor: Colors.white,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Connect', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

      if (password == null) return; // Cancelled
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecting to ${network.ssid}...')),
      );
      setState(() => _isLoading = true);
    }

    final success = await _wifiService.connectToNetwork(network.ssid, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected successfully!'), backgroundColor: Colors.green),
        );
        _scanNetworks(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _forgetNetwork(WifiNetwork network) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text('Forget ${network.ssid}?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to forget this network?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forget', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _wifiService.forgetNetwork(network.ssid);
      _scanNetworks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildGlassCard(
            child: Row(
              children: [
                const Icon(Icons.wifi, color: Colors.amber),
                const SizedBox(width: 16),
                const Text('Wi-Fi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(
                  value: _isWifiEnabled,
                  activeColor: Colors.amber,
                  onChanged: (val) async {
                    setState(() => _isWifiEnabled = val);
                    await _wifiService.toggleWifi(val);
                    if (val) _scanNetworks();
                  },
                ),
              ],
            ),
          ),
        ),
        if (_isWifiEnabled)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : RefreshIndicator(
                    onRefresh: _scanNetworks,
                    color: Colors.amber,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _networks.length + 1, // +1 for scan button at bottom
                      itemBuilder: (context, index) {
                        if (index == _networks.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: ElevatedButton.icon(
                                onPressed: _scanNetworks,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Scan for Networks'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber.withOpacity(0.2),
                                  foregroundColor: Colors.amber,
                                ),
                              ),
                            ),
                          );
                        }

                        final network = _networks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildGlassCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Icon(
                                network.isSecure ? Icons.wifi_lock : Icons.wifi,
                                color: network.isConnected ? Colors.greenAccent : Colors.white70,
                              ),
                              title: Text(
                                network.ssid,
                                style: TextStyle(
                                  color: network.isConnected ? Colors.greenAccent : Colors.white,
                                  fontWeight: network.isConnected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(Icons.signal_wifi_4_bar, size: 14, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Text('${network.signalStrength}%', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  if (network.isConnected) ...[
                                    const SizedBox(width: 8),
                                    const Text('• Connected', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                                  ],
                                ],
                              ),
                              trailing: network.isConnected
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _forgetNetwork(network),
                                      tooltip: 'Forget Network',
                                    )
                                  : const Icon(Icons.chevron_right, color: Colors.white24),
                              onTap: network.isConnected ? null : () => _connectToNetwork(network),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('Wi-Fi is disabled', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
