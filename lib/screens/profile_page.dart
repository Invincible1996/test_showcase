import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          // 用户信息卡片
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                // 用户头像
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                // 用户名和其他信息
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '用户名',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '查看并编辑个人资料',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 编辑按钮
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('编辑个人资料'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
          ),
          
          // 菜单项
          const SizedBox(height: 20),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: '设置',
            subtitle: '应用设置、隐私政策等',
          ),
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: '历史记录',
            subtitle: '查看您的使用历史',
          ),
          _buildMenuItem(
            context,
            icon: Icons.favorite,
            title: '我的收藏',
            subtitle: '查看您收藏的内容',
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: '帮助与反馈',
            subtitle: '常见问题解答、提交反馈',
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: '关于',
            subtitle: '应用版本、开发者信息',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('点击了$title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
