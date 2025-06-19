import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:appcine/pantallas/reproduccionpeli.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with TickerProviderStateMixin {
  
  PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: false,
  );
  List<dynamic> _movies = [];
  List<dynamic> _filteredMovies = [];
  List<String> _userFavorites = [];
  Map<String, dynamic> _userProfile = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // Variables para scroll súper sensible
  double _startY = 0;
  bool _isScrolling = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    
    // Pantalla completa inmersiva para experiencia TikTok
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _loadMovies();
    _loadUserFavorites();
    _loadUserProfile(); // Cargar perfil para obtener edad
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Cargar perfil del usuario para obtener su edad
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
              'edad': userData['edad'] ?? 18,
              'nombre': userData['nombre'] ?? 'Usuario',
            };
          });
          print('Edad del usuario: ${_userProfile['edad']}'); // Debug
          
          // Recargar películas con filtro de edad
          if (_movies.isNotEmpty) {
            _filterMoviesByAge();
          }
        }
      } catch (e) {
        print('Error cargando perfil: $e');
        // Usar edad por defecto
        setState(() {
          _userProfile = {'edad': 18, 'nombre': 'Usuario'};
        });
      }
    } else {
      // Usuario no logueado, usar edad por defecto
      setState(() {
        _userProfile = {'edad': 18, 'nombre': 'Usuario'};
      });
    }
  }

  // Verificar si el usuario puede ver contenido basado en rating y edad
  bool _canWatchContent(String rating) {
    int userAge = _userProfile['edad'] ?? 18;
    
    switch (rating.toUpperCase()) {
      case 'G':
      case 'PG':
        return true; // Todos pueden ver
      case 'PG-13':
        return userAge >= 13;
      case 'R':
      case 'NC-17':
        return userAge >= 18;
      default:
        return userAge >= 13; // Por defecto, requiere 13+
    }
  }

  // Determinar género principal de la película
  String _getMainGenre(Map<String, dynamic> movie) {
    String name = movie['name'].toLowerCase();
    String description = movie['description'].toLowerCase();
    
    // Detectar películas de terror/horror
    if (name.contains('conjuring') || 
        name.contains('it ') || 
        name.contains('scream') ||
        name.contains('nightmare') ||
        name.contains('friday') ||
        name.contains('halloween') ||
        description.contains('terror') || 
        description.contains('miedo') ||
        description.contains('horror') ||
        description.contains('scary') ||
        description.contains('haunted')) {
      return 'Terror';
    }
    
    // Otros géneros...
    if (name.contains('mario') || name.contains('spider-verse') || name.contains('toy story')) {
      return 'Animación';
    } else if (name.contains('deadpool') || description.contains('comedia')) {
      return 'Comedia';
    } else if (name.contains('inception') || name.contains('ready player')) {
      return 'Ciencia Ficción';
    } else {
      return 'Acción';
    }
  }

  // Filtrar películas según edad del usuario
  void _filterMoviesByAge() {
    int userAge = _userProfile['edad'] ?? 18;
    
    List<dynamic> ageFilteredMovies = _movies.where((movie) {
      String rating = movie['rating'] ?? 'PG-13';
      String genre = _getMainGenre(movie);
      
      // Si es menor de 18 y es terror, NO mostrar
      if (userAge < 18 && genre == 'Terror') {
        print('Ocultando película de terror para menor de edad: ${movie['name']}'); // Debug
        return false;
      }
      
      // Verificar rating
      bool canWatch = _canWatchContent(rating);
      
      if (!canWatch) {
        print('Ocultando película ${movie['name']} - Rating: $rating, Edad: $userAge'); // Debug
      }
      
      return canWatch;
    }).toList();
    
    setState(() {
      _filteredMovies = ageFilteredMovies;
    });
    
    print('Películas totales: ${_movies.length}'); // Debug
    print('Películas filtradas para edad $userAge: ${_filteredMovies.length}'); // Debug
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

        _showSnackBar('❤️ ${movie['name']} agregada a biblioteca', Colors.red);
        
      } catch (e) {
        _showSnackBar('❌ Error al agregar a biblioteca', Colors.red);
      }
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
          _userFavorites.remove(movieId);
        });

        _showSnackBar('💔 ${movie['name']} removida de biblioteca', Colors.orange);
        
      } catch (e) {
        _showSnackBar('❌ Error al remover de biblioteca', Colors.red);
      }
    }
  }

  bool _isInFavorites(Map<String, dynamic> movie) {
    String movieId = movie['name'].replaceAll(' ', '_').toLowerCase();
    return _userFavorites.contains(movieId);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loadMovies() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context)
          .loadString("assets/data/peliculas.json");
      List movies = json.decode(jsonString);
      
      setState(() {
        _movies = movies;
      });
      
      print('Películas cargadas: ${_movies.length}'); // Debug
      
      // Si ya tenemos el perfil del usuario, filtrar
      if (_userProfile.isNotEmpty) {
        _filterMoviesByAge();
      } else {
        // Mostrar todas mientras se carga el perfil
        setState(() {
          _filteredMovies = movies;
        });
      }
      
      setState(() {
        _isLoading = false;
      });
      
      _fadeController.forward();
    } catch (e) {
      print('Error cargando películas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_filteredMovies.isEmpty) { // Cambio: usar _filteredMovies
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // PageView principal - scroll vertical
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                print('Cambiando a video $index'); // Debug
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _filteredMovies.length, // Cambio: usar _filteredMovies
              itemBuilder: (context, index) {
                return _buildVideoItem(_filteredMovies[index], index); // Cambio: usar _filteredMovies
              },
            ),
            
            // Header con información básica
            _buildHeader(),
            
            // Botones laterales (como TikTok)
            _buildSideActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Cargando trailers...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 60),
            SizedBox(height: 20),
            Text(
              'No hay contenido disponible para tu edad',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Las películas están filtradas según tu edad (${_userProfile['edad'] ?? 18} años)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadMovies();
              },
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> movie, int index) {
    bool isCurrentVideo = index == _currentIndex;
    
    return Stack(
      children: [
        // Video de YouTube a pantalla completa
        Positioned.fill(
          child: TikTokVideoPlayer(
            key: ValueKey('video_${movie['videoId']}_$index'), // Key única para cada video
            videoId: movie['videoId'],
            isPlaying: isCurrentVideo, // Solo reproducir si es el video actual
          ),
        ),
        
        // Overlay con gradiente sutil
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
        
        // Información de la película (parte inferior)
        Positioned(
          bottom: 20,  // Cambio: más abajo
          left: 16,
          right: 80,
          child: _buildMovieInfo(movie),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 15,
      left: 0,
      right: 0,
      child: Container(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_fill,
                    color: Colors.red,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'StreamFlix Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildSideActions() {
    if (_filteredMovies.isEmpty) return Container(); // Protección
    
    final movie = _filteredMovies[_currentIndex]; // Cambio: usar _filteredMovies
    bool isLiked = _isInFavorites(movie);
    
    return Positioned(
      right: 12,
      bottom: 40,  // Cambio: más abajo también
      child: Column(
        children: [
          // Botón Ver Película Completa (PRINCIPAL)
          _buildActionButton(
            icon: Icons.play_circle_fill,
            label: 'Ver\nCompleta',
            color: Colors.red,
            onTap: () => _navigateToFullMovie(movie),
            isPrimary: true,
          ),
          
          SizedBox(height: 24),
          
          // Botón Me Gusta / Biblioteca
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: isLiked ? 'Guardada' : 'Guardar',
            color: isLiked ? Colors.red : Colors.white,
            onTap: () => _toggleFavorite(movie),
          ),
          
          SizedBox(height: 24),
          
          // Botón Comentarios
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: '1.2K',
            color: Colors.white,
            onTap: () => _showComments(movie),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isPrimary ? 60 : 50,
            height: isPrimary ? 60 : 50,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.red : Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(isPrimary ? 30 : 25),
              border: Border.all(
                color: isPrimary ? Colors.red.shade700 : Colors.white.withOpacity(0.3),
                width: isPrimary ? 2 : 1,
              ),
              boxShadow: isPrimary ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ] : [],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isPrimary ? 30 : 25,
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isPrimary ? 12 : 10,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMovieInfo(Map<String, dynamic> movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la película
        Text(
          movie['name'],
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
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
        
        SizedBox(height: 8),
        
        // Información adicional
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                movie['year'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                movie['rating'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              movie['duration'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Descripción corta
        Text(
          movie['description'],
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
            height: 1.3,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ========== MÉTODOS DE ACCIÓN ==========

  void _toggleFavorite(Map<String, dynamic> movie) {
    if (_isInFavorites(movie)) {
      _removeFromFavorites(movie);
    } else {
      _addToFavorites(movie);
    }
  }

  void _navigateToFullMovie(Map<String, dynamic> movie) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReproduccionScreen(
              titulo: movie['name'],
              videoId: movie['videoId'],
              description: movie['description'],
              year: movie['year'],
              duration: movie['duration'],
              rating: movie['rating'],
              image: movie['image'],
              movieUrl: movie['movieUrl'],
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showComments(Map<String, dynamic> movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(movie: movie),
    );
  }
}

// ========== REPRODUCTOR DE VIDEO PERSONALIZADO ==========

class TikTokVideoPlayer extends StatefulWidget {
  final String videoId;
  final bool isPlaying;

  const TikTokVideoPlayer({
    super.key,
    required this.videoId,
    required this.isPlaying,
  });

  @override
  State<TikTokVideoPlayer> createState() => _TikTokVideoPlayerState();
}

class _TikTokVideoPlayerState extends State<TikTokVideoPlayer> {
  YoutubePlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    print('Inicializando video: ${widget.videoId}'); // Debug
    _initializeController();
  }

  void _initializeController() {
    _controller?.dispose(); // Asegurar que se destruya el anterior
    
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.isPlaying,
        mute: false,
        loop: false,
        hideControls: true,
        forceHD: false, // Cambio: menos exigente
        enableCaption: false,
        startAt: 0,
      ),
    );
    
    print('Controller creado para: ${widget.videoId}, autoPlay: ${widget.isPlaying}'); // Debug
  }

  @override
  void didUpdateWidget(TikTokVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    print('didUpdateWidget - Old: ${oldWidget.videoId}, New: ${widget.videoId}'); // Debug
    print('didUpdateWidget - Old playing: ${oldWidget.isPlaying}, New playing: ${widget.isPlaying}'); // Debug
    
    // Si cambió el videoId, recrear controller
    if (widget.videoId != oldWidget.videoId) {
      print('Recreando controller para nuevo video: ${widget.videoId}'); // Debug
      _initializeController();
      return; // Salir porque ya se maneja el autoplay en la inicialización
    }
    
    // Si solo cambió el estado de reproducción
    if (widget.isPlaying != oldWidget.isPlaying) {
      print('Cambiando estado de reproducción a: ${widget.isPlaying}'); // Debug
      if (widget.isPlaying) {
        _controller?.play();
        print('Reproduciendo video: ${widget.videoId}'); // Debug
      } else {
        _controller?.pause();
        print('Pausando video: ${widget.videoId}'); // Debug
      }
    }
  }

  @override
  void dispose() {
    print('Disposing controller para: ${widget.videoId}'); // Debug
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return YoutubePlayer(
      controller: _controller!,
      showVideoProgressIndicator: false,
      progressIndicatorColor: Colors.transparent,
      aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
      bottomActions: [],
      topActions: [],
      onReady: () {
        print('Video listo: ${widget.videoId}'); // Debug
        if (widget.isPlaying) {
          _controller?.play();
        }
      },
    );
  }
}

// ========== COMENTARIOS FUNCIONALES ==========

class CommentsSheet extends StatefulWidget {
  final Map<String, dynamic> movie;

  const CommentsSheet({super.key, required this.movie});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadComments();
    // Agregar comentarios de ejemplo
    _addExampleComments();
  }

  void _addExampleComments() {
    _comments.addAll([
      {
        'user': 'Carlos_M',
        'comment': '¡Increíble trailer! 🔥 Ya quiero verla completa',
        'time': '2h',
        'likes': 45,
      },
      {
        'user': 'Ana_Cinema',
        'comment': 'Los efectos especiales se ven espectaculares 😍',
        'time': '1h',
        'likes': 23,
      },
      {
        'user': 'MovieFan2024',
        'comment': 'Definitivamente va a mi lista de pendientes',
        'time': '45min',
        'likes': 12,
      },
      {
        'user': 'Sofia_R',
        'comment': 'El protagonista actúa increíble! 👏',
        'time': '30min',
        'likes': 8,
      },
    ]);
  }

  void _loadComments() async {
    // Aquí cargarías comentarios reales de Firebase
    // Por ahora usamos comentarios de ejemplo
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user != null) {
      String userName = user.displayName ?? 'Usuario';
      
      setState(() {
        _comments.insert(0, {
          'user': userName,
          'comment': _commentController.text.trim(),
          'time': 'ahora',
          'likes': 0,
        });
      });

      _commentController.clear();

      // Aquí guardarías en Firebase
      try {
        String movieId = widget.movie['name'].replaceAll(' ', '_').toLowerCase();
        await _database
            .child('comentarios')
            .child(movieId)
            .push()
            .set({
          'userId': user.uid,
          'userName': userName,
          'comment': _commentController.text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
          'likes': 0,
        });
      } catch (e) {
        print('Error guardando comentario: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Comentarios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  '${_comments.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Lista de comentarios
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentItem(comment);
              },
            ),
          ),

          // Input para nuevo comentario
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Escribe un comentario...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _addComment,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.purple,
            child: Text(
              comment['user'][0].toUpperCase(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['user'],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      comment['time'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment['comment'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Like comentario
                        setState(() {
                          comment['likes'] = (comment['likes'] ?? 0) + 1;
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${comment['likes']}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Responder',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}