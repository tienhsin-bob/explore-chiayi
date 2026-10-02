import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/profile_menu_item.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'favorite_page.dart';
import 'main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _photoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  User? get user => FirebaseAuth.instance.currentUser;
  bool get isUserLoggedIn => user != null && !user!.isAnonymous;

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog() {
    _nameController.text = user?.displayName ?? '';
    _photoController.text = user?.photoURL ?? '';
    _emailController.text = user?.email ?? '';
    _passwordController.text = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯個人資料'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '使用者名稱', hintText: '輸入新的名稱'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _photoController,
                decoration: const InputDecoration(labelText: '頭像網址', hintText: '輸入圖片 URL'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: '電子郵件', hintText: '輸入新的信箱'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '新密碼', hintText: '留空表示不修改'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_nameController.text != user?.displayName) {
                  await user?.updateDisplayName(_nameController.text);
                }
                if (_photoController.text != user?.photoURL) {
                  await user?.updatePhotoURL(_photoController.text);
                }
                if (_emailController.text.isNotEmpty && _emailController.text != user?.email) {
                  await user?.verifyBeforeUpdateEmail(_emailController.text);
                }
                if (_passwordController.text.isNotEmpty) {
                  await user?.updatePassword(_passwordController.text);
                }
                await user?.reload();
                if (mounted) {
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('資料已更新')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失敗: $e')));
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('個人中心'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textTitle,
        elevation: 0,
        actions: [
          if (isUserLoggedIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _showEditProfileDialog,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                        ? NetworkImage(user!.photoURL!) as ImageProvider
                        : const AssetImage('assets/images/re_lie.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isUserLoggedIn ? (user?.displayName ?? '未設定名稱') : '訪客使用者',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTitle,
                    ),
                  ),
                  if (isUserLoggedIn)
                    Text(
                      user?.email ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.favorite_border,
                    title: '我的收藏',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritePage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
                  ProfileMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: '我的行程',
                    onTap: () {
                      // 💡 修改：直接跳轉到地圖分頁，並清空之前的導航棧以確保 UI 狀態正確
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainPage(initialIndex: 2),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
                  ProfileMenuItem(
                    icon: Icons.info_outline,
                    title: '關於我們',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('探索嘉義 v1.0.0')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (isUserLoggedIn) {
                      await _authService.signOut();
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已登出')));
                      }
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(isUserLoggedIn ? '登出帳號' : '登入 / 註冊', style: const TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
