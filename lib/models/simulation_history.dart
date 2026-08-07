import 'package:hive_ce/hive.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/helpers.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';

/// Skema bunga yang dipakai sebuah simulasi. Menentukan pembangkit tabel
/// angsuran mana yang dipanggil saat riwayat dibuka kembali.
enum SimulationScheme { simple, fixFloating, tiered }

extension SimulationSchemeLabel on SimulationScheme {
  String get label => switch (this) {
        SimulationScheme.simple => 'Bunga Tetap',
        SimulationScheme.fixFloating => 'Fix & Floating',
        SimulationScheme.tiered => 'Berjenjang',
      };
}

/// Satu simulasi tersimpan.
///
/// Yang disimpan hanya **input** dan **ringkasan** — tabel angsuran per bulan
/// (bisa 480 baris) tidak ikut disimpan melainkan dihitung ulang lewat
/// [buildTable] saat riwayat dibuka. Satu record karena itu hanya berukuran
/// ratusan byte, sehingga riwayat ratusan simulasi pun tetap ringan dibaca
/// per halaman.
class SimulationHistory {
  SimulationHistory({
    this.id,
    required this.name,
    required this.type,
    required this.scheme,
    this.initialLoan,
    this.dpNominal,
    required this.loanPlafon,
    required this.year,
    required this.interest,
    this.fixInterest,
    this.fixYear,
    this.floatingInterest,
    this.tieredInterest = const [],
    this.contract = FinancingContract.conventional,
    required this.firstInstallment,
    required this.totalInterest,
    required this.totalPayment,
    required this.createdAt,
  });

  /// Kunci Hive. `null` selama record belum tersimpan; diisi oleh repository
  /// setelah `add`/`get` supaya layar riwayat bisa mengubah nama dan menghapus.
  int? id;

  String name;

  final CalculatorType type;
  final SimulationScheme scheme;

  // --- Input ---
  /// Harga rumah sebelum DP. Hanya terisi dari layar Advanced.
  final double? initialLoan;
  final double? dpNominal;

  /// Pokok pinjaman yang benar-benar diangsur (setelah DP).
  final double loanPlafon;
  final double year;
  final double interest;
  final double? fixInterest;
  final double? fixYear;
  final double? floatingInterest;
  final List<double> tieredInterest;

  /// Akad pembiayaan. Record lama (sebelum KPR Syariah ada) tidak memuat kunci
  /// ini dan otomatis dibaca sebagai konvensional.
  final FinancingContract contract;

  // --- Ringkasan (agar daftar riwayat tidak perlu menghitung ulang) ---
  final double firstInstallment;
  final double totalInterest;
  final double totalPayment;

  final DateTime createdAt;

  factory SimulationHistory.fromCalculation({
    required String name,
    required CalculatorType type,
    required CalculateModel model,
    required InstallmentSummary summary,
    List<double>? tieredInterest,
    FinancingContract contract = FinancingContract.conventional,
  }) {
    final List<double> tiers = tieredInterest ?? const [];
    // Berjenjang diperiksa lebih dulu: layar berjenjang juga mengisi
    // `floatingInterest`, jadi urutan sebaliknya akan salah mengenali skema.
    final SimulationScheme scheme = tiers.isNotEmpty
        ? SimulationScheme.tiered
        : model.floatingInterest != null
            ? SimulationScheme.fixFloating
            : SimulationScheme.simple;

    return SimulationHistory(
      name: name,
      type: type,
      scheme: scheme,
      initialLoan: model.initialLoan,
      dpNominal: model.dpNominal,
      loanPlafon: model.loanPlafon ?? model.loan ?? 0,
      year: model.year ?? 0,
      interest: model.interest ?? 0,
      fixInterest: model.fixInterest,
      fixYear: model.fixYear,
      floatingInterest: model.floatingInterest,
      tieredInterest: tiers,
      contract: contract,
      firstInstallment: summary.firstInstallment,
      totalInterest: summary.totalInterest,
      totalPayment: summary.totalPayment,
      createdAt: DateTime.now(),
    );
  }

  CalculateModel toCalculateModel() => CalculateModel(
        initialLoan: initialLoan,
        dpNominal: dpNominal,
        loanPlafon: loanPlafon,
        loan: loanPlafon,
        year: year,
        interest: interest,
        fixInterest: fixInterest,
        fixYear: fixYear,
        floatingInterest: floatingInterest,
      );

  /// Menghitung ulang tabel angsuran dari input yang tersimpan.
  List<CalculateResultModel> buildTable() {
    final CalculateModel model = toCalculateModel();

    // Murabahah punya pembangkitnya sendiri karena kolom sisa menampilkan sisa
    // harga jual, bukan sisa pokok seperti pada tabel bunga flat. Musyarakah
    // mutanaqisah memakai mesin efektif/anuitas yang sama dengan konvensional,
    // jadi cukup lewat jalur `scheme` di bawah.
    if (contract == FinancingContract.murabahah) {
      return installmentTableMurabahah(model);
    }

    return switch (scheme) {
      SimulationScheme.tiered =>
        installmentTableTiered(type, model, tieredInterest),
      SimulationScheme.fixFloating => installmentTableFixFloating(type, model),
      SimulationScheme.simple => switch (type) {
          CalculatorType.flat => installmentTableFlat(model),
          CalculatorType.effective => installmentTableEffective(model),
          CalculatorType.anuitas => installmentTableAnuitas(model),
        },
    };
  }

  /// Usulan nama saat pengguna menyimpan, mis. "Anuitas 500 jt · 15 thn".
  static String suggestName(
    CalculatorType type,
    CalculateModel model, {
    FinancingContract contract = FinancingContract.conventional,
  }) {
    final double plafon = model.loanPlafon ?? model.loan ?? 0;
    final int years = (model.year ?? 0).round();
    final String prefix = contract.isSharia ? contract.shortLabel : type.label;
    return '$prefix ${CurrencyFormat.compact(plafon)} · $years thn';
  }

  /// Label ringkas untuk chip di daftar riwayat.
  List<String> get badges => [
        if (contract.isSharia) ...[
          contract.shortLabel,
          if (contract == FinancingContract.mmq) mmqPatternOf(type).shortLabel,
        ] else ...[
          type.label,
          scheme.label,
        ],
        '${year.round()} thn',
      ];

  Map<String, dynamic> toMap() => {
        'name': name,
        // Enum disimpan sebagai nama, bukan indeks, supaya menambah/menyusun
        // ulang anggota enum tidak mengubah arti data yang sudah tersimpan.
        'type': type.name,
        'scheme': scheme.name,
        'initialLoan': initialLoan,
        'dpNominal': dpNominal,
        'loanPlafon': loanPlafon,
        'year': year,
        'interest': interest,
        'fixInterest': fixInterest,
        'fixYear': fixYear,
        'floatingInterest': floatingInterest,
        'tieredInterest': tieredInterest,
        'contract': contract.name,
        'firstInstallment': firstInstallment,
        'totalInterest': totalInterest,
        'totalPayment': totalPayment,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory SimulationHistory.fromMap(Map<dynamic, dynamic> map) {
    return SimulationHistory(
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : 'Tanpa nama',
      type: _enumOf(CalculatorType.values, map['type'], CalculatorType.anuitas),
      scheme: _enumOf(
          SimulationScheme.values, map['scheme'], SimulationScheme.simple),
      initialLoan: _nullableDouble(map['initialLoan']),
      dpNominal: _nullableDouble(map['dpNominal']),
      loanPlafon: _double(map['loanPlafon']),
      year: _double(map['year']),
      interest: _double(map['interest']),
      fixInterest: _nullableDouble(map['fixInterest']),
      fixYear: _nullableDouble(map['fixYear']),
      floatingInterest: _nullableDouble(map['floatingInterest']),
      tieredInterest: _doubleList(map['tieredInterest']),
      contract: _enumOf(FinancingContract.values, map['contract'],
          FinancingContract.conventional),
      firstInstallment: _double(map['firstInstallment']),
      totalInterest: _double(map['totalInterest']),
      totalPayment: _double(map['totalPayment']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0),
    );
  }

  static T _enumOf<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  static double _double(Object? raw) {
    final double value = (raw as num?)?.toDouble() ?? 0;
    return value.isFinite ? value : 0;
  }

  static double? _nullableDouble(Object? raw) {
    final double? value = (raw as num?)?.toDouble();
    return value != null && value.isFinite ? value : null;
  }

  static List<double> _doubleList(Object? raw) {
    if (raw is! List) return const [];
    return raw.whereType<num>().map((value) => value.toDouble()).toList();
  }
}

/// Adapter Hive yang menulis record sebagai map.
///
/// Menyimpan map (bukan deretan field berindeks seperti adapter hasil codegen)
/// membuat penambahan field di rilis berikutnya tidak merusak data lama:
/// kunci yang belum ada cukup jatuh ke nilai default di [SimulationHistory.fromMap].
class SimulationHistoryAdapter extends TypeAdapter<SimulationHistory> {
  static const int id = 1;

  @override
  int get typeId => id;

  @override
  SimulationHistory read(BinaryReader reader) =>
      SimulationHistory.fromMap(reader.readMap());

  @override
  void write(BinaryWriter writer, SimulationHistory obj) =>
      writer.writeMap(obj.toMap());
}
