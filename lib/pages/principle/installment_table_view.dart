import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';

/// Tab "Tabel" di halaman tabel angsuran.
///
/// Dibangun dari sliver (bukan `DataTable2`) supaya menggulir tabel ikut
/// menggulung ringkasan di atasnya dan header kolom tetap menempel di bawah
/// TabBar. Harus berada di dalam `NestedScrollView` yang memakai
/// `SliverOverlapAbsorber`.
class InstallmentTableView extends StatelessWidget {
  const InstallmentTableView({
    super.key,
    required this.results,
    required this.terms,
    required this.totalPrincipal,
    required this.totalInterest,
    required this.totalInstallment,
  });

  final List<CalculateResultModel> results;
  final InstallmentTerms terms;
  final int totalPrincipal;
  final int totalInterest;
  final int totalInstallment;

  /// Lebar minimum tabel; di layar yang lebih sempit tabel digeser horizontal.
  static const double _minWidth = 700;
  static const double _margin = 15;

  /// Lebar kolom "Bulan ke" tetap; kolom lain berbagi sisa lebar dengan bobot
  /// [_flex] (pokok sedikit lebih sempit dari kolom nominal lainnya).
  static const double _monthWidth = 72;
  static const List<int> _flex = [10, 12, 12, 12];

  static const double _rowHeight = 48;
  static const double _headerHeight = 56;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width =
          math.max(_minWidth, constraints.maxWidth - _margin * 2);

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _margin),
        child: SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: CustomScrollView(
            key: const PageStorageKey('installment-table'),
            // Memakai controller dalam NestedScrollView supaya menggulir tabel
            // juga menggulung ringkasan di atasnya.
            primary: true,
            slivers: [
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: _margin),
                sliver: DecoratedSliver(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.panel),
                    boxShadow: AppShadows.soft,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _HeaderDelegate(
                          height: _headerHeight,
                          child: _buildHeader(),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: results.length + 1,
                        itemBuilder: (context, index) => index < results.length
                            ? _buildRow(index)
                            : _buildFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    const TextStyle style = TextStyle(
        color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 14);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.panel)),
      ),
      child: _cells(
        [
          'Bulan\nke',
          terms.principalColumn,
          terms.chargeColumn,
          terms.installmentColumn,
          terms.remainingColumn,
        ].map((label) => Text(label, style: style)).toList(),
        height: _headerHeight,
      ),
    );
  }

  Widget _buildRow(int index) {
    final CalculateResultModel row = results[index];
    final double remain = row.principalTotalRemain ?? 0;
    return _bordered(
      _cells([
        Text('${index + 1}'),
        Text(currencyId.format(row.principal ?? 0)),
        Text(currencyId.format(row.interestResult ?? 0)),
        Text(
          currencyId.format(row.installmentResult ?? 0),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(currencyId.format(remain < 1 ? 0 : remain)),
      ]),
    );
  }

  Widget _buildFooter() {
    const TextStyle bold = TextStyle(fontWeight: FontWeight.bold);
    return _cells([
      const Text('Total', style: bold),
      Text(currencyId.format(totalPrincipal), style: bold),
      Text(currencyId.format(totalInterest), style: bold),
      Text(currencyId.format(totalInstallment), style: bold),
      const Text('--', style: bold),
    ]);
  }

  Widget _bordered(Widget child) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.gridLine)),
        ),
        child: child,
      );

  /// Satu baris: kolom bulan selebar [_monthWidth], sisanya sesuai [_flex].
  Widget _cells(List<Widget> cells, {double height = _rowHeight}) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: _monthWidth,
            child: _padded(cells.first),
          ),
          for (int i = 1; i < cells.length; i++)
            Expanded(flex: _flex[i - 1], child: _padded(cells[i])),
        ],
      ),
    );
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Align(alignment: Alignment.centerLeft, child: child),
      );
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
