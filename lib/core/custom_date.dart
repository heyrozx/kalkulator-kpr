import 'package:intl/intl.dart';

const idMonths = [
  "Januari",
  "Februari",
  "Maret",
  "April",
  "Mei",
  "Juni",
  "Juli",
  "Agustus",
  "September",
  "Oktober",
  "November",
  "Desember"
];

const idMonthsShort = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "Mei",
  "Jun",
  "Jul",
  "Agu",
  "Sep",
  "Okt",
  "Nov",
  "Des"
];

class DateCustom {
  /// Tanggal & jam singkat berbahasa Indonesia, mis. `7 Agu 2026, 14:05`.
  ///
  /// Dirakit manual, bukan lewat `DateFormat(..., 'id')`, karena format tanggal
  /// berlokal menuntut `initializeDateFormatting` dipanggil lebih dulu dan akan
  /// melempar exception kalau terlewat.
  static String shortDateTime(DateTime date) {
    final String month = idMonthsShort[date.month - 1];
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} $month ${date.year}, $hour:$minute';
  }

  /// DateFormat now in string
  ///
  /// Output : 2022-05-06 12:30:19
  static String timestamp() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);
    return formattedDate;
  }

  /// DateFormat now in string
  ///
  /// Output : 2022-05-06
  static String commonDate() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return formattedDate;
  }

  /// Params string date : yyyy-mm-dd
  ///
  /// Ex. 2022-01-01
  static String id(String date) {
    List<String> listDates = date.split("-");
    // ignore: prefer_interpolation_to_compose_strings
    return "${listDates[2]} ${idMonths[int.parse(listDates[1]) - 1]} ${listDates[0]}";
  }
}
