import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

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
        forceUpdate: math.Random().nextBool(), // 随机决定是否强制更新
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ShowCaseWidget(
        disableBarrierInteraction: true, // 禁用背景点击关闭
        builder: (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _lastItemKey = GlobalKey();
  static const String _hasSeenShowcaseKey = 'has_seen_showcase';
  bool _hasSeenShowcase = false;
  bool _isCheckingForUpdates = true; // 标记是否正在检查更新
  // 移除未使用的 _newVersion 字段

  @override
  void initState() {
    super.initState();
    // 先检查更新，然后再检查是否显示引导
    _checkForUpdatesFirst();
  }

  // 先检查更新，确保更新弹窗在引导之前显示
  Future<void> _checkForUpdatesFirst() async {
    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      final newVersion = await VersionCheckService.checkForUpdates();
      if (newVersion != null && 
          VersionCheckService.needsUpdate(
            VersionCheckService.currentVersion, 
            newVersion.version
          )) {
        // 显示更新弹窗
        if (mounted) {
          await _showUpdateDialog(newVersion);
        }
      }
    } catch (e) {
      debugPrint('版本检查失败: $e');
    } finally {
      // 无论是否有更新，都标记检查完成
      setState(() {
        _isCheckingForUpdates = false;
      });
      
      // 检查更新完成后，再检查是否显示引导
      _checkIfShowcaseWasSeen();
    }
  }

  // 显示更新弹窗
  Future<void> _showUpdateDialog(VersionInfo version) async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: !version.forceUpdate, // 强制更新时不允许点击外部关闭
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          // 强制更新时禁止返回键关闭对话框
          onWillPop: () async => !version.forceUpdate,
          child: AlertDialog(
            title: Text('发现新版本 ${version.version}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '更新内容:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(version.releaseNotes),
                ],
              ),
            ),
            actions: <Widget>[
              if (!version.forceUpdate)
                TextButton(
                  child: const Text('稍后再说'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              TextButton(
                child: const Text('立即更新'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // 这里可以添加跳转到下载页面或应用商店的逻辑
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('正在前往下载页面: ${version.downloadUrl}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkIfShowcaseWasSeen() async {
    // 如果正在检查更新，则不显示引导
    if (_isCheckingForUpdates) return;
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenShowcase = prefs.getBool(_hasSeenShowcaseKey) ?? false;
    });

    if (!_hasSeenShowcase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isCheckingForUpdates) {
            ShowCaseWidget.of(context).startShowCase([
              _lastItemKey,
            ]);
          }
        });
      });
    }
  }

  Future<void> _markShowcaseAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenShowcaseKey, true);
    setState(() {
      _hasSeenShowcase = true;
    });
  }

  // 显示确认对话框
  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 用户必须点击按钮关闭对话框
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('确认重置'),
          content: const Text('确定要清除引导缓存吗？下次启动应用时将再次显示引导。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 关闭对话框
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 关闭对话框
                _resetShowcase(); // 执行重置操作
              },
            ),
          ],
        );
      },
    );
  }

  // 只清除缓存，不立即展示引导
  Future<void> _resetShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenShowcaseKey, false);

    if (mounted) {
      setState(() {
        _hasSeenShowcase = false;
      });

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('引导缓存已清除，下次启动应用时将显示引导'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 手动检查更新
  Future<void> _manualCheckForUpdates() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在检查更新...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final newVersion = await VersionCheckService.checkForUpdates();
      if (newVersion != null && 
          VersionCheckService.needsUpdate(
            VersionCheckService.currentVersion, 
            newVersion.version
          )) {
        if (mounted) {
          _showUpdateDialog(newVersion);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已经是最新版本'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查更新失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // 添加检查更新按钮
          IconButton(
            icon: const Icon(Icons.system_update),
            tooltip: '检查更新',
            onPressed: _manualCheckForUpdates,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置引导',
            onPressed: _showResetConfirmationDialog,
          ),
        ],
      ),
      body: _isCheckingForUpdates 
          ? const Center(child: CircularProgressIndicator()) // 检查更新时显示加载指示器
          : GridView.builder(
              itemCount: 6,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                if (index == 5) {
                  return Showcase.withWidget(
                    key: _lastItemKey,
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    container: Align(
                      alignment: Alignment.topLeft,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 220,
                            margin: const EdgeInsets.only(left: 100),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 30),
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '重要提示',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    '这是网格中的最后一个元素，点击可以查看详情。',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '提示',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          ShowCaseWidget.of(context).dismiss();
                                          _markShowcaseAsSeen();
                                        },
                                        child: const Text('我知道了'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: -50,
                            left: 0,
                            right: -140,
                            child: Center(
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/img_guide.png',
                                  fit: BoxFit.cover,
                                  width: 112,
                                  height: 68,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Item $index'),
                    ),
                  );
                }

                return Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Item $index'),
                );
              },
            ),
    );
  }
}
