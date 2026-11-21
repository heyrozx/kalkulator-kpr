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
///
/// Lebar tiap kolom diukur dari isi terpanjangnya (angka maupun kata di
/// judul kolom). Sebelumnya tabel dipaksa minimal 700 px lalu dibagi rata per
/// bobot, sehingga muncul ruang kosong lebar di antara kolom.
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

  static const double _margin = 15;

  /// Jarak antara TabBar dan header kolom saat header menempel. Tanpa ini
  /// header terlihat menempel langsung pada garis bawah TabBar.
  static const double _stickyGap = 8;

  static const double _cellPadding = 12;
  static const double _rowHeight = 48;
  static const double _headerHeight = 56;

  static const TextStyle _headerStyle = TextStyle(
      color: AppColors.onPrimary, fontWeight: FontWeight.bold, fontSize: 14);
  static const TextStyle _bold = TextStyle(fontWeight: FontWeight.bold);

  List<String> get _headers => [
        'Bulan\nke',
        terms.principalColumn,
        terms.chargeColumn,
        terms.installmentColumn,
        terms.remainingColumn,
      ];

  String _remainText(CalculateResultModel row) {
    final double remain = row.principalTotalRemain ?? 0;
    return currencyId.format(remain < 1 ? 0 : remain);
  }

  /// Lebar tiap kolom: teks terpanjang di kolom itu ditambah padding sel.
  ///
  /// Judul kolom diukur per kata karena boleh turun ke baris kedua — judul
  /// panjang seperti "Sisa Harga Jual" tidak boleh membuat kolomnya melebar.
  List<double> _measureColumns(BuildContext context) {
    final TextStyle base = DefaultTextStyle.of(context).style;
    final TextScaler scaler = MediaQuery.textScalerOf(context);

    double measure(String text, TextStyle style) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final double width = painter.width;
      painter.dispose();
      return width;
    }

    // Angka terpanjang di tiap kolom. Panjang karakter dipakai untuk memilih
    // kandidat supaya tidak perlu mengukur ratusan baris satu per satu.
    String longest(Iterable<String> values) => values.fold(
        '', (best, value) => value.length > best.length ? value : best);

    final List<(String, TextStyle)> widest = [
      ('${results.length}', const TextStyle()),
      (
        longest([
          ...results.map((r) => currencyId.format(r.principal ?? 0)),
          currencyId.format(totalPrincipal),
        ]),
        _bold
      ),
      (
        longest([
          ...results.map((r) => currencyId.format(r.interestResult ?? 0)),
          currencyId.format(totalInterest),
        ]),
        _bold
      ),
      (
        longest([
          ...results.map((r) => currencyId.format(r.installmentResult ?? 0)),
          currencyId.format(totalInstallment),
        ]),
        _bold
      ),
      (longest(results.map(_remainText)), const TextStyle()),
    ];

    final List<String> headers = _headers;
    return [
      for (int i = 0; i < headers.length; i++)
        math.max(
              // Kolom pertama juga memuat kata "Total" di baris terakhir.
              math.max(measure(widest[i].$1, widest[i].$2),
                  i == 0 ? measure('Total', _bold) : 0),
              headers[i]
                  .split(RegExp(r'\s+'))
                  .map((word) => measure(word, _headerStyle))
                  .fold<double>(0, math.max),
            ) +
            _cellPadding * 2 +
            // Cadangan kecil untuk pembulatan subpiksel saat render.
            2,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<double> natural = _measureColumns(context);
    final double naturalWidth = natural.fold(0, (a, b) => a + b);

    return LayoutBuilder(builder: (context, constraints) {
      final double available = constraints.maxWidth - _margin * 2;
      // Di layar yang lebih lebar dari isi tabel, sisa lebar dibagi rata ke
      // kolom nominal supaya panel tetap selebar layar; kalau lebih sempit,
      // tabel digeser horizontal.
      final double extra = math.max(0, available - naturalWidth);
      final List<double> widths = [
        natural.first,
        for (final double width in natural.skip(1))
          width + extra / (natural.length - 1),
      ];
      final double width = naturalWidth + extra;

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
                // Jarak atas total tetap 15: sisanya diisi celah header.
                padding: const EdgeInsets.only(
                    top: _margin - _stickyGap, bottom: _margin),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _HeaderDelegate(
                        height: _headerHeight,
                        gap: _stickyGap,
                        child: _buildHeader(widths),
                      ),
                    ),
                    DecoratedSliver(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(AppRadius.panel)),
                        boxShadow: AppShadows.soft,
                      ),
                      sliver: SliverList.builder(
                        itemCount: results.length + 1,
                        itemBuilder: (context, index) => index < results.length
                            ? _buildRow(index, widths)
                            : _buildFooter(widths),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(List<double> widths) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.panel)),
      ),
      child: _cells(
        _headers.map((label) => Text(label, style: _headerStyle)).toList(),
        widths,
        height: _headerHeight,
      ),
    );
  }

  Widget _buildRow(int index, List<double> widths) {
    final CalculateResultModel row = results[index];
    return _bordered(
      _cells([
        Text('${index + 1}'),
        Text(currencyId.format(row.principal ?? 0)),
        Text(currencyId.format(row.interestResult ?? 0)),
        Text(currencyId.format(row.installmentResult ?? 0), style: _bold),
        Text(_remainText(row)),
      ], widths),
    );
  }

  Widget _buildFooter(List<double> widths) {
    return _cells([
      const Text('Total', style: _bold),
      Text(currencyId.format(totalPrincipal), style: _bold),
      Text(currencyId.format(totalInterest), style: _bold),
      Text(currencyId.format(totalInstallment), style: _bold),
      const Text('--', style: _bold),
    ], widths);
  }

  Widget _bordered(Widget child) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.gridLine)),
        ),
        child: child,
      );

  Widget _cells(List<Widget> cells, List<double> widths,
      {double height = _rowHeight}) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _cellPadding),
                child: Align(alignment: Alignment.centerLeft, child: cells[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header kolom yang menempel. Di atasnya ada celah berwarna latar halaman,
/// sehingga saat menempel, baris yang tergulung di bawahnya tertutup celah
/// itu dan header terlihat berjarak dari TabBar.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate(
      {required this.height, required this.gap, required this.child});

  final double height;
  final double gap;
  final Widget child;

  @override
  double get minExtent => height + gap;

  @override
  double get maxExtent => height + gap;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: EdgeInsets.only(top: gap),
          child: SizedBox(height: height, child: child),
        ),
      );

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) =>
      oldDelegate.child != child ||
      oldDelegate.height != height ||
      oldDelegate.gap != gap;
}
