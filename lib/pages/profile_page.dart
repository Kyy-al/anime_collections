import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  Map<String, dynamic>? _userData;
  int _totalFavorites = 0;
  int _totalAnime = 0;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    final user = await _dbService.getUser();
    setState(() {
      _userData = user;
    });
  }

  Future<void> _loadStats() async {
    final favorites = await _dbService.getFavorites(1);
    final anime = await _dbService.getAllAnime();
    
    setState(() {
      _totalFavorites = favorites.length;
      _totalAnime = anime.length;
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              // Clear local data
              await _dbService.deleteUser();
              
              // Update auth provider
              if (mounted) {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.logout();
                
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Cache'),
        content: const Text(
          'Ini akan menghapus semua data anime yang tersimpan di lokal. Favorit tidak akan terpengaruh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.clearAllData();
              Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              
              _loadStats();
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213e),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade900,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurpleAccent,
                      child: Text(
                        _userData != null
                            ? _userData!['username'][0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['username'] ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData?['email'] ?? 'user@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      title: 'Favorit',
                      value: '$_totalFavorites',
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.movie_filter,
                      title: 'Total Anime',
                      value: '$_totalAnime',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // Settings Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notifications Toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Notifikasi'),
                      subtitle: const Text('Terima notifikasi anime baru'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        
                        if (value) {
                          _notificationService.showNotification(
                            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                            title: '🔔 Notifikasi Aktif',
                            body: 'Anda akan menerima notifikasi anime baru',
                          );
                        }
                      },
                      secondary: const Icon(Icons.notifications),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Test Notification
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Test Notifikasi'),
                      subtitle: const Text('Kirim notifikasi test'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _notificationService.showNotification(
                          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                          title: '🎬 Test Notifikasi',
                          body: 'Ini adalah notifikasi test dari Anime Collection!',
                        );
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notifikasi test terkirim'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Clear Cache
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('Hapus Cache'),
                      subtitle: const Text('Bersihkan data lokal'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _clearCache,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // About
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Tentang Aplikasi'),
                      subtitle: const Text('Versi 1.0.0'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Anime Collection',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(
                            Icons.movie_filter_rounded,
                            size: 50,
                          ),
                          children: [
                            const Text(
                              'Aplikasi untuk mengelola koleksi anime favorit Anda.',
                            ),
                            const SizedBox(height: 16),
                            const Text('Fitur:'),
                            const Text('• Database MySQL & SQLite'),
                            const Text('• REST API Integration'),
                            const Text('• Video Player'),
                            const Text('• Push Notifications'),
                            const Text('• Offline Mode'),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}