import 'package:flutter/material.dart';

class SprigrigKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onSpace;

  const SprigrigKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onSpace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P']),
          const SizedBox(height: 8),
          _buildRow(['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKey('Z'),
              _buildKey('X'),
              _buildKey('C'),
              _buildKey('V'),
              _buildKey('B'),
              _buildKey('N'),
              _buildKey('M'),
              const SizedBox(width: 4),
              _buildActionKey(Icons.backspace_outlined, onDelete, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 8),
          _buildSpaceBar(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onKeyPressed(key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey(IconData icon, VoidCallback onTap, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildSpaceBar() {
    return InkWell(
      onTap: onSpace,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'SPACE',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
