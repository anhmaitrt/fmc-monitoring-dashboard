import 'package:intl/intl.dart';

final _formatterHHmmddMMyyyy = DateFormat('HH:mm dd/MM/yyyy');
final _formatterHHmm = DateFormat('HH:mm');
final _formatterddMMyyyy = DateFormat('dd/MM/yyyy');

extension EDateTime on DateTime? {
  String get formatHHMMDDMMYYYY => this == null ? '' : _formatterHHmmddMMyyyy.format(this!);
  String get formatddMMyyyy => this == null ? '' : _formatterddMMyyyy.format(this!);

  Duration getGap(String end) {
    if(this == null) return Duration(days: 999);
    final endTime = _formatterHHmmddMMyyyy.parse(end);
    return endTime.difference(this!);
  }
}

extension EStringDateTime on String {
  String onlyHHMM() => _formatterHHmm.parse(this).toString();

  Duration getGap(String end) {
    final startTime = _formatterHHmmddMMyyyy.parse(this);
    return startTime.getGap(end);
  }
}