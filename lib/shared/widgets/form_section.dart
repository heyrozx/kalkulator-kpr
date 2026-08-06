import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/theme.dart';

/// Judul bagian pada form layar Advanced.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title,
      {super.key, this.topPadding = 32, this.trailing});

  final String title;
  final double topPadding;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: topPadding),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

/// Tombol "Hitung Simulasi" yang menempel di bawah form layar Advanced.
class SubmitBar extends StatelessWidget {
  const SubmitBar(
      {super.key, required this.onPressed, this.label = 'Hitung Simulasi'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: onPressed,
          child: Wrap(
            children: [Text(label), const Icon(Icons.chevron_right)],
          ),
        ),
      ),
    );
  }
}
