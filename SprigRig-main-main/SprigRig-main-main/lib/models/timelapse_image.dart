class TimelapseImage {
  final String path;
  final String thumbnailPath;
  final DateTime capturedAt;
  final int cameraId;

  TimelapseImage({
    required this.path,
    required this.thumbnailPath,
    required this.capturedAt,
    required this.cameraId,
  });
}
