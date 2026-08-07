import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/theme.dart';

class ShariaSummaryRow {
  const ShariaSummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;

  /// Angka kunci akad (harga jual, angsuran) ditebalkan dan diberi warna merek.
  final bool emphasized;
}

/// Ringkasan yang muncul di form syariah begitu inputnya lengkap.
///
/// Angka-angka ini — harga jual pada murabahah, angsuran pertama & terakhir
/// pada musyarakah — adalah yang paling dicari pengguna, jadi ditampilkan
/// sebelum ia perlu membuka tabel angsuran.
class ShariaSummaryCard extends StatelessWidget {
  const ShariaSummaryCard({super.key, required this.rows, this.note});

  final List<ShariaSummaryRow> rows;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows) ...[
            if (row != rows.first) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: row.emphasized
                          ? AppColors.onSurface
                          : AppColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Rp ${currencyId.format(row.value)}',
                  style: TextStyle(
                    fontSize: row.emphasized ? 15 : 13,
                    fontWeight: FontWeight.bold,
                    color: row.emphasized
                        ? AppColors.primary
                        : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(
              note!,
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
