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
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Referencias de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    
    // Cargar datos del usuario
    _loadUserFavorites();
    _loadUserProfile();
    
    // Auto-scroll del hero
    _startHeroAutoScroll();
  }

  void _startHeroAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _allMovies.isNotEmpty) {
        int nextIndex = (_currentHeroIndex + 1) % _allMovies.length;
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _startHeroAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<List> leerJson(context) async {
    String jsonString = await DefaultAssetBundle.of(context).loadString("assets/data/peliculas.json");
    List movies = json.decode(jsonString);
    
    // Filtrar películas según la edad del usuario
    List filteredMovies = _filterMoviesByAge(movies);
    
    _allMovies = filteredMovies;
    return filteredMovies;
  }

  // ========== FUNCIONES DE FIREBASE ==========
  
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
              'avatar': userData['avatar'] ?? '',
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

  List<dynamic> _filterMoviesByAge(List<dynamic> movies) {
    return movies.where((movie) {
      String rating = movie['rating'] ?? 'PG-13';
      return _canWatchContent(rating);
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

        _showSnackBar('${movie['name']} agregada a tu biblioteca', Icons.check_circle, Colors.green);
        
      } catch (e) {
        _showSnackBar('Error al agregar a biblioteca', Icons.error, Colors.red);
        print('Error agregando a favoritos: $e');
      }
    }
  }

  bool _isInFavorites(Map<String, dynamic> movie) {
    String movieId = movie['name'].replaceAll(' ', '_').toLowerCase();
    return _userFavorites.contains(movieId);
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen(); 
         case 1:
        return BuscarScreen(
          allMovies: _allMovies,
          onMovieTap: _navigateToMovie,
        ); 
      case 2:
        return const FeedScreen(); 
     
      case 3:
        return BibliotecaScreen(
          userFavorites: _userFavorites,
          onMovieTap: _navigateToMovie,
          onFavoritesChanged: _loadUserFavorites,
        ); // Pantalla de biblioteca separada
      case 4:
        return PerfilScreen(
          userProfile: _userProfile,
          userFavorites: _userFavorites,
          allMovies: _allMovies,
          onProfileUpdate: _loadUserProfile,
        ); // Pantalla de perfil separada
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildHeroSection(),
              const SizedBox(height: 30),
              _buildSection("Próximamente", isComingSoon: true),
              const SizedBox(height: 30),
              _buildCategorySection("Acción", "Action"),
              const SizedBox(height: 30),
              _buildCategorySection("Ciencia Ficción", "SciFi"),
              const SizedBox(height: 30),
              _buildSection("Tendencias", isSpecial: true),
              const SizedBox(height: 30),
              _buildCategorySection("Comedia", "Comedy"),
              const SizedBox(height: 30),
              _buildCategorySection("Terror", "Horror"),
              const SizedBox(height: 30),
              _buildSection("Continuar Viendo", showProgress: true),
              const SizedBox(height: 30),
              _buildSection("Recomendados para ti"),
              const SizedBox(height: 30),
              _buildSection("Solo en StreamFlix", isExclusive: true),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Text(
            'StreamFlix',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return FutureBuilder(
      future: leerJson(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildHeroSkeleton();
        }
        
        final movies = snapshot.data!.take(5).toList();
        
        return Column(
          children: [
            Container(
              height: 520,
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
                  return _buildHeroPoster(movie);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(movies.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentHeroIndex == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _currentHeroIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroPoster(Map<String, dynamic> movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              movie['image'],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1C1C1E),
                  child: const Center(
                    child: Icon(Icons.movie, size: 80, color: Colors.white38),
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
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie['name'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${movie['year']} • ${movie['duration']} • ${movie['rating']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToMovie(movie),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.black, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Reproducir',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _addToFavorites(movie),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isInFavorites(movie) 
                                ? Colors.green.withOpacity(0.8)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _isInFavorites(movie)
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.3)
                            ),
                          ),
                          child: Icon(
                            _isInFavorites(movie) ? Icons.check : Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
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


  
  Widget _buildSection(String title, {bool isComingSoon = false, bool isSpecial = false, bool showProgress = false, bool isExclusive = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              if (isSpecial) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              if (isExclusive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'EXCLUSIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Contenido de la sección
        if (isComingSoon)
          _buildComingSoonCard()
        else
          _buildMoviesList(showProgress: showProgress),
      ],
    );
  }

  Widget _buildCategorySection(String title, String genre) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header elegante con título
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Icono pequeño y elegante
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getGenreColors(genre)[0].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getGenreColors(genre)[0].withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getGenreIcon(genre),
                  color: _getGenreColors(genre)[0],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Botón "Ver más"
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; // Índice de la pestaña "Buscar"
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver más',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.6),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Lista de películas filtradas por género
        _buildFilteredMoviesList(genre),
      ],
    );
  }

  List<Color> _getGenreColors(String genre) {
    switch (genre) {
      case "Action":
        return [Colors.red.withOpacity(0.8), Colors.orange.withOpacity(0.6)];
      case "Comedy":
        return [Colors.blue.withOpacity(0.8), Colors.purple.withOpacity(0.6)];
      case "Horror":
        return [Colors.black.withOpacity(0.9), Colors.grey.withOpacity(0.7)];
      case "SciFi":
        return [Colors.cyan.withOpacity(0.8), Colors.blue.withOpacity(0.6)];
      case "Animation":
        return [Colors.pink.withOpacity(0.8), Colors.orange.withOpacity(0.6)];
      default:
        return [Colors.grey.withOpacity(0.8), Colors.blueGrey.withOpacity(0.6)];
    }
  }

  IconData _getGenreIcon(String genre) {
    switch (genre) {
      case "Action":
        return Icons.local_fire_department;
      case "Comedy":
        return Icons.theater_comedy;
      case "Horror":
        return Icons.sentiment_very_dissatisfied;
      case "SciFi":
        return Icons.rocket_launch;
      case "Animation":
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
        List<dynamic> filteredMovies = allMovies.take(6).toList(); // Mostrar algunas películas
        
        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filteredMovies.length,
            itemBuilder: (context, index) {
              final movie = filteredMovies[index];
              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => _navigateToMovie(movie),
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _getGenreColors(genre)[0].withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        movie['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1C1C1E),
                            child: const Icon(Icons.movie, size: 25, color: Colors.white38),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildComingSoonCard() {
    return FutureBuilder(
      future: leerJson(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container();
        }
        
        final movie = snapshot.data![1]; // Usar la segunda película para "Próximamente"
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
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
                      color: const Color(0xFF1C1C1E),
                      child: const Center(
                        child: Icon(Icons.movie, size: 60, color: Colors.white38),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Próximamente',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Notificarme',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }

  Widget _buildMoviesList({bool showProgress = false}) {
    return FutureBuilder(
      future: leerJson(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildHorizontalSkeleton();
        }
        
        final movies = snapshot.data!;
        return SizedBox(
          height: showProgress ? 180 : 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _navigateToMovie(movie),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            movie['image'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1C1C1E),
                                child: const Icon(Icons.movie, size: 30, color: Colors.white38),
                              );
                            },
                          ),
                        ),
                      ),
                      if (showProgress) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.4, // 40% progreso
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHorizontalSkeleton() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 110,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 520,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
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
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}