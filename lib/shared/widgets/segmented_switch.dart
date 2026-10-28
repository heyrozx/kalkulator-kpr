import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/theme.dart';

/// Switch bersegmen berbentuk pil: satu "thumb" ungu bergeser ke pilihan yang
/// aktif. Dipakai menggantikan `TabBar` untuk memilih metode bunga di beranda,
/// karena isinya hanya mengganti mode perhitungan, bukan berpindah halaman.
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 34,
    this.segmentWidth = 80,
  });

  final List<({T value, String label})> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  /// Lebar tiap segmen. Switch tidak merentang selebar layar supaya tetap
  /// ringkas di bawah judul.
  final double segmentWidth;

  static const Duration _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final int selectedIndex =
        segments.indexWhere((segment) => segment.value == selected);
    final double radius = height / 2;

    return Container(
      height: height,
      width: segmentWidth * segments.length + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: _duration,
            curve: Curves.easeOutCubic,
            // Petakan indeks 0..n-1 ke rentang -1..1 milik Alignment.x.
            alignment: Alignment(
              segments.length == 1
                  ? 0
                  : -1 + 2 * selectedIndex / (segments.length - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / segments.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(child: _buildSegment(context, segment, radius)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
      BuildContext context, ({T value, String label}) segment, double radius) {
    final bool isSelected = segment.value == selected;
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: isSelected ? null : () => onChanged(segment.value),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: _duration,
            // Digabung dengan gaya warisan supaya font tema tetap terpakai;
            // AnimatedDefaultTextStyle mengganti gaya secara utuh.
            style: DefaultTextStyle.of(context).style.merge(TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.onPrimary : AppColors.muted,
                )),
            child: Text(segment.label),
          ),
        ),
      ),
    );
  }
}
