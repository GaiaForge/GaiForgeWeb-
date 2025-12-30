import 'package:flutter/material.dart';

class GaiaNumPad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  const GaiaNumPad({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildRow(['.', '0', 'DEL']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    final isSpecial = key == 'DEL' || key == '.';
    
    return InkWell(
      onTap: () {
        if (key == 'DEL') {
          onDelete();
        } else {
          onKeyPressed(key);
        }
      },
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSpecial ? Colors.white10 : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: Colors.white.withOpacity(isSpecial ? 0.2 : 0.1),
          ),
        ),
        child: key == 'DEL'
            ? const Icon(Icons.backspace_outlined, color: Colors.redAccent, size: 20)
            : Text(
                key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
      ),
    );
  }
}
