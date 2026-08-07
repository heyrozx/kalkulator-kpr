import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/theme.dart';

/// Dialog satu field untuk memberi/mengubah nama simulasi.
///
/// Controller-nya dimiliki oleh dialog ini sendiri supaya baru dibuang setelah
/// [TextField] benar-benar lepas dari widget tree. Membuang controller lewat
/// `showDialog(...).whenComplete(controller.dispose)` terlalu cepat: future
/// showDialog selesai saat `Navigator.pop` dipanggil, sementara dialognya masih
/// tampil selama animasi menutup — hasilnya error "Tried to build dirty widget
/// in the wrong build scope".
class NameInputDialog extends StatefulWidget {
  const NameInputDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.labelText = 'Nama simulasi',
    this.hintText,
    this.allowEmpty = false,
  });

  final String title;
  final String initialValue;
  final String labelText;
  final String? hintText;

  /// Kalau `true`, nama kosong dikembalikan sebagai [initialValue] alih-alih
  /// menahan tombol simpan.
  final bool allowEmpty;

  /// Menampilkan dialog dan mengembalikan nama yang dipilih, atau `null` kalau
  /// dibatalkan.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
    String labelText = 'Nama simulasi',
    String? hintText,
    bool allowEmpty = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => NameInputDialog(
        title: title,
        initialValue: initialValue,
        labelText: labelText,
        hintText: hintText,
        allowEmpty: allowEmpty,
      ),
    );
  }

  @override
  State<NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<NameInputDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _controller.text.trim();
    if (value.isEmpty) {
      // Nama kosong tetap boleh untuk simpan baru: diganti usulan otomatis
      // supaya daftar riwayat tidak pernah berisi baris tanpa judul.
      if (!widget.allowEmpty) return;
      Navigator.pop(context, widget.initialValue);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
