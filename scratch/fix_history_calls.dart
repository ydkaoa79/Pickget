import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  var content = file.readAsStringSync();

  // Fix _history.insert calls with broken Korean strings
  content = content.replaceAll("title: '異쒖꽍 泥댄겕 蹂댁긽', amount: 10, date: '諛⑷툑 ??", 
                               "title: '출석 체크 보상', amount: 10, date: '방금 전'");
  
  // Also check for other variants
  content = content.replaceAll("title: '異쒖꽍 泥댄겕 蹂댁긽', amount: 10, date: '방금 전'", 
                               "title: '출석 체크 보상', amount: 10, date: '방금 전'");

  // Fix another potential broken string in PointScreen
  content = content.replaceAll("title: '??딄린 蹂댁긽', amount: 5, date: '1?쒓컙 ??",
                               "title: '걷기 보상', amount: 5, date: '1시간 전'");
  
  // Generic cleanup of common corrupted patterns
  content = content.replaceAll("date: '방금 ??", "date: '방금 전'");
  content = content.replaceAll("date: '1?쒓컙 ??", "date: '1시간 전'");

  file.writeAsStringSync(content);
  print('Fixed history insert calls.');
}
