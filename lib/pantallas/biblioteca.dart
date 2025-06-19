import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BibliotecaScreen extends StatefulWidget {
  final List<String> userFavorites;
  final Function(Map<String, dynamic>) onMovieTap;
  final VoidCallback onFavoritesChanged;

  const BibliotecaScreen({
    super.key,
    required this.userFavorites,
    required this.onMovieTap,
    required this.onFavoritesChanged,
  });

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen>
    with TickerProviderStateMixin {
  
  List<Map<String, dynamic>> _favoriteMovies = [];
  bool _isLoading = true;
  String _sortBy = 'recent'; // recent, alphabetical, year
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadFavoriteMovies();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteMovies() async {
    setState(() {
      _isLoading = true;
    });

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
          List<Map<String, dynamic>> favoriteMovies = [];
          
          favoritesMap.forEach((key, value) {
            favoriteMovies.add(Map<String, dynamic>.from(value));
          });
          
          setState(() {
            _favoriteMovies = favoriteMovies;
            _sortMovies();
          });
        } else {
          setState(() {
            _favoriteMovies = [];
          });
        }
      } catch (e) {
        print('Error cargando películas favoritas: $e');
        setState(() {
          _favoriteMovies = [];
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _sortMovies() {
    switch (_sortBy) {
      case 'recent':
        _favoriteMovies.sort((a, b) {
          String dateA = a['fechaAgregado'] ?? '';
          String dateB = b['fechaAgregado'] ?? '';
          return dateB.compareTo(dateA); // Más recientes primero
        });
        break;
      case 'alphabetical':
        _favoriteMovies.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'year':
        _favoriteMovies.sort((a, b) {
          int yearA = int.tryParse(a['year'] ?? '0') ?? 0;
          int yearB = int.tryParse(b['year'] ?? '0') ?? 0;
          return yearB.compareTo(yearA); // Más nuevas primero
        });
        break;
    }
  }

  Future<void> _removeFromFavorites(Map<String, dynamic> movie) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        String movieId = movie['name'].replaceAll(' ', '_').toLowerCase();
        
        await _database
            .child('usuarios')
            .child(user.uid)
            .child('peliculasFavoritas')
            .child(movieId)
            .remove();

        setState(() {
          _favoriteMovies.removeWhere((m) => m['name'] == movie['name']);
        });

        widget.onFavoritesChanged();
        
        _showSnackBar('${movie['name']} removida de tu biblioteca', Icons.remove_circle, Colors.orange);
        
      } catch (e) {
        _showSnackBar('Error al remover de biblioteca', Icons.error, Colors.red);
        print('Error removiendo de favoritos: $e');
      }
    }
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
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadFavoriteMovies,
          color: Colors.white,
          backgroundColor: Colors.black,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                
                if (_isLoading)
                  _buildLoadingState()
                else if (_favoriteMovies.isEmpty)
                  _buildEmptyState()
                else ...[
                  _buildStatsAndFilters(),
                  const SizedBox(height: 20),
                  _buildMoviesGrid(),
                ],
                
                const SizedBox(height: 100),
              ],
            ),
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
            'Tu Biblioteca',
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

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Cargando tu biblioteca...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 500,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.video_library_outlined,
                  size: 60,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tu biblioteca está vacía',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Agrega películas a tu biblioteca tocando el botón + en cualquier película que te guste',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Navegar a la pestaña de inicio
                      DefaultTabController.of(context)?.animateTo(0);
                    },
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.explore, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Explorar películas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Estadísticas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.purple.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_favoriteMovies.length}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Películas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _getLastAddedDate(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Última agregada',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filtros de ordenamiento
          Row(
            children: [
              Text(
                'Ordenar por:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortButton('Recientes', 'recent'),
                      const SizedBox(width: 8),
                      _buildSortButton('A-Z', 'alphabetical'),
                      const SizedBox(width: 8),
                      _buildSortButton('Año', 'year'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    bool isSelected = _sortBy == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _sortMovies();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.blue.withOpacity(0.8) 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _getLastAddedDate() {
    if (_favoriteMovies.isEmpty) return 'Nunca';
    
    try {
      // Ordenar por fecha para obtener la más reciente
      var sortedMovies = List<Map<String, dynamic>>.from(_favoriteMovies);
      sortedMovies.sort((a, b) {
        String dateA = a['fechaAgregado'] ?? '';
        String dateB = b['fechaAgregado'] ?? '';
        return dateB.compareTo(dateA);
      });
      
      if (sortedMovies.isNotEmpty) {
        DateTime? date = DateTime.tryParse(sortedMovies.first['fechaAgregado'] ?? '');
        if (date != null) {
          Duration diff = DateTime.now().difference(date);
          if (diff.inDays == 0) {
            return 'Hoy';
          } else if (diff.inDays == 1) {
            return 'Ayer';
          } else if (diff.inDays < 7) {
            return 'Hace ${diff.inDays} días';
          } else {
            return '${date.day}/${date.month}';
          }
        }
      }
    } catch (e) {
      return 'Reciente';
    }
    
    return 'Reciente';
  }

  Widget _buildMoviesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _favoriteMovies.length,
        itemBuilder: (context, index) {
          final movie = _favoriteMovies[index];
          return _buildMovieCard(movie, index);
        },
      ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie, int index) {
    return GestureDetector(
      onTap: () => widget.onMovieTap(movie),
      onLongPress: () => _showRemoveDialog(movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Imagen de la película
              Image.network(
                movie['image'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1C1C1E),
                    child: const Center(
                      child: Icon(Icons.movie, size: 50, color: Colors.white38),
                    ),
                  );
                },
              ),
              
              // Gradiente overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              
              // Badge de favorito
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              
              // Información de la película
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${movie['year']} • ${movie['duration']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRemoveDialog(Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Remover de biblioteca',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            '¿Quieres remover "${movie['name']}" de tu biblioteca?',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromFavorites(movie);
              },
              child: const Text(
                'Remover',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}