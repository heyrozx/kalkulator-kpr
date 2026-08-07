import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalkulator_kpr/blocs/purchase_cubit/purchase_cubit.dart';
import 'package:kalkulator_kpr/core/currency_format.dart';
import 'package:kalkulator_kpr/core/custom_date.dart';
import 'package:kalkulator_kpr/core/error_reporter.dart';
import 'package:kalkulator_kpr/core/simulation_history_repository.dart';
import 'package:kalkulator_kpr/core/theme.dart';
import 'package:kalkulator_kpr/models/calculate_model.dart';
import 'package:kalkulator_kpr/models/financing_contract.dart';
import 'package:kalkulator_kpr/models/simulation_history.dart';
import 'package:kalkulator_kpr/pages/premiums/premium_paywall.dart';
import 'package:kalkulator_kpr/pages/principle/principal_table.dart';
import 'package:kalkulator_kpr/shared/widgets/name_input_dialog.dart';
import 'package:kalkulator_kpr/utils/custom_snackbar.dart';

/// Daftar simulasi tersimpan (F-5).
///
/// Riwayat dimuat per halaman dan halaman berikutnya baru diambil ketika
/// pengguna hampir menyentuh dasar daftar, sehingga jumlah record di database
/// tidak memengaruhi waktu buka layar ini.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final SimulationHistoryRepository _repository =
      SimulationHistoryRepository.instance;
  final ScrollController _scrollController = ScrollController();

  final List<SimulationHistory> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    // Diambil sebelum benar-benar mentok supaya halaman berikutnya sudah siap
    // ketika pengguna sampai di dasar daftar.
    if (remaining < 300) _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final SimulationHistoryPage page = await _repository.load(page: _page);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _total = page.total;
        _hasMore = page.hasMore;
        _page++;
      });
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'loadHistory');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _hasMore = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 0;
      _total = 0;
      _hasMore = true;
      _hasError = false;
      _isFirstLoad = true;
    });
    await _loadNextPage();
  }

  void _open(SimulationHistory entry) {
    final List<CalculateResultModel> results = entry.buildTable();
    if (results.isEmpty) {
      CustomSnackbar.show(context,
          title: 'Tidak Bisa Dibuka',
          message: 'Data simulasi ini tidak lengkap.',
          type: SnackbarType.failure);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalTable(
          results: results,
          type: entry.type,
          calculateModel: entry.toCalculateModel(),
          tieredInterest:
              entry.tieredInterest.isEmpty ? null : entry.tieredInterest,
          savedHistoryId: entry.id,
          contract: entry.contract,
        ),
      ),
    );
  }

  Future<void> _rename(SimulationHistory entry) async {
    final String? name = await NameInputDialog.show(
      context,
      title: 'Ubah Nama',
      initialValue: entry.name,
    );

    if (name == null) return;
    try {
      await _repository.rename(entry, name);
      if (mounted) setState(() {});
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'renameHistory');
      if (!mounted) return;
      CustomSnackbar.show(context,
          title: 'Gagal',
          message: 'Nama simulasi gagal diubah.',
          type: SnackbarType.failure);
    }
  }

  Future<void> _delete(SimulationHistory entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Simulasi'),
        content: Text('Hapus "${entry.name}" dari riwayat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.delete(entry);
      if (!mounted) return;
      setState(() {
        _items.remove(entry);
        if (_total > 0) _total--;
      });
      CustomSnackbar.show(context,
          title: 'Terhapus',
          message: '"${entry.name}" dihapus dari riwayat.',
          type: SnackbarType.success);
    } catch (error, stack) {
      ErrorReporter.report(error, stack, hint: 'deleteHistory');
      if (!mounted) return;
      CustomSnackbar.show(context,
          title: 'Gagal',
          message: 'Simulasi gagal dihapus.',
          type: SnackbarType.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Simulasi', style: TextStyle(fontSize: 16)),
        centerTitle: false,
        actions: [
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              if (state is! PurchaseNothing) return const SizedBox();
              return IconButton(
                onPressed: () => showPremiumPaywall(context),
                icon: SizedBox(
                  width: 30,
                  child: Image.asset('assets/premium.png'),
                ),
              );
            },
          ),
          const SizedBox(width: 7),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError && _items.isEmpty) {
      return _Placeholder(
        icon: Icons.error_outline,
        title: 'Riwayat tidak bisa dibaca',
        message: 'Terjadi kesalahan saat membuka penyimpanan riwayat.',
        action: TextButton(onPressed: _refresh, child: const Text('Coba Lagi')),
      );
    }
    if (_items.isEmpty) {
      return _Placeholder(
        icon: Icons.bookmark_border,
        title: 'Belum ada simulasi tersimpan',
        message: 'Buka Tabel Angsuran, lalu ketuk ikon simpan di kanan atas '
            'untuk menyimpan simulasi ke riwayat.',
      );
    }

    return Column(
      children: [
        _buildQuotaBar(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(15, 4, 15, 20),
              // Satu baris tambahan di dasar untuk indikator "memuat lagi".
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return _HistoryTile(
                  entry: _items[index],
                  subtitle: DateCustom.shortDateTime(_items[index].createdAt),
                  onTap: () => _open(_items[index]),
                  onRename: () => _rename(_items[index]),
                  onDelete: () => _delete(_items[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuotaBar() {
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      builder: (context, state) {
        final bool isPremium = state is PurchaseData && state.isPremium;
        final String text = isPremium
            ? '$_total simulasi tersimpan'
            : '$_total dari ${SimulationHistoryRepository.freeLimit} '
                'simulasi tersimpan';

        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              if (!isPremium)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => showPremiumPaywall(context),
                  child:
                      const Text('Tanpa batas', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.subtitle,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final SimulationHistory entry;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Menu simulasi',
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert, color: AppColors.muted),
                    onSelected: (value) =>
                        value == 'rename' ? onRename() : onDelete(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final badge in entry.badges) _Chip(badge),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _row('Angsuran awal',
                  'Rp ${currencyId.format(entry.firstInstallment)}'),
              const SizedBox(height: 4),
              _row(entry.contract.terms.totalCharge.toLowerCase(),
                  'Rp ${currencyId.format(entry.totalInterest)}'),
              const SizedBox(height: 4),
              _row('Total pembayaran',
                  'Rp ${currencyId.format(entry.totalPayment)}'),
              const SizedBox(height: 10),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
