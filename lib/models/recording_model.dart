class RecordingModel {
  final int? id;
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int durationMs;
  final int fileSizeBytes;

  RecordingModel({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.durationMs,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'created_at': createdAt.toIso8601String(),
      'duration_ms': durationMs,
      'file_size_bytes': fileSizeBytes,
    };
  }

  factory RecordingModel.fromMap(Map<String, dynamic> map) {
    return RecordingModel(
      id: map['id'] as int?,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      durationMs: map['duration_ms'] as int,
      fileSizeBytes: map['file_size_bytes'] as int,
    );
  }

  RecordingModel copyWith({
    int? id,
    String? filePath,
    String? fileName,
    DateTime? createdAt,
    int? durationMs,
    int? fileSizeBytes,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}