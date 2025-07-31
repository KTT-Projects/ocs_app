import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<void> downloadFile(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last;
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
  } else {
    throw HttpException('Failed to download file: ${response.statusCode}');
  }
}
