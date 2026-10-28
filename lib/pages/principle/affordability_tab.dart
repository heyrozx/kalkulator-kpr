import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/affordability.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/shared/widgets/labeled_number_field.dart';

/// Tab "Kemampuan Bayar" di halaman tabel angsuran: membandingkan angsuran
/// terberat dengan penghasilan pengguna memakai batas rasio cicilan yang umum
/// dipakai bank (30%).
///
/// Harus berada di dalam `NestedScrollView` yang memakai
/// `SliverOverlapAbsorber`, karena isinya menyisipkan `SliverOverlapInjector`.
class AffordabilityTab extends StatefulWidget {
  const AffordabilityTab({super.key, required this.results});

  final List<CalculateResultModel> results;

  @override
  State<AffordabilityTab> createState() => _AffordabilityTabState();
}

class _AffordabilityTabState extends State<AffordabilityTab>
    with AutomaticKeepAliveClientMixin {
  final _incomeController = TextEditingController();
  final _otherDebtController = TextEditingController();

  late final double _installment = highestInstallment(widget.results);

  // Isian tetap ada saat pengguna berpindah ke tab lain lalu kembali.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _incomeController.dispose();
    _otherDebtController.dispose();
    super.dispose();
  }

  Affordability get _affordability => Affordability(
        income: CurrencyFormat.parseNumber(_incomeController.text),
        otherDebt: CurrencyFormat.parseNumber(_otherDebtController.text),
        installment: _installment,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Affordability affordability = _affordability;

    return CustomScrollView(
      key: const PageStorageKey('affordability'),
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 24),
          sliver: SliverList.list(
            children: [
              _Panel(child: _buildInputs()),
              const SizedBox(height: 15),
              _Panel(
                child: affordability.income > 0
                    ? _AffordabilityResult(affordability: affordability)
                    : _buildPlaceholder(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cek Kemampuan Bayar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Bank umumnya menyetujui KPR bila total cicilan tidak lebih dari '
          '30% penghasilan bersih.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        LabeledNumberField(
          controller: _incomeController,
          label: 'Penghasilan Bersih per Bulan (Rp)',
          onChanged: (_) => setState(() {}),
        ),
        LabeledNumberField(
          controller: _otherDebtController,
          label: 'Cicilan Lain per Bulan (Rp)',
          onChanged: (_) => setState(() {}),
          margin: EdgeInsets.zero,
        ),
        const SizedBox(height: 6),
        Text(
          'Opsional: cicilan kendaraan, kartu kredit, paylater, dll.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Isi penghasilan untuk melihat apakah angsuran '
            'Rp ${currencyId.format(_installment)} per bulan masih terjangkau.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

class _AffordabilityResult extends StatelessWidget {
  const _AffordabilityResult({required this.affordability});

  final Affordability affordability;

  Color get _color => switch (affordability.level) {
        AffordabilityLevel.safe => AppColors.success,
        AffordabilityLevel.caution => AppColors.warning,
        AffordabilityLevel.heavy => AppColors.danger,
      };

  String get _message => switch (affordability.level) {
        AffordabilityLevel.safe =>
          'Cicilan masih dalam batas yang umum disetujui bank.',
        AffordabilityLevel.caution =>
          'Masih mungkin disetujui, tapi ruang keuangan Anda cukup sempit. '
              'Pertimbangkan DP lebih besar atau tenor lebih panjang.',
        AffordabilityLevel.heavy =>
          'Cicilan terlalu besar dibanding penghasilan dan umumnya ditolak '
              'bank. Coba turunkan pinjaman atau perpanjang tenor.',
      };

  @override
  Widget build(BuildContext context) {
    final double ratio = affordability.ratio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rasio Cicilan', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${(ratio * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Text(
                affordability.level.label,
                style: TextStyle(color: _color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RatioBar(ratio: ratio, color: _color),
        const SizedBox(height: 12),
        Text(_message, style: const TextStyle(fontSize: 13)),
        const Divider(height: 28),
        _row('Angsuran KPR tertinggi', affordability.installment),
        if (affordability.otherDebt > 0)
          _row('Cicilan lain', affordability.otherDebt),
        _row('Sisa penghasilan', affordability.remainingIncome,
            highlight:
                affordability.remainingIncome < 0 ? AppColors.danger : null),
        _row('Penghasilan minimal (rasio 30%)', affordability.minimumIncome),
      ],
    );
  }

  Widget _row(String label, double value, {Color? highlight}) {
    final String sign = value < 0 ? '-' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '${sign}Rp ${currencyId.format(value.abs())}',
            style: TextStyle(fontWeight: FontWeight.bold, color: highlight),
          ),
        ],
      ),
    );
  }
}

/// Batang rasio 0–60% dengan garis penanda batas aman 30% dan batas 40%.
class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  static const double _scale = 0.6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      double at(double value) => width * (value / _scale).clamp(0.0, 1.0);

      return Column(
        children: [
          SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.gridLine,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: at(ratio),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                for (final limit in const [
                  Affordability.safeRatio,
                  Affordability.cautionRatio
                ])
                  Positioned(
                    left: at(limit) - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: AppColors.surface),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 16,
            child: Stack(
              children: [
                for (final (limit, label) in const [
                  (Affordability.safeRatio, '30%'),
                  (Affordability.cautionRatio, '40%'),
                ])
                  Positioned(
                    left: at(limit) - 14,
                    width: 28,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.panel),
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
