import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  try {
    var bytes = File('assets/lottery_data.xlsx').readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    print('Sheets: ${excel.tables.keys}');
    for (var table in excel.tables.keys) {
      print('Sheet $table maxRows: ${excel.tables[table]?.maxRows}');
    }
    print('Success!');
  } catch (e, st) {
    print('Error: $e');
    print('Stacktrace: $st');
  }
}
