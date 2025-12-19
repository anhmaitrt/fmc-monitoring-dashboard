import 'package:intl/intl.dart';

final _formatterHHmmddMMYYYY = DateFormat('HH:mm dd/MM/yyyy');
final _formatterHHmm = DateFormat('HH:mm dd/MM/yyyy');

extension EDateTime on DateTime {
  String get formatHHMMDDMMYYYY => _formatterHHmmddMMYYYY.format(this);

  Duration getGap(String end) {
    final endTime = _formatterHHmmddMMYYYY.parse(end);
    return endTime.difference(this);
  }
}

extension EStringDateTime on String {
  String onlyHHMM() => _formatterHHmm.parse(this).toString();

  Duration getGap(String end) {
    final startTime = _formatterHHmmddMMYYYY.parse(this);
    return startTime.getGap(end);
  }
}