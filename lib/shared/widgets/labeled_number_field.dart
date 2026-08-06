import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:pattern_formatter/numeric_formatter.dart';

/// Field angka yang dipakai berulang di layar utama dan layar Advanced.
///
/// Sebelumnya setiap field menyalin blok `TextFormField` + `OutlineInputBorder`
/// + `ThousandsFormatter` yang sama (belasan kali di empat file).
class LabeledNumberField extends StatelessWidget {
  const LabeledNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.onChanged,
    this.suffixIcon,
    this.readOnly = false,
    this.decimal = false,
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final bool readOnly;

  /// `true` untuk field persentase (bunga, DP %) yang boleh memuat pecahan.
  final bool decimal;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: decimal
          ? [
              // Field persen tidak memakai pemisah ribuan supaya koma maupun
              // titik bisa dipakai sebagai pemisah desimal, apa pun keyboard
              // yang dipakai pengguna.
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              LengthLimitingTextInputFormatter(6),
            ]
          : [
              ThousandsFormatter(
                allowFraction: false,
                formatter: inputNumberFormat,
              ),
            ],
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      decoration: InputDecoration(
        label: Text(label),
        suffixIcon: suffixIcon,
      ),
    );

    return margin == null ? field : Container(margin: margin, child: field);
  }
}
