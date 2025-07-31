import 'dart:html' as html;

Future<void> downloadFile(String url) async {
  final request = await html.HttpRequest.request(url, responseType: 'blob');
  final blob = request.response as html.Blob;
  final objectUrl = html.Url.createObjectUrl(blob);
  final anchor = html.AnchorElement(href: objectUrl)
    ..download = url.split('/').last;
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(objectUrl);
}
