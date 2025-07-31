import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';

Future<void> downloadFile(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final tempDir = await getTemporaryDirectory();
    final fileName = url.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);
    await GallerySaver.saveImage(file.path);
  } else {
    throw HttpException('Failed to download file: ${response.statusCode}');
  }
}
