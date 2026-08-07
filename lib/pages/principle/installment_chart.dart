import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';

/// Tab "Grafik" pada layar tabel angsuran (F-3).
///
/// Menjawab pertanyaan yang selama ini hanya bisa dibaca dari baris terakhir
/// tabel: berapa total imbalan yang dibayar ke bank, dan bagaimana komposisi
/// pokok–imbalan bergeser dari tahun ke tahun. Seluruh label mengikuti [terms]
/// supaya hasil akad syariah tidak pernah tertulis "bunga".
class InstallmentChart extends StatelessWidget {
  const InstallmentChart({
    super.key,
    required this.results,
    required this.summary,
    required this.terms,
    required this.openingBalance,
  });

  final List<CalculateResultModel> results;
  final InstallmentSummary summary;
  final InstallmentTerms terms;

  /// Kewajiban di titik nol, sebelum angsuran pertama dibayar.
  final double openingBalance;

  @override
  Widget build(BuildContext context) {
    final List<YearlyInstallment> years = yearlyBreakdown(results);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryCard(summary: summary, terms: terms),
          if (years.isNotEmpty) ...[
            const SizedBox(height: 15),
            _ChartCard(
              title: terms.remaining,
              subtitle: 'Posisi di akhir tiap tahun',
              child: _RemainingLoanChart(
                years: years,
                openingBalance: openingBalance,
                label: terms.remaining,
              ),
            ),
            const SizedBox(height: 15),
            _ChartCard(
              title: terms.compositionTitle,
              subtitle: 'Komposisi yang dibayar tiap tahun',
              legend: _ChartLegend(terms: terms),
              child: _PrincipalInterestChart(years: years, terms: terms),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Kartu ringkasan
// =============================================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.terms});

  final InstallmentSummary summary;
  final InstallmentTerms terms;

  @override
  Widget build(BuildContext context) {
    final int interestPercent = (summary.interestRatio * 100).round();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Pembayaran', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            'Rp ${currencyId.format(summary.totalPayment)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'selama ${summary.months} bulan',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: terms.principal,
                  value: summary.totalPrincipal,
                  color: AppColors.chartPrincipal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: terms.charge,
                  value: summary.totalInterest,
                  color: AppColors.chartInterest,
                  note: '$interestPercent% dari total',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: summary.isVarying
                      ? 'Angsuran Bulan Pertama'
                      : 'Angsuran per Bulan',
                  value: summary.firstInstallment,
                ),
              ),
              if (summary.isVarying) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    label: 'Angsuran Bulan Terakhir',
                    value: summary.lastInstallment,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color,
    this.note,
  });

  final String label;
  final double value;

  /// Warna seri grafik yang bersesuaian. Ditampilkan sebagai titik di samping
  /// teks — identitas tidak pernah dibawa oleh warna teksnya sendiri.
  final Color? color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (color != null) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rp ${currencyId.format(value)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              note!,
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Grafik sisa pinjaman
// =============================================================================

class _RemainingLoanChart extends StatelessWidget {
  const _RemainingLoanChart({
    required this.years,
    required this.openingBalance,
    required this.label,
  });

  final List<YearlyInstallment> years;

  /// Kewajiban sebelum satu pun angsuran dibayar, supaya kurvanya turun dari
  /// nilai penuh dan bukan dari akhir tahun pertama. Dikirim oleh pemanggil
  /// karena isinya berbeda per akad: pokok pinjaman untuk kredit berbunga dan
  /// musyarakah, harga jual untuk murabahah.
  final double openingBalance;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double startingLoan = openingBalance;
    final List<FlSpot> spots = [
      FlSpot(0, startingLoan),
      for (final year in years)
        FlSpot(year.year.toDouble(), max(year.remaining, 0)),
    ];

    final double maxY = _axisMax(startingLoan);
    final double yInterval = _axisInterval(maxY);
    final double xInterval = _yearInterval(years.length);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: years.length.toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: _gridData(yInterval),
          titlesData: _titlesData(
            yInterval: yInterval,
            xInterval: xInterval,
            // Titik 0 adalah kondisi sebelum angsuran pertama, bukan "tahun 0".
            xLabel: (value) => value < 1 ? '' : value.toInt().toString(),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.chartTooltip,
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map((spot) => LineTooltipItem(
                        'Akhir tahun ${spot.x.toInt()}\n'
                        '$label Rp ${currencyId.format(spot.y)}',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.chartPrincipal,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.chartPrincipal.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Grafik pokok vs bunga
// =============================================================================

class _PrincipalInterestChart extends StatelessWidget {
  const _PrincipalInterestChart({required this.years, required this.terms});

  final List<YearlyInstallment> years;
  final InstallmentTerms terms;

  @override
  Widget build(BuildContext context) {
    final double maxTotal =
        years.map((year) => year.total).reduce((a, b) => a > b ? a : b);
    final double maxY = _axisMax(maxTotal);
    final double yInterval = _axisInterval(maxY);
    final double xInterval = _yearInterval(years.length);

    // Celah 2px berwarna latar yang memisahkan segmen pokok dan bunga,
    // dinyatakan dalam satuan data terhadap tinggi area gambar (~180px).
    final double gap = maxY / 90;

    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lebar batang dibatasi 24px; sisa ruang di tiap slot dibiarkan kosong.
          final double slot = (constraints.maxWidth - 46) / years.length;
          final double barWidth = (slot * 0.6).clamp(3.0, 24.0);

          return BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceEvenly,
              gridData: _gridData(yInterval),
              titlesData: _titlesData(
                yInterval: yInterval,
                xInterval: xInterval,
                xLabel: (value) => (value.toInt() + 1).toString(),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.chartTooltip,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final YearlyInstallment year = years[group.x];
                    return BarTooltipItem(
                      'Tahun ${year.year}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '${terms.principalShort} '
                              'Rp ${currencyId.format(year.principal)}\n'
                              '${terms.chargeShort} '
                              'Rp ${currencyId.format(year.interest)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < years.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [_rod(years[i], barWidth, gap)],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  BarChartRodData _rod(YearlyInstallment year, double width, double gap) {
    final double principal = max(year.principal, 0);
    final double total = max(year.total, 0);
    // Celah hanya dipasang kalau segmen bunga masih tersisa sesudah dipotong,
    // supaya batang tahun tanpa bunga tidak berbalik nilainya.
    final double interestStart =
        principal + gap < total ? principal + gap : principal;

    return BarChartRodData(
      toY: total,
      width: width,
      // Warna batang itu sendiri yang terlihat pada celah antar segmen.
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      rodStackItems: [
        BarChartRodStackItem(0, principal, AppColors.chartPrincipal),
        BarChartRodStackItem(interestStart, total, AppColors.chartInterest),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.terms});

  final InstallmentTerms terms;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _LegendItem(
            color: AppColors.chartPrincipal, label: terms.principalShort),
        _LegendItem(color: AppColors.chartInterest, label: terms.chargeShort),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

// =============================================================================
// Bagian bersama kedua grafik
// =============================================================================

FlGridData _gridData(double interval) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: AppColors.gridLine, strokeWidth: 1),
    );

/// [xLabel] menerjemahkan nilai sumbu X menjadi nomor tahun: grafik garis
/// memakai nomor tahun langsung, grafik batang memakai indeks grup yang dimulai
/// dari 0. Mengembalikan string kosong berarti label itu tidak digambar.
FlTitlesData _titlesData({
  required double yInterval,
  required double xInterval,
  required String Function(double value) xLabel,
}) =>
    FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 46,
          interval: yInterval,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            space: 6,
            child: Text(
              CurrencyFormat.compact(value),
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 24,
          interval: xInterval,
          getTitlesWidget: (value, meta) {
            final String label = xLabel(value);
            if (label.isEmpty) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              space: 6,
              child: Text(
                label,
                style: TextStyle(fontSize: 10, color: AppColors.muted),
              ),
            );
          },
        ),
      ),
    );

/// Batas atas sumbu Y: sedikit di atas nilai terbesar supaya ujung batang atau
/// kurva tidak menempel di tepi area gambar.
double _axisMax(double maxValue) => maxValue <= 0 ? 1 : maxValue * 1.08;

/// Jarak antar garis bantu, dibulatkan ke angka "enak dibaca" (1/2/2,5/5 × 10ⁿ)
/// supaya label sumbu tidak berupa angka acak.
double _axisInterval(double maxValue, {int ticks = 4}) {
  if (maxValue <= 0) return 1;
  final double raw = maxValue / ticks;
  final double magnitude = pow(10, (log(raw) / ln10).floor()).toDouble();
  for (final double step in const [1, 2, 2.5, 5]) {
    final double candidate = magnitude * step;
    if (candidate >= raw) return candidate;
  }
  return magnitude * 10;
}

/// Menjarangkan label tahun supaya tidak saling menumpuk pada tenor panjang.
double _yearInterval(int totalYears) =>
    max(1, (totalYears / 8).ceil()).toDouble();

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? legend;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          if (legend != null) ...[
            const SizedBox(height: 10),
            legend!,
          ],
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 4),
          Text(
            'Tahun ke-',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 4,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}
