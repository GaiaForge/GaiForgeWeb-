import 'dart:io';

// lib/models/image_info.dart
class ImageInfo {
  final int id;
  final int cameraId;
  final int growId;
  final String filePath;
  final String? thumbnailPath;
  final int timestamp;
  final int growDay;
  final int growHour;
  final String? notes;
  final int createdAt;
  File get file => File(filePath);

  ImageInfo({
    required this.id,
    required this.cameraId,
    required this.growId,
    required this.filePath,
    this.thumbnailPath,
    required this.timestamp,
    required this.growDay,
    required this.growHour,
    this.notes,
    required this.createdAt,
  });

  factory ImageInfo.fromMap(Map<String, dynamic> map) {
    return ImageInfo(
      id: map['id'] as int,
      cameraId: map['camera_id'] as int,
      growId: map['grow_id'] as int,
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      timestamp: map['timestamp'] as int,
      growDay: map['grow_day'] as int,
      growHour: map['grow_hour'] as int,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'camera_id': cameraId,
      'grow_id': growId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'timestamp': timestamp,
      'grow_day': growDay,
      'grow_hour': growHour,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  // Helper methods
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  DateTime get createdDateTime => DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

  String get fileName => filePath.split('/').last;
  String? get thumbnailFileName => thumbnailPath?.split('/').last;

  // Time of day string (e.g., "14:30")
  String get timeOfDay {
    final hour = growHour.toString().padLeft(2, '0');
    final minute = ((timestamp % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Growth stage string (e.g., "Day 15, Hour 14")
  String get growthStage => 'Day $growDay, Hour $growHour';

  // File size helper (you'll need to implement this based on your file system)
  Future<int> getFileSize() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Check if files exist
  Future<bool> fileExists() async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<bool> thumbnailExists() async {
    if (thumbnailPath == null) return false;
    try {
      final file = File(thumbnailPath!);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Human readable file size
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Copy with method
  ImageInfo copyWith({
    int? id,
    int? cameraId,
    int? growId,
    String? filePath,
    String? thumbnailPath,
    int? timestamp,
    int? growDay,
    int? growHour,
    String? notes,
    int? createdAt,
  }) {
    return ImageInfo(
      id: id ?? this.id,
      cameraId: cameraId ?? this.cameraId,
      growId: growId ?? this.growId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      timestamp: timestamp ?? this.timestamp,
      growDay: growDay ?? this.growDay,
      growHour: growHour ?? this.growHour,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Image metadata for additional information
class ImageMetadata {
  final String? cameraModel;
  final String? resolution;
  final Map<String, dynamic>? exifData;
  final double? fileSize;
  final String? compression;

  ImageMetadata({
    this.cameraModel,
    this.resolution,
    this.exifData,
    this.fileSize,
    this.compression,
  });

  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      cameraModel: json['camera_model'] as String?,
      resolution: json['resolution'] as String?,
      exifData: json['exif_data'] as Map<String, dynamic>?,
      fileSize: (json['file_size'] as num?)?.toDouble(),
      compression: json['compression'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'camera_model': cameraModel,
      'resolution': resolution,
      'exif_data': exifData,
      'file_size': fileSize,
      'compression': compression,
    };
  }
}

// Image collection for time-lapse sequences
class ImageSequence {
  final int growId;
  final int? cameraId;
  final List<ImageInfo> images;
  final DateTime startDate;
  final DateTime endDate;
  final String sequenceType; // daily, hourly, custom

  ImageSequence({
    required this.growId,
    this.cameraId,
    required this.images,
    required this.startDate,
    required this.endDate,
    this.sequenceType = 'daily',
  });

  int get imageCount => images.length;
  int get daysSpanned => endDate.difference(startDate).inDays + 1;

  List<ImageInfo> get sortedImages => List.from(images)..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  // Get images for a specific day
  List<ImageInfo> getImagesForDay(int day) {
    return images.where((img) => img.growDay == day).toList();
  }

  // Get images within a date range
  List<ImageInfo> getImagesInRange(DateTime start, DateTime end) {
    final startTimestamp = start.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = end.millisecondsSinceEpoch ~/ 1000;
    return images.where((img) => img.timestamp >= startTimestamp && img.timestamp <= endTimestamp).toList();
  }
}