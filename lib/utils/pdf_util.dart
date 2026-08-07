import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/custom_date.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Parameter pembangun PDF. Objek biasa (tanpa closure) supaya bisa dikirim ke
/// isolate lain lewat `compute`.
class PdfBuildParams {
  const PdfBuildParams({
    required this.calculates,
    required this.timestamp,
    required this.typeLabel,
    required this.terms,
    required this.isSharia,
    this.logoBytes,
    this.totalPrincipal,
    this.totalInterest,
    this.totalInstallment,
    this.tieredInterest,
    this.calculateModel,
  });

  final List<CalculateResultModel> calculates;
  final String timestamp;
  final String typeLabel;

  /// Istilah kolom & label sesuai akad, supaya PDF yang dibagikan konsisten
  /// dengan yang dilihat di layar.
  final InstallmentTerms terms;
  final bool isSharia;

  final Uint8List? logoBytes;
  final int? totalPrincipal;
  final int? totalInterest;
  final int? totalInstallment;
  final List<double>? tieredInterest;
  final CalculateModel? calculateModel;
}

class PdfUtil {
  const PdfUtil._();

  static const String filePrefix = 'Tabel-Angsuran';

  static String typeLabelOf(CalculatorType? type) => switch (type) {
        CalculatorType.flat => 'Flat',
        CalculatorType.effective => 'Efektif',
        _ => 'Anuitas',
      };

  /// Nama file yang informatif dan bisa ditebak pengguna, menggantikan nama
  /// acak seperti `principal-483920.pdf`.
  static String suggestedFileName(CalculatorType? type,
      {FinancingContract contract = FinancingContract.conventional}) {
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final label = contract.isSharia ? contract.shortLabel : typeLabelOf(type);
    // Spasi pada nama akad ("Musyarakah MQ") diganti supaya nama berkas aman
    // di seluruh sistem berkas dan aplikasi berbagi.
    return '$filePrefix-${label.replaceAll(' ', '-')}-$stamp.pdf';
  }

  static Future<File> generatePrincipalPDF(
    List<CalculateResultModel> calculates, {
    int? totalPrincipal,
    int? totalInterest,
    int? totalInstallment,
    final List<double>? tieredInterest,
    CalculatorType? type,
    CalculateModel? calculateModel,
    FinancingContract contract = FinancingContract.conventional,
    String? schemeLabel,
  }) async {
    Uint8List? logoBytes;
    try {
      final ByteData bytes = await rootBundle.load('assets/ic_launcher.png');
      logoBytes = bytes.buffer.asUint8List();
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'PDF logo');
    }

    final params = PdfBuildParams(
      calculates: calculates,
      timestamp: DateCustom.timestamp(),
      typeLabel: schemeLabel ?? typeLabelOf(type),
      terms: contract.terms,
      isSharia: contract.isSharia,
      logoBytes: logoBytes,
      totalPrincipal: totalPrincipal,
      totalInterest: totalInterest,
      totalInstallment: totalInstallment,
      tieredInterest: tieredInterest,
      calculateModel: calculateModel,
    );

    // Tabel 30 tahun = 360 baris; membangunnya di isolate terpisah menjaga UI
    // tetap responsif.
    final Uint8List bytes = await compute(buildPrincipalPdfBytes, params);

    // Ditulis ke direktori sementara, bukan folder Downloads: file ini hanya
    // perantara sebelum dibagikan atau disimpan lewat FlutterFileSaver.
    final Directory directory = await getTemporaryDirectory();
    await _cleanOldFiles(directory);

    final file = File(
        '${directory.path}/${suggestedFileName(type, contract: contract)}');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Membuang PDF sementara dari sesi sebelumnya supaya tidak menumpuk.
  static Future<void> _cleanOldFiles(Directory directory) async {
    try {
      final now = DateTime.now();
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.startsWith(filePrefix) || !name.endsWith('.pdf')) continue;
        final stat = await entity.stat();
        if (now.difference(stat.modified) > const Duration(hours: 6)) {
          await entity.delete();
        }
      }
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'PDF cleanup');
    }
  }
}

/// Membangun dokumen PDF. Fungsi top-level supaya bisa dijalankan `compute`.
Future<Uint8List> buildPrincipalPdfBytes(PdfBuildParams params) async {
  final calculates = params.calculates;
  final calculateModel = params.calculateModel;
  final tieredInterest = params.tieredInterest;
  final logobytes = params.logoBytes;
  final terms = params.terms;
  final isSharia = params.isSharia;

  final pw.Document pdf = pw.Document();
  pdf.addPage(pw.MultiPage(
      maxPages: 1000,
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
                child: pw.Row(children: [
              logobytes != null
                  ? pw.Container(
                      margin: const pw.EdgeInsets.only(
                        right: 10,
                      ),
                      child: pw.Image(pw.MemoryImage(logobytes),
                          width: 50, height: 50))
                  : pw.SizedBox(),
              pw.Expanded(
                  child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                      child: pw.Text('Tabel Angsuran',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 16))),
                  pw.Container(child: pw.Text('Kalkulator KPR')),
                ],
              )),
            ])),
            pw.Text(params.timestamp)
          ]),
          pw.SizedBox(height: 15),
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 15),
            child: pw.Row(children: [
              pw.Expanded(
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    pw.Text(
                        "${isSharia ? 'Akad' : 'Jenis'}: ${params.typeLabel}"),
                    if (calculateModel?.initialLoan != null)
                      pw.Text(
                          "${isSharia ? 'Harga Rumah' : 'Jumlah Pinjaman'}: Rp. ${currencyId.format(calculateModel?.initialLoan ?? 0)}"),
                    if (calculateModel?.dpNominal != null)
                      pw.Text(
                          "${isSharia ? 'Uang Muka' : 'DP'}: Rp. ${currencyId.format(calculateModel?.dpNominal ?? 0)}"),
                    pw.Text(
                        "${terms.financing}: Rp. ${currencyId.format(calculateModel?.loan ?? 0)}"),
                  ])),
              pw.Expanded(
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                    // Advanced
                    if (calculateModel?.floatingInterest != null)
                      pw.Text(
                          "Total Waktu Pinjaman: ${currencyId.format(calculateModel?.year ?? 0)} Tahun"),
                    if (calculateModel?.floatingInterest != null &&
                        (tieredInterest ?? []).isEmpty)
                      pw.Text(
                          "Bunga Fix : ${calculateModel?.fixInterest?.toString()}%"),
                    if (calculateModel?.floatingInterest != null &&
                        (tieredInterest ?? []).isEmpty)
                      pw.Text(
                          "Tahun Bunga Fix : ${calculateModel?.fixYear?.toInt()} Tahun"),
                    for (int i = 0; i < (tieredInterest ?? []).length; i++)
                      pw.Text(
                          "Bunga Fix Tahun ke ${i + 1} : ${tieredInterest![i]}%"),
                    if (calculateModel?.floatingInterest != null)
                      pw.Text(
                          "Bunga : ${calculateModel?.floatingInterest?.toString()}%"),

                    // Common
                    if (calculateModel?.floatingInterest == null)
                      pw.Text(
                          "Jangka Waktu (Tahun): ${currencyId.format(calculateModel?.year ?? 0)}"),
                    if (calculateModel?.floatingInterest == null)
                      pw.Text(
                          "${terms.rate} : ${calculateModel?.interest?.toString()}%"),
                  ])),
            ]),
          ),
          pw.Table(
              columnWidths: {
                0: const pw.FixedColumnWidth(50),
              },
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(children: [
                  _headerCell("Bulan ke"),
                  _headerCell(terms.principal),
                  _headerCell(terms.charge),
                  _headerCell(terms.installment),
                  _headerCell(terms.remaining),
                ]),
                for (int i = 0; i < calculates.length; i++)
                  pw.TableRow(children: [
                    pw.Center(
                        child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Text((i + 1).toString()),
                    )),
                    _numberCell(calculates[i].principal),
                    _numberCell(calculates[i].interestResult),
                    _numberCell(calculates[i].installmentResult),
                    _numberCell((calculates[i].principalTotalRemain ?? 0) < 1
                        ? 0
                        : calculates[i].principalTotalRemain),
                  ]),
                pw.TableRow(children: [
                  _headerCell("Total"),
                  _numberCell(params.totalPrincipal ?? 0, bold: true),
                  _numberCell(params.totalInterest ?? 0, bold: true),
                  _numberCell(params.totalInstallment ?? 0, bold: true),
                  pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        child: pw.Text("--",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      )),
                ]),
              ]),
        ];
      }));

  return pdf.save();
}

pw.Widget _headerCell(String text) => pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
    );

pw.Widget _numberCell(num? value, {bool bold = false}) => pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          currencyId.format(value ?? 0),
          style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
        ),
      ),
    );
