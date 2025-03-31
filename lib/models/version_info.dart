// 模拟版本信息类
class VersionInfo {
  final String version;
  final String releaseNotes;
  final bool forceUpdate;
  final String downloadUrl;

  VersionInfo({
    required this.version,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.downloadUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      releaseNotes: json['releaseNotes'] as String,
      forceUpdate: json['forceUpdate'] as bool,
      downloadUrl: json['downloadUrl'] as String,
    );
  }
}
