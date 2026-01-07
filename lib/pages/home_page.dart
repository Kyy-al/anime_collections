import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../main.dart';
import 'detail_page.dart';
import 'favorite_page.dart';
import 'profile_page.dart';
import 'add_anime_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _animeList = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshAnimeList();
  }

  Future<void> _refreshAnimeList() async {
    setState(() => _isLoading = true);

    try {
      // Load from local database first
      final localAnime = await _dbService.getAllAnime();

      // Filter out invalid entries
      final validAnime = localAnime.where((anime) {
        return anime['title'] != null && anime['title'].toString().isNotEmpty;
      }).toList();

      setState(() {
        _animeList = validAnime;
      });

      // Try to sync with API if authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.token != null) {
        try {
          final apiAnime = await _apiService.getAllAnime(
            token: authProvider.token,
          );

          // Cache API data to local database
          await _dbService.cacheAnimeList(
            apiAnime.map((e) => e as Map<String, dynamic>).toList(),
          );

          // Reload from database to get combined data
          final updatedAnime = await _dbService.getAllAnime();
          setState(() {
            _animeList = updatedAnime;
          });
        } catch (apiError) {
          // API failed, but we already have local data
          print('API sync failed: $apiError');
        }
      }
    } catch (e) {
      print('Error loading anime: $e');
      setState(() {
        _animeList = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onAddAnimePressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAnimePage()),
    );

    if (result == true) {
      // Anime berhasil ditambahkan, refresh list
      await _refreshAnimeList();
    }
  }

  Future<void> _searchAnime(String query) async {
    if (query.isEmpty) {
      _refreshAnimeList();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await _apiService.searchAnime(
        query,
        token: authProvider.token,
      );

      setState(() {
        _animeList = results.map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      // Search in local database
      final results = await _dbService.searchAnime(query);
      setState(() {
        _animeList = results;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAnimeGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_animeList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 100, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Belum ada anime',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAnimeList,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _animeList.length,
        itemBuilder: (context, index) {
          final anime = _animeList[index];
          return _buildAnimeCard(anime);
        },
      ),
    );
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailPage(anime: anime)),
        );

        if (result == true) {
          // Anime diedit atau dihapus, refresh list
          await _refreshAnimeList();
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: anime['image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, size: 50),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '${anime['rating'] ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime['title'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    anime['genre'] ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildHomePage(), const FavoritePage(), const ProfilePage()];

    return Scaffold(
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _onAddAnimePressed,
              child: const Icon(Icons.add),
              backgroundColor: Colors.deepPurpleAccent,
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF16213e),
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFF16213e),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 16,
              bottom: 72,
            ),
            title: const Text(
              'Anime Collection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            background: Container(
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
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchAnime,
                decoration: InputDecoration(
                  hintText: 'Cari anime...',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _refreshAnimeList();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverFillRemaining(child: _buildAnimeGrid()),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
