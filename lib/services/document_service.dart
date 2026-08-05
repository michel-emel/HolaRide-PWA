import 'api_client.dart';

/// The four document types the backend accepts. Kept in one place so
/// the UI slots and the API calls can't drift apart.
enum DriverDocType { driverLicence, idCard, registration, insurance }

extension DriverDocTypeApi on DriverDocType {
  /// The exact string the backend's `document_type` field expects.
  String get apiValue {
    switch (this) {
      case DriverDocType.driverLicence:
        return 'driver_licence';
      case DriverDocType.idCard:
        return 'id_card';
      case DriverDocType.registration:
        return 'registration';
      case DriverDocType.insurance:
        return 'insurance';
    }
  }

  static DriverDocType? fromApi(String v) {
    switch (v) {
      case 'driver_licence':
        return DriverDocType.driverLicence;
      case 'id_card':
        return DriverDocType.idCard;
      case 'registration':
        return DriverDocType.registration;
      case 'insurance':
        return DriverDocType.insurance;
    }
    return null;
  }
}

/// One document as the backend reports it (never exposes the raw file
/// path — only its type, kind, and review status).
class DriverDocument {
  final DriverDocType type;
  final String fileType; // 'pdf' | 'image'
  final String status; // pending | approved | rejected
  final DateTime uploadedAt;

  DriverDocument({
    required this.type,
    required this.fileType,
    required this.status,
    required this.uploadedAt,
  });

  static DriverDocument? fromJson(Map<String, dynamic> j) {
    final type = DriverDocTypeApi.fromApi(j['document_type']?.toString() ?? '');
    if (type == null) return null;
    return DriverDocument(
      type: type,
      fileType: j['file_type']?.toString() ?? 'image',
      status: j['status']?.toString() ?? 'pending',
      uploadedAt: DateTime.tryParse(j['uploaded_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// Uploading and listing a vehicle's legal documents (driver licence,
/// ID card, registration, insurance). Documents are OPTIONAL — nothing
/// here gates approval; this just lets a driver complete their file and
/// admin review it.
class DocumentService {
  DocumentService._();
  static final DocumentService instance = DocumentService._();

  final _api = ApiClient.instance;

  /// Current documents for a vehicle, keyed by type for easy slot lookup.
  Future<Map<DriverDocType, DriverDocument>> myDocuments(String vehicleId) async {
    final res = await _api.get('/drivers/me/vehicle/$vehicleId/documents');
    final list = (res as List?) ?? const [];
    final out = <DriverDocType, DriverDocument>{};
    for (final row in list.whereType<Map<String, dynamic>>()) {
      final doc = DriverDocument.fromJson(row);
      if (doc != null) out[doc.type] = doc;
    }
    return out;
  }

  /// Uploads (or replaces) one document. On mobile pass [filePath]; on
  /// web pass [bytes] + [filename] (the browser gives no real path).
  Future<DriverDocument?> upload({
    required String vehicleId,
    required DriverDocType type,
    String? filePath,
    List<int>? bytes,
    String? filename,
  }) async {
    final res = await _api.postMultipart(
      '/drivers/me/vehicle/$vehicleId/documents',
      fields: {'document_type': type.apiValue},
      files: filePath != null ? [MapEntry('file', filePath)] : null,
      fileBytes: (bytes != null)
          ? [MapEntry('file', MapEntry(filename ?? 'document', bytes))]
          : null,
    );
    return DriverDocument.fromJson(res as Map<String, dynamic>);
  }
}