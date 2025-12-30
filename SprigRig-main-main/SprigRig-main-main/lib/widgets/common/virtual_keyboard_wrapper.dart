import 'package:flutter/material.dart';
import 'virtual_keyboard.dart';

class VirtualKeyboardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool autofocus;
  final int? maxLines;

  const VirtualKeyboardTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.autofocus = false,
    this.maxLines = 1,
    this.textColor,
    this.hintColor,
  });

  final Color? textColor;
  final Color? hintColor;

  void _showKeyboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: VirtualKeyboard(
          controller: controller,
          type: keyboardType == TextInputType.number 
              ? VirtualKeyboardType.numeric 
              : VirtualKeyboardType.alphanumeric,
          onDone: () {
            Navigator.pop(context);
            if (onChanged != null) {
              onChanged!(controller.text);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true, // Prevent system keyboard
      onTap: () => _showKeyboard(context),
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        labelStyle: TextStyle(color: (textColor ?? Colors.white).withOpacity(0.7)),
        hintStyle: TextStyle(color: hintColor ?? (textColor ?? Colors.white).withOpacity(0.3)),
      ),
      style: TextStyle(color: textColor ?? Colors.white),
    );
  }
}

class VirtualKeyboardTextFormField extends FormField<String> {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;

  final int? maxLines;
  final Color? textColor;
  final Color? hintColor;

  VirtualKeyboardTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.maxLines = 1,
    this.textColor,
    this.hintColor,
    super.validator,
  }) : super(
          initialValue: controller.text,
          builder: (FormFieldState<String> state) {
            return VirtualKeyboardTextField(
              controller: controller,
              label: label,
              keyboardType: keyboardType,
              obscureText: obscureText,
              hintText: hintText,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              errorText: state.errorText,
              autofocus: autofocus,
              maxLines: maxLines,
              textColor: textColor,
              hintColor: hintColor,
              onChanged: (value) {
                state.didChange(value);
                if (onChanged != null) {
                  onChanged(value);
                }
              },
            );
          },
        );
}
