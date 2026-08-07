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

  /// Ukuran ringkas yang dipakai semua layar kalkulator: tinggi field, teks, dan
  /// label sedikit lebih kecil dari baku Material supaya form, tombol, dan hasil
  /// muat dalam satu layar tanpa menggulir.
  static const TextStyle _textStyle = TextStyle(fontSize: 15);
  static const TextStyle _labelStyle = TextStyle(fontSize: 14);
  static const TextStyle _errorStyle = TextStyle(fontSize: 11);
  static const EdgeInsets _contentPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 16);

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
      style: _textStyle,
      decoration: InputDecoration(
        label: Text(label),
        suffixIcon: suffixIcon,
        // `isDense` sengaja tidak dipakai: tingginya jadi terlalu pendek untuk
        // field yang sering diketik. Cukup padding & ukuran teks yang dirapatkan.
        labelStyle: _labelStyle,
        errorStyle: _errorStyle,
        contentPadding: _contentPadding,
      ),
    );

    return margin == null ? field : Container(margin: margin, child: field);
  }
}
