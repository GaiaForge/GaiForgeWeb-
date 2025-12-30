import 'package:flutter/material.dart';
import '../../models/io_channel.dart';
import '../../services/database_helper.dart';

class IoSelector extends StatefulWidget {
  final String label;
  final List<String> allowedTypes; // e.g. ['relay'], ['ai_4_20', 'ai_0_10']
  final int? selectedIoId;
  final Function(int?) onChanged;
  final bool isInput; // Filter for inputs or outputs

  const IoSelector({
    super.key,
    required this.label,
    required this.allowedTypes,
    this.selectedIoId,
    required this.onChanged,
    required this.isInput,
  });

  @override
  State<IoSelector> createState() => _IoSelectorState();
}

class _IoSelectorState extends State<IoSelector> {
  final DatabaseHelper _db = DatabaseHelper();
  List<IoChannel> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _isLoading = true);
    // Fetch all channels
    final allChannels = await _db.getAllIoChannels();
    
    // Filter by direction (Input/Output) and Type
    final filtered = allChannels.where((c) {
      if (c.isInput != widget.isInput) return false;
      if (widget.allowedTypes.isNotEmpty && !widget.allowedTypes.contains(c.type)) return false;
      return true;
    }).toList();

    setState(() {
      _channels = filtered;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Find selected channel object if any
    final selectedChannel = _channels.where((c) => c.id == widget.selectedIoId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showSelectionDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isInput ? Icons.input : Icons.output,
                  color: widget.isInput ? Colors.greenAccent : Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedChannel != null 
                        ? _formatChannelName(selectedChannel)
                        : 'Select ${widget.isInput ? "Input" : "Output"}',
                    style: TextStyle(
                      color: selectedChannel != null ? Colors.white : Colors.white38,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatChannelName(IoChannel c) {
    String source = c.moduleNumber == 1 ? 'Relay Board' : 'Hub #${c.moduleNumber - 100}';
    return '$source - Ch ${c.channelNumber} (${c.type?.toUpperCase() ?? "UNK"})';
  }

  Future<void> _showSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Select ${widget.label}', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _channels.length,
            itemBuilder: (context, index) {
              final channel = _channels[index];
              final isSelected = channel.id == widget.selectedIoId;
              final isReserved = channel.isAssigned && !isSelected; // Reserved by someone else

              return ListTile(
                enabled: !isReserved,
                leading: Icon(
                  widget.isInput ? Icons.input : Icons.output,
                  color: isReserved ? Colors.grey : (widget.isInput ? Colors.greenAccent : Colors.orangeAccent),
                ),
                title: Text(
                  _formatChannelName(channel),
                  style: TextStyle(
                    color: isReserved ? Colors.grey : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: isReserved 
                    ? Text('Reserved by ${channel.assignedTo ?? "Unknown"}', style: const TextStyle(color: Colors.redAccent))
                    : Text(channel.name ?? 'Available', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: isReserved ? null : () {
                  widget.onChanged(channel.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onChanged(null); // Clear selection
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
