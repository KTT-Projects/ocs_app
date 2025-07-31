import 'dart:html' as html;

Future<void> downloadFile(String url) async {
  final anchor = html.AnchorElement(href: url)
    ..download = url.split('/').last
    ..target = '_blank';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
