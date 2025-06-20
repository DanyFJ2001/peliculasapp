import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appcine/pantallas/reproduccionpeli.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Importar las pantallas separadas
import 'package:appcine/pantallas/buscar.dart';
import 'package:appcine/pantallas/biblioteca.dart';
import 'package:appcine/pantallas/perfil.dart';
import 'package:appcine/pantallas/feed.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen>
    with TickerProviderStateMixin {
  
  int _selectedIndex = 0;
  int _currentHeroIndex = 0;
  List<dynamic> _allMovies = [];
  List<String> _userFavorites = [];
  Map<String, dynamic> _userProfile = {};
  final PageController _heroPageController = PageController();
  bool _isDarkTheme = true; // Control de tema
  
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _tabController;
  late AnimationController _themeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tabAnimation;
  late Animation<double> _themeAnimation;

  // Referencias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _themeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _tabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tabController,
      curve: Curves.elasticOut,
    ));

    _themeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _themeController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _tabController.forward();
    _pulseController.repeat(reverse: true);
    
    _loadUserFavorites();
    _loadUserProfile();
    _startHeroAutoScroll();
  }

  void _startHeroAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _allMovies.isNotEmpty) {
        int nextIndex = (_currentHeroIndex + 1) % _allMovies.length;
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
        _startHeroAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _tabController.dispose();
    _themeController.dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  // Cambiar tema
  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
    
    if (_isDarkTheme) {
      _themeController.reverse();
    } else {
      _themeController.forward();
    }
  }

  // Colores dinámicos según el tema
  Color get _backgroundColor => _isDarkTheme ? Colors.black : const Color(0xFFF0F8FF);
  Color get _surfaceColor => _isDarkTheme ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _textColor => _isDarkTheme ? Colors.white : const Color(0xFF1A1A1A);
  Color get _subtextColor => _isDarkTheme ? Colors.white.withOpacity(0.7) : const Color(0xFF666666);
  
  LinearGradient get _backgroundGradient => _isDarkTheme 
    ? LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.black,
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          Colors.black,
        ],
      )
    : LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF0F8FF),
          const Color(0xFFE6F3FF),
          const Color(0xFFCCE7FF),
          const Color(0xFFF0F8FF),
        ],
      );

  Future<List> leerJson(context) async {
    String jsonString = await DefaultAssetBundle.of(context).loadString("assets/data/peliculas.json");
    List movies = json.decode(jsonString);
    
    List filteredMovies = _filterMoviesByAge(movies);
    _allMovies = filteredMovies;
    return filteredMovies;
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DatabaseEvent event = await _database
            .child('usuarios')
            .child(user.uid)
            .once();
        
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> userData = event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _userProfile = {
              'nombre': userData['nombre'] ?? 'Usuario',
              'correo': userData['correo'] ?? user.email ?? '',
              'edad': userData['edad'] ?? 18,
              'fechaRegistro': userData['fechaRegistro'] ?? '',
              'fotoPerfil': userData['fotoPerfil'] ?? '',
            };
          });
        }
      } catch (e) {
        print('Error cargando perfil: $e');
      }
    }
  }

  bool _canWatchContent(String rating) {
    int userAge = _userProfile['edad'] ?? 18;
    
    switch (rating.toUpperCase()) {
      case 'G':
      case 'PG':
        return true;
      case 'PG-13':
        return userAge >= 13;
      case 'R':
      case 'NC-17':
        return userAge >= 18;
      default:
        return userAge >= 13;
    }
  }

  String _getMainGenre(Map<String, dynamic> movie) {
    String name = movie['name'].toLowerCase();
    String description = movie['description'].toLowerCase();
    
    if (name.contains('conjuring') || 
        name.contains('scream') ||
        name.contains('nightmare') ||
        name.contains('friday') ||
        name.contains('halloween') ||
        description.contains('terror') || 
        description.contains('horror') ||
        description.contains('scary') ||
        description.contains('haunted')) {
      return 'Terror';
    }
    
    if (name.contains('inception') || 
        name.contains('ready player') ||
        name.contains('matrix') ||
        name.contains('star wars') ||
        name.contains('blade runner') ||
        description.contains('future') ||
        description.contains('space') ||
        description.contains('science fiction')) {
      return 'Ciencia Ficción';
    }
    
    if (name.contains('mario') || name.contains('spider-verse') || name.contains('toy story')) {
      return 'Animación';
    } else if (name.contains('deadpool') || description.contains('comedia')) {
      return 'Comedia';
    } else {
      return 'Acción';
    }
  }

  List<dynamic> _filterMoviesByAge(List<dynamic> movies) {
    int userAge = _userProfile['edad'] ?? 18;
    
    return movies.where((movie) {
      String rating = movie['rating'] ?? 'PG-13';
      String genre = _getMainGenre(movie);
      
      if (userAge < 18 && genre == 'Terror') {
        return false;
      }
      
      return _canWatchContent(rating);
    }).toList();
  }

  List<dynamic> _filterMoviesByGenre(List<dynamic> movies, String targetGenre) {
    return movies.where((movie) {
      String genre = _getMainGenre(movie);
      return genre == targetGenre;
    }).toList();
  }

  Future<void> _loadUserFavorites() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DatabaseEvent event = await _database
            .child('usuarios')
            .child(user.uid)
            .child('peliculasFavoritas')
            .once();
        
        if (event.snapshot.exists) {
          Map<dynamic, dynamic> favoritesMap = event.snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            _userFavorites = favoritesMap.keys.cast<String>().toList();
          });
        }
      } catch (e) {
        print('Error cargando favoritos: $e');
      }
    }
  }

  Future<void> _addToFavorites(Map<String, dynamic> movie) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String movieId = movie['name'].replaceAll(' ', '_').toLowerCase();
        
        await _database
            .child('usuarios')
            .child(user.uid)
            .child('peliculasFavoritas')
            .child(movieId)
            .set({
          'name': movie['name'],
          'description': movie['description'],
          'image': movie['image'],
          'year': movie['year'],
          'duration': movie['duration'],
          'rating': movie['rating'],
          'videoId': movie['videoId'],
          'fechaAgregado': DateTime.now().toIso8601String(),
        });

        setState(() {
          _userFavorites.add(movieId);
        });

        _showEnhancedSnackBar(
          '${movie['name']} agregada a tu biblioteca', 
          Icons.favorite, 
          Colors.pink,
          true
        );
        
      } catch (e) {
        _showEnhancedSnackBar(
          'Error al agregar a biblioteca', 
          Icons.error, 
          Colors.red,
          false
        );
        print('Error agregando a favoritos: $e');
      }
    }
  }

  bool _isInFavorites(Map<String, dynamic> movie) {
    String movieId = movie['name'].replaceAll(' ', '_').toLowerCase();
    return _userFavorites.contains(movieId);
  }

  void _showEnhancedSnackBar(String message, IconData icon, Color color, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSuccess)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
        backgroundColor: _surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeAnimation,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor,
          body: Container(
            decoration: BoxDecoration(gradient: _backgroundGradient),
            child: _buildBody(),
          ),
          bottomNavigationBar: _buildEnhancedBottomNavigation(),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildEnhancedHomeScreen(); 
      case 1:
        return BuscarScreen(
          allMovies: _allMovies,
    onMovieTap: _navigateToMovie,
    onGoToFeed: () {
      setState(() {
        _selectedIndex = 2; 
      });
    },
    isDarkTheme: _isDarkTheme,
  );  
      case 2:
        return const FeedScreen(); 
      case 3:
        return BibliotecaScreen(
          userFavorites: _userFavorites,
          onMovieTap: _navigateToMovie,
          onFavoritesChanged: _loadUserFavorites,
        );
      case 4:
        return PerfilScreen(
          userProfile: _userProfile,
          userFavorites: _userFavorites,
          allMovies: _allMovies,
          onProfileUpdate: _loadUserProfile,
        );
      default:
        return _buildEnhancedHomeScreen();
    }
  }

  Widget _buildEnhancedHomeScreen() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildEnhancedHeader()),
            SliverToBoxAdapter(child: _buildEnhancedHeroSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(child: _buildSection("🔥 Tendencias", isSpecial: true)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(child: _buildCategorySection("⚡ Acción", "Acción")),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            SliverToBoxAdapter(child: _buildCategorySection("🚀 Ciencia Ficción", "Ciencia Ficción")),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
            if (_userProfile['edad'] != null && _userProfile['edad'] >= 18) ...[
              SliverToBoxAdapter(child: _buildCategorySection("💀 Terror", "Terror")),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
            SliverToBoxAdapter(child: _buildSection("📱 Solo en StreamFlix", isExclusive: true)),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    String userName = _userProfile['nombre'] ?? 'Usuario';
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hola",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _subtextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: userName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const TextSpan(
                            text: ' ',
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de cambio de tema
              GestureDetector(
                onTap: _toggleTheme,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: _surfaceColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkTheme ? Colors.yellow : Colors.indigo,
                    size: 20,
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _surfaceColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  child: _userProfile['fotoPerfil'] != null && _userProfile['fotoPerfil'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.network(
                          _userProfile['fotoPerfil'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: _textColor,
                              size: 20,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: _textColor,
                        size: 20,
                      ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          RichText(
            text: TextSpan(
              children: [
               
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeroSection() {
    return FutureBuilder(
      future: leerJson(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEnhancedHeroSkeleton();
        }
        
        final movies = snapshot.data!.take(5).toList();
        
        return Column(
          children: [
            Container(
              height: 520,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: PageView.builder(
                controller: _heroPageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentHeroIndex = index;
                  });
                },
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return _buildEnhancedHeroPoster(movie);
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(movies.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentHeroIndex == index ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentHeroIndex == index
                        ? const Color(0xFF007AFF)
                        : _subtextColor.withOpacity(0.5),
                    boxShadow: _currentHeroIndex == index ? [
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedHeroPoster(Map<String, dynamic> movie) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isDarkTheme ? Colors.black : Colors.grey).withOpacity(0.6),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Image.network(
              movie['image'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                  ),
                  child: Center(
                    child: Icon(Icons.movie, size: 80, color: _subtextColor),
                  ),
                );
              },
            ),
            
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.3),
                    (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.8),
                    (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
                ),
              ),
            ),
            
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['name'],
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          color: (_isDarkTheme ? Colors.black : Colors.grey).withOpacity(0.5),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoPill(movie['year'], const Color(0xFF007AFF)),
                      _buildInfoPill(movie['duration'], const Color(0xFF059669)),
                      _buildInfoPill(movie['rating'], const Color(0xFFDC2626)),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildEnhancedActionButton(
                          onPressed: () => _navigateToMovie(movie),
                          icon: Icons.play_arrow,
                          label: 'Reproducir',
                          isPrimary: true,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      _buildCircularActionButton(
                        onPressed: () => _addToFavorites(movie),
                        icon: _isInFavorites(movie) ? Icons.favorite : Icons.favorite_border,
                        color: _isInFavorites(movie) ? Colors.pink : _textColor.withOpacity(0.8),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      _buildCircularActionButton(
                        onPressed: () => _showMovieInfoModal(movie),
                        icon: Icons.info_outline,
                        color: _textColor.withOpacity(0.8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF007AFF) : _surfaceColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPrimary 
                ? const Color(0xFF007AFF)
                : _textColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: const Color(0xFF007AFF).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _surfaceColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showMovieInfoModal(Map<String, dynamic> movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _subtextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_isDarkTheme ? Colors.black : Colors.grey).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      movie['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _surfaceColor,
                          child: Icon(Icons.movie, size: 60, color: _subtextColor),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie['name'],
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildInfoChip(movie['year'], Colors.blue),
                              const SizedBox(width: 8),
                              _buildInfoChip(movie['duration'], Colors.green),
                              const SizedBox(width: 8),
                              _buildInfoChip(movie['rating'], Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sinopsis',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          movie['description'],
                          style: TextStyle(
                            color: _subtextColor,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToMovie(movie);
                            },
                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                            label: const Text(
                              'Reproducir',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToFavorites(movie);
                          },
                          icon: Icon(
                            _isInFavorites(movie) ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isInFavorites(movie) ? 'Guardada' : 'Guardar',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInFavorites(movie) ? Colors.pink : Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(String title, {bool isSpecial = false, bool isExclusive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    if (isSpecial) ...[
                      const TextSpan(
                        text: '🔥 ',
                        style: TextStyle(fontSize: 22),
                      ),
                      const TextSpan(
                        text: 'Tendencias',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ] else if (isExclusive) ...[
                      TextSpan(
                        text: '📱 Solo en ',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                      const TextSpan(
                        text: 'StreamFlix',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ] else ...[
                      TextSpan(
                        text: title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              if (isSpecial) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        _buildMoviesList(),
      ],
    );
  }

  Widget _buildCategorySection(String title, String genre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getGenreColors(genre)[0].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getGenreColors(genre)[0].withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getGenreIcon(genre),
                  color: _getGenreColors(genre)[0],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textColor,
                  ),
                ),
              ),
              
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _surfaceColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _textColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver más',
                        style: TextStyle(
                          color: _textColor.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: _textColor.withOpacity(0.7),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        _buildFilteredMoviesList(genre),
      ],
    );
  }

  List<Color> _getGenreColors(String genre) {
    switch (genre) {
      case "Acción":
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case "Comedia":
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case "Terror":
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
      case "Ciencia Ficción":
        return [const Color(0xFF06B6D4), const Color(0xFF0891B2)];
      case "Animación":
        return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
    }
  }

  IconData _getGenreIcon(String genre) {
    switch (genre) {
      case "Acción":
        return Icons.local_fire_department;
      case "Comedia":
        return Icons.theater_comedy;
      case "Terror":
        return Icons.sentiment_very_dissatisfied;
      case "Ciencia Ficción":
        return Icons.rocket_launch;
      case "Animación":
        return Icons.palette;
      default:
        return Icons.movie;
    }
  }

  Widget _buildFilteredMoviesList(String genre) {
    return FutureBuilder(
      future: leerJson(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildHorizontalSkeleton();
        }
        
        final allMovies = snapshot.data!;
        List<dynamic> filteredMovies;
        
        if (genre == "Terror" || genre == "Ciencia Ficción") {
          filteredMovies = _filterMoviesByGenre(allMovies, genre);
          
          if (filteredMovies.isEmpty) {
            if (genre == "Terror" && (_userProfile['edad'] ?? 18) < 18) {
              return _buildRestrictedContentMessage();
            }
            return _buildNoMoviesMessage(genre);
          }
        } else {
          filteredMovies = allMovies.take(8).toList();
        }
        
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filteredMovies.length,
            itemBuilder: (context, index) {
              final movie = filteredMovies[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16),
                child: _buildMovieCard(movie),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRestrictedContentMessage() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Contenido restringido',
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Requiere ser mayor de 18 años',
              style: TextStyle(
                color: _subtextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMoviesMessage(String genre) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              color: _subtextColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'Próximamente',
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Más películas de $genre',
              style: TextStyle(
                color: _subtextColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesList() {
    return FutureBuilder(
      future: leerJson(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildHorizontalSkeleton();
        }
        
        final movies = snapshot.data!;
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16),
                child: _buildMovieCard(movie),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () => _navigateToMovie(movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (_isDarkTheme ? Colors.black : Colors.grey).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.network(
                movie['image'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                    ),
                    child: Center(
                      child: Icon(Icons.movie, size: 40, color: _subtextColor),
                    ),
                  );
                },
              ),
              
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _addToFavorites(movie),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isInFavorites(movie) 
                          ? Colors.pink.withOpacity(0.9)
                          : (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _textColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isInFavorites(movie) ? Icons.favorite : Icons.favorite_border,
                      color: _isInFavorites(movie) ? Colors.white : _textColor,
                      size: 14,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getRatingColor(movie['rating']).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getRatingColor(movie['rating']),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    movie['rating'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showMovieInfoModal(movie),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (_isDarkTheme ? Colors.black : Colors.white).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _textColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: _textColor,
                      size: 14,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                bottom: 8,
                left: 8,
                right: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie['name'],
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: (_isDarkTheme ? Colors.black : Colors.grey).withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      movie['year'],
                      style: TextStyle(
                        color: _subtextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRatingColor(String rating) {
    switch (rating.toUpperCase()) {
      case 'G':
        return const Color(0xFF10B981);
      case 'PG':
        return const Color(0xFF3B82F6);
      case 'PG-13':
        return const Color(0xFFF59E0B);
      case 'R':
      case 'NC-17':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildHorizontalSkeleton() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _surfaceColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _textColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.movie,
                color: _subtextColor.withOpacity(0.5),
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedHeroSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 520,
      decoration: BoxDecoration(
        color: _surfaceColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie,
              color: _subtextColor.withOpacity(0.5),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando contenido...',
              style: TextStyle(
                color: _subtextColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          top: BorderSide(
            color: _textColor.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: _subtextColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _navigateToMovie(Map<String, dynamic> pelicula) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReproduccionScreen(
              titulo: pelicula['name'],
              videoId: pelicula['videoId'],
              description: pelicula['description'],
              year: pelicula['year'],
              duration: pelicula['duration'],
              rating: pelicula['rating'],
              image: pelicula['image'],
              movieUrl: pelicula['movieUrl'],
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}