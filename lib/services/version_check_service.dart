import 'dart:async';
import 'dart:math' as math;

import '../models/version_info.dart';

// 模拟版本检查服务
class VersionCheckService {
  // 当前应用版本
  static const String currentVersion = '1.0.0';

  // 模拟 API 请求，检查是否有新版本
  static Future<VersionInfo?> checkForUpdates() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 1));

    // 随机决定是否有新版本 (50% 的概率)
    if (math.Random().nextBool()) {
      // 模拟返回新版本信息
      return VersionInfo(
        version: '1.1.0',
        releaseNotes: '1. 修复了一些已知问题\n2. 优化了用户界面\n3. 添加了新功能',
        forceUpdate: false, // 随机决定是否强制更新
        downloadUrl: 'https://example.com/download',
      );
    }

    // 没有新版本
    return null;
  }

  // 比较版本号，检查是否需要更新
  static bool needsUpdate(String currentVersion, String newVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = newVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < math.min(current.length, latest.length); i++) {
      if (latest[i] > current[i]) {
        return true;
      } else if (latest[i] < current[i]) {
        return false;
      }
    }

    return latest.length > current.length;
  }
}
