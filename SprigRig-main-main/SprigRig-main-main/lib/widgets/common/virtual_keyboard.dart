import 'package:flutter/material.dart';

enum VirtualKeyboardType {
  alphanumeric,
  numeric,
}

class VirtualKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onDone;
  final VirtualKeyboardType type;

  const VirtualKeyboard({
    super.key,
    required this.controller,
    required this.onDone,
    this.type = VirtualKeyboardType.alphanumeric,
  });

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  bool _isShifted = false;

  // Alphanumeric Layout
  final List<String> _alphaRow1 = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
  final List<String> _alphaRow2 = ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'];
  final List<String> _alphaRow3 = ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'];
  final List<String> _alphaRow4 = ['z', 'x', 'c', 'v', 'b', 'n', 'm'];

  // Numeric Layout
  final List<String> _numericRow1 = ['1', '2', '3'];
  final List<String> _numericRow2 = ['4', '5', '6'];
  final List<String> _numericRow3 = ['7', '8', '9'];
  final List<String> _numericRow4 = ['.', '0', '-'];

  void _onKeyTap(String key) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;

    String newChar = _isShifted ? key.toUpperCase() : key;
    
    final newText = text.replaceRange(start, end, newChar);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  void _onBackspace() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final int start = selection.start >= 0 ? selection.start : text.length;
    final int end = selection.end >= 0 ? selection.end : text.length;

    if (text.isEmpty) return;

    if (start == end && start > 0) {
      final newText = text.replaceRange(start - 1, start, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 1),
      );
    } else if (start != end) {
      final newText = text.replaceRange(start, end, '');
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // Increased from 8
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) {
                return Text(
                  value.text.isEmpty ? 'Enter text...' : value.text,
                  style: TextStyle(
                    color: value.text.isEmpty ? Colors.white30 : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          if (widget.type == VirtualKeyboardType.alphanumeric) ...[
            _buildRow(_alphaRow1),
            const SizedBox(height: 8),
            _buildRow(_alphaRow2),
            const SizedBox(height: 8),
            _buildRow(_alphaRow3),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: Icons.arrow_upward,
                  isActive: _isShifted,
                  onTap: () => setState(() => _isShifted = !_isShifted),
                ),
                const SizedBox(width: 4),
                ..._alphaRow4.map((key) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _buildKey(key),
                )),
                const SizedBox(width: 4),
                _buildActionButton(
                  icon: Icons.backspace_outlined,
                  onTap: _onBackspace,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildKey(' ', label: 'Space'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Numeric Layout
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildRow(_numericRow1),
                      const SizedBox(height: 8),
                      _buildRow(_numericRow2),
                      const SizedBox(height: 8),
                      _buildRow(_numericRow3),
                      const SizedBox(height: 8),
                      _buildRow(_numericRow4),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.backspace_outlined,
                        onTap: _onBackspace,
                        height: 120, // Increased from 100
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: widget.onDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 48), // Increased from 36
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 32), // Increased icon size
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: _buildKey(key),
      )).toList(),
    );
  }

  Widget _buildKey(String key, {String? label}) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _onKeyTap(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: label != null ? null : 50, // Increased from 36
          height: 60, // Increased from 44
          alignment: Alignment.center,
          child: Text(
            label ?? (_isShifted ? key.toUpperCase() : key),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), // Increased from 18
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap, bool isActive = false, double height = 60}) { // Increased default from 44
    return Material(
      color: isActive ? Colors.blue : Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 60, // Increased from 44
          height: height,
          alignment: Alignment.center,
          child: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 28), // Increased size from 20
        ),
      ),
    );
  }
}
