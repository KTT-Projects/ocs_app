class VolunteerAttachment {
  final int id;
  final int opportunityId;
  final String fileName;
  final String fileUrl;
  final String mimeType;
  final int? fileSize;
  final int uploadedBy;
  final DateTime createdAt;

  const VolunteerAttachment({
    required this.id,
    required this.opportunityId,
    required this.fileName,
    required this.fileUrl,
    required this.mimeType,
    this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  factory VolunteerAttachment.fromJson(Map<String, dynamic> json, String hostUrl) {
    String url = json['file_url'] ?? '';
    if (url.startsWith('/')) {
      url = '$hostUrl$url';
    }
    return VolunteerAttachment(
      id: _parseInt(json['id']),
      opportunityId: _parseInt(json['opportunity_id'] ?? json['opportunityId'] ?? 0),
      fileName: json['file_name'] ?? '',
      fileUrl: url,
      mimeType: json['mime_type'] ?? '',
      fileSize: _parseIntNullable(json['file_size']),
      uploadedBy: _parseInt(json['uploaded_by'] ?? 0),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
