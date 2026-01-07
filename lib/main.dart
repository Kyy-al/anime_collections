import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService().init();
  await DatabaseService().database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnimeProvider()),
      ],
      child: MaterialApp(
        title: 'Anime Collection',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: const Color(0xFF1a1a2e),
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16213e),
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF0f3460),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

// Auth Provider
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  Map<String, dynamic>? _user;
  int? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  int? get userId => _userId;

  Future<void> login(String email, String password) async {
    // API call will be implemented in api_service.dart
    _isAuthenticated = true;
    _token = 'dummy_token';
    _userId = 1; // For now, set to 1
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _token = null;
    _user = null;
    _userId = null;
    notifyListeners();
  }
}

// Anime Provider
class AnimeProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _animeList = [];
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get animeList => _animeList;
  List<Map<String, dynamic>> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchAnime() async {
    _isLoading = true;
    notifyListeners();

    // API call will be implemented
    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
  }

  void addToFavorites(Map<String, dynamic> anime) {
    _favorites.add(anime);
    notifyListeners();
  }

  void removeFromFavorites(int animeId) {
    _favorites.removeWhere((a) => a['id'] == animeId);
    notifyListeners();
  }
}
