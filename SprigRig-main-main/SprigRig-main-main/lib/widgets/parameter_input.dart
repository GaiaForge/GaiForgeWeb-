// lib/widgets/parameter_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ParameterInput extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final String? unit;
  final String? helperText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool required;
  final IconData? icon;
  final Widget? suffix;
  final int? maxLines;
  final int? minLines;

  const ParameterInput({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.unit,
    this.helperText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.icon,
    this.suffix,
    this.maxLines = 1,
    this.minLines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? Colors.grey.shade700 : Colors.grey.shade500,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(color: Colors.red.shade600, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Input field
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            suffixText: unit,
            suffix: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
        ),
      ],
    );
  }
}

class NumberParameterInput extends StatelessWidget {
  final String label;
  final double? value;
  final double? min;
  final double? max;
  final String? unit;
  final String? helperText;
  final int decimals;
  final ValueChanged<double?>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool required;
  final IconData? icon;

  const NumberParameterInput({
    super.key,
    required this.label,
    this.value,
    this.min,
    this.max,
    this.unit,
    this.helperText,
    this.decimals = 1,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ParameterInput(
      label: label,
      value: value?.toStringAsFixed(decimals),
      unit: unit,
      helperText: helperText,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [
        if (decimals > 0)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: (text) {
        final parsedValue = double.tryParse(text);
        if (parsedValue != null) {
          if (min != null && parsedValue < min!) return;
          if (max != null && parsedValue > max!) return;
        }
        onChanged?.call(parsedValue);
      },
      validator:
          validator ??
          (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            final parsedValue = double.tryParse(value ?? '');
            if (value != null && value.isNotEmpty && parsedValue == null) {
              return 'Please enter a valid number';
            }
            if (parsedValue != null) {
              if (min != null && parsedValue < min!) {
                return 'Value must be at least $min';
              }
              if (max != null && parsedValue > max!) {
                return 'Value must be at most $max';
              }
            }
            return null;
          },
      enabled: enabled,
      required: required,
      icon: icon,
    );
  }
}

class DropdownParameterInput<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String? helperText;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final bool required;
  final IconData? icon;

  const DropdownParameterInput({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.helperText,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.required = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? Colors.grey.shade700 : Colors.grey.shade500,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(color: Colors.red.shade600, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Dropdown field
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            helperText: helperText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
        ),
      ],
    );
  }
}
