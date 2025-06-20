
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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // OPTIMIZACIÓN: Mantener el estado vivo
  @override
  bool get wantKeepAlive => true;
  
  late PageController _pageController;
  List<dynamic> _movies = [];
  List<dynamic> _filteredMovies = [];
  List<String> _userFavorites = [];
  Map<String, dynamic> _userProfile = {};
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // OPTIMIZACIÓN: Cache de controladores de video
  final Map<String, YoutubePlayerController> _videoControllers = {};
  final Set<int> _preloadedVideos = {};
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _pageController = PageController(
      viewportFraction: 1.0,
      keepPage: true, // OPTIMIZACIÓN: Mantener páginas
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300), // OPTIMIZACIÓN: Más rápido
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _initializeAsync();
  }

  // OPTIMIZACIÓN: Inicialización asíncrona optimizada
  Future<void> _initializeAsync() async {
    await Future.wait([
      _loadUserProfile(),
      _loadUserFavorites(),
      _loadMovies(),
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _fadeController.dispose();
    
    // OPTIMIZACIÓN: Limpiar todos los controladores
    _disposeAllVideoControllers();
    super.dispose();
  }

  // OPTIMIZACIÓN: Limpiar controladores de video
  void _disposeAllVideoControllers() {
    for (var controller in _videoControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        print('Error disposing controller: $e');
      }
    }
    _videoControllers.clear();
    _preloadedVideos.clear();
  }

  // OPTIMIZACIÓN: Crear controlador solo cuando sea necesario
  YoutubePlayerController _getOrCreateController(String videoId, {bool autoPlay = false}) {
    if (_videoControllers.containsKey(videoId)) {
      return _videoControllers[videoId]!;
    }
    
    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: autoPlay,
        mute: false,
        loop: false,
        hideControls: true,
        forceHD: false,
        enableCaption: false,
        useHybridComposition: false, // OPTIMIZACIÓN: Mejor rendimiento
      ),
    );
    
    _videoControllers[videoId] = controller;
    return controller;
  }

  // OPTIMIZACIÓN: Precargar videos adyacentes
  void _preloadAdjacentVideos(int currentIndex) {
    if (_filteredMovies.isEmpty) return;
    
    final indicesToPreload = [
      if (currentIndex > 0) currentIndex - 1,
      currentIndex,
      if (currentIndex < _filteredMovies.length - 1) currentIndex + 1,
    ];
    
    for (int index in indicesToPreload) {
      if (!_preloadedVideos.contains(index) && index < _filteredMovies.length) {
        final videoId = _filteredMovies[index]['videoId'];
        _getOrCreateController(videoId, autoPlay: index == currentIndex);
        _preloadedVideos.add(index);
      }
    }
    
    // OPTIMIZACIÓN: Limpiar videos lejanos
    _cleanupDistantVideos(currentIndex);
  }

  // OPTIMIZACIÓN: Limpiar videos que están lejos
  void _cleanupDistantVideos(int currentIndex) {
    final videosToRemove = <String>[];
    final indicesToRemove = <int>[];
    
    for (int index in _preloadedVideos) {
      if ((index - currentIndex).abs() > 2) { // Mantener solo 2 videos antes y después
        if (index < _filteredMovies.length) {
          final videoId = _filteredMovies[index]['videoId'];
          videosToRemove.add(videoId);
          indicesToRemove.add(index);
        }
      }
    }
    
    for (String videoId in videosToRemove) {
      _videoControllers[videoId]?.dispose();
      _videoControllers.remove(videoId);
    }
    
    for (int index in indicesToRemove) {
      _preloadedVideos.remove(index);
    }
  }

  // OPTIMIZACIÓN: Pausar videos que no se están viendo
  void _pausePreviousVideos(int currentIndex) {
    for (var entry in _videoControllers.entries) {
      try {
        final controller = entry.value;
        if (controller.value.isPlaying) {
          // Solo pausar si no es el video actual
          final currentVideoId = _filteredMovies[currentIndex]['videoId'];
          if (entry.key != currentVideoId) {
            controller.pause();
          }
        }
      } catch (e) {
        print('Error pausando video: $e');
      }
    }
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
          if (mounted) {
            setState(() {
              _userProfile = {
                'edad': userData['edad'] ?? 18,
                'nombre': userData['nombre'] ?? 'Usuario',
                'fotoPerfil': userData['fotoPerfil'] ?? '',
              };
            });
            
            if (_movies.isNotEmpty) {
              _filterMoviesByAge();
            }
          }
        }
      } catch (e) {
        print('Error cargando perfil: $e');
        if (mounted) {
          setState(() {
            _userProfile = {'edad': 18, 'nombre': 'Usuario'};
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _userProfile = {'edad': 18, 'nombre': 'Usuario'};
        });
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

  void _filterMoviesByAge() {
    int userAge = _userProfile['edad'] ?? 18;
    
    List<dynamic> ageFilteredMovies = _movies.where((movie) {
      String rating = movie['rating'] ?? 'PG-13';
      String genre = _getMainGenre(movie);
      
      if (userAge < 18 && genre == 'Terror') {
        return false;
      }
      
      return _canWatchContent(rating);
    }).toList();
    
    if (mounted) {
      setState(() {
        _filteredMovies = ageFilteredMovies;
      });
    }
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
        
        if (event.snapshot.exists && mounted) {
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

        if (mounted) {
          setState(() {
            _userFavorites.add(movieId);
          });
          _showSnackBar('❤️ ${movie['name']} agregada a biblioteca', Colors.red);
        }
        
      } catch (e) {
        if (mounted) {
          _showSnackBar('❌ Error al agregar a biblioteca', Colors.red);
        }
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

        if (mounted) {
          setState(() {
            _userFavorites.remove(movieId);
          });
          _showSnackBar('💔 ${movie['name']} removida de biblioteca', Colors.orange);
        }
        
      } catch (e) {
        if (mounted) {
          _showSnackBar('❌ Error al remover de biblioteca', Colors.red);
        }
      }
    }
  }

  bool _isInFavorites(Map<String, dynamic> movie) {
    String movieId = movie['name'].replaceAll(' ', '_').toLowerCase();
    return _userFavorites.contains(movieId);
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
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
  }

  // Generar ID de película para Firebase
  String _generateMovieId(String movieName) {
    return movieName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // Obtener contador de comentarios
  Future<int> _getCommentsCount(String movieName) async {
    try {
      String movieId = _generateMovieId(movieName);
      DataSnapshot snapshot = await _database
          .child('comentarios')
          .child(movieId)
          .once()
          .then((event) => event.snapshot);

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        return data.length;
      }
      return 0;
    } catch (e) {
      print('Error obteniendo contador: $e');
      return 0;
    }
  }

  Future<void> _loadMovies() async {
    try {
      String jsonString = await DefaultAssetBundle.of(context)
          .loadString("assets/data/peliculas.json");
      List movies = json.decode(jsonString);
      
      if (mounted) {
        setState(() {
          _movies = movies;
          _filteredMovies = movies; // Inicialmente mostrar todas
        });
        
        // Filtrar por edad si ya tenemos el perfil
        if (_userProfile.isNotEmpty) {
          _filterMoviesByAge();
        }
        
        setState(() {
          _isLoading = false;
        });
        
        _fadeController.forward();
        
        // OPTIMIZACIÓN: Precargar el primer video
        if (_filteredMovies.isNotEmpty) {
          _preloadAdjacentVideos(0);
        }
      }
    } catch (e) {
      print('Error cargando películas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // REQUERIDO para AutomaticKeepAliveClientMixin
    
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_filteredMovies.isEmpty) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // OPTIMIZACIÓN: PageView con configuración optimizada
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _currentIndex = index;
                  });
                  
                  // OPTIMIZACIÓN: Pausar videos anteriores y precargar siguientes
                  _pausePreviousVideos(index);
                  _preloadAdjacentVideos(index);
                }
              },
              physics: const ClampingScrollPhysics(), // OPTIMIZACIÓN: Mejor scroll
              itemCount: _filteredMovies.length,
              itemBuilder: (context, index) {
                return _buildVideoItem(_filteredMovies[index], index);
              },
            ),
            
            _buildHeader(),
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
        // OPTIMIZACIÓN: Video optimizado
        Positioned.fill(
          child: OptimizedVideoPlayer(
            key: ValueKey('video_${movie['videoId']}_$index'),
            videoId: movie['videoId'],
            isPlaying: isCurrentVideo,
            controller: _getOrCreateController(movie['videoId'], autoPlay: isCurrentVideo),
          ),
        ),
        
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
        
        Positioned(
          bottom: 20,
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
    if (_filteredMovies.isEmpty) return Container();
    
    final movie = _filteredMovies[_currentIndex];
    bool isLiked = _isInFavorites(movie);
    
    return Positioned(
      right: 12,
      bottom: 40,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.play_circle_fill,
            label: 'Ver\nCompleta',
            color: Colors.red,
            onTap: () => _navigateToFullMovie(movie),
            isPrimary: true,
          ),
          
          SizedBox(height: 24),
          
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: isLiked ? 'Guardada' : 'Guardar',
            color: isLiked ? Colors.red : Colors.white,
            onTap: () => _toggleFavorite(movie),
          ),
          
          SizedBox(height: 24),
          
          // Botón de comentarios con contador real
          FutureBuilder<int>(
            future: _getCommentsCount(movie['name']),
            builder: (context, snapshot) {
              String label = '0';
              if (snapshot.hasData) {
                int count = snapshot.data!;
                if (count >= 1000) {
                  label = '${(count / 1000).toStringAsFixed(1)}K';
                } else {
                  label = count.toString();
                }
              }
              
              return _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: label,
                color: Colors.white,
                onTap: () => _showComments(movie),
              );
            },
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
      builder: (context) => SimpleCommentsSheet(movie: movie),
    );
  }
}

// ========== REPRODUCTOR DE VIDEO OPTIMIZADO ==========

class OptimizedVideoPlayer extends StatefulWidget {
  final String videoId;
  final bool isPlaying;
  final YoutubePlayerController controller;

  const OptimizedVideoPlayer({
    super.key,
    required this.videoId,
    required this.isPlaying,
    required this.controller,
  });

  @override
  State<OptimizedVideoPlayer> createState() => _OptimizedVideoPlayerState();
}

class _OptimizedVideoPlayerState extends State<OptimizedVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(OptimizedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // OPTIMIZACIÓN: Solo cambiar estado de reproducción
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        widget.controller.play();
      } else {
        widget.controller.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return YoutubePlayer(
      controller: widget.controller,
      showVideoProgressIndicator: false,
      progressIndicatorColor: Colors.transparent,
      aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
      bottomActions: [],
      topActions: [],
      onReady: () {
        if (widget.isPlaying) {
          widget.controller.play();
        }
      },
    );
  }
}

// ========== COMENTARIOS SIMPLES ==========

class SimpleCommentsSheet extends StatefulWidget {
  final Map<String, dynamic> movie;

  const SimpleCommentsSheet({super.key, required this.movie});

  @override
  State<SimpleCommentsSheet> createState() => _SimpleCommentsSheetState();
}

class _SimpleCommentsSheetState extends State<SimpleCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  Stream<List<Map<String, dynamic>>>? _commentsStream;
  Map<String, dynamic> _userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializeCommentsStream();
  }

  void _initializeCommentsStream() {
    String movieId = _generateMovieId(widget.movie['name']);
    _commentsStream = _database
        .child('comentarios')
        .child(movieId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      List<Map<String, dynamic>> comments = [];
      
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        
        data.forEach((key, value) {
          Map<String, dynamic> comment = Map<String, dynamic>.from(value);
          comment['id'] = key;
          comments.add(comment);
        });
        
        comments.sort((a, b) {
          int timestampA = a['timestamp'] ?? 0;
          int timestampB = b['timestamp'] ?? 0;
          return timestampB.compareTo(timestampA);
        });
      }
      
      return comments;
    });
  }

  String _generateMovieId(String movieName) {
    return movieName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DataSnapshot snapshot = await _database
            .child('usuarios')
            .child(user.uid)
            .once()
            .then((event) => event.snapshot);
        
        if (snapshot.exists) {
          setState(() {
            _userProfile = Map<String, dynamic>.from(snapshot.value as Map);
          });
        }
      } catch (e) {
        print('Error cargando perfil: $e');
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      String movieId = _generateMovieId(widget.movie['name']);
      String commentText = _commentController.text.trim();
      
      await _database
          .child('comentarios')
          .child(movieId)
          .push()
          .set({
        'userId': user.uid,
        'userName': _userProfile['nombre'] ?? 'Usuario',
        'userPhoto': _userProfile['fotoPerfil'] ?? '',
        'comentario': commentText,
        'timestamp': ServerValue.timestamp,
      });

      _commentController.clear();
      _showSnackBar('Comentario agregado', Colors.green);
      
    } catch (e) {
      _showSnackBar('Error al agregar comentario', Colors.red);
      print('Error: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comentarios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.movie['name'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de comentarios
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sé el primero en comentar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '¡Comparte tu opinión sobre esta película!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final comments = snapshot.data!;
                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar del usuario
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.purple, Colors.blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: comment['userPhoto'] != null && comment['userPhoto'].isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      comment['userPhoto'],
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            (comment['userName']?.isNotEmpty == true ? comment['userName'][0] : 'U').toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      (comment['userName']?.isNotEmpty == true ? comment['userName'][0] : 'U').toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                          ),
                          
                          SizedBox(width: 12),
                          
                          // Contenido del comentario
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header del comentario
                                Row(
                                  children: [
                                    Text(
                                      comment['userName'] ?? 'Usuario',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _formatTimestamp(comment['timestamp'] ?? 0),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 6),
                                
                                // Texto del comentario
                                Text(
                                  comment['comentario'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
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
                // Avatar del usuario actual
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _userProfile['fotoPerfil'] != null && _userProfile['fotoPerfil'].isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            _userProfile['fotoPerfil'],
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  (_userProfile['nombre']?.isNotEmpty == true ? _userProfile['nombre'][0] : 'U').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            (_userProfile['nombre']?.isNotEmpty == true ? _userProfile['nombre'][0] : 'U').toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                
                SizedBox(width: 12),
                
                // Campo de texto
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: Colors.white),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu comentario...',
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                
                SizedBox(width: 8),
                
                // Botón enviar
                GestureDetector(
                  onTap: _addComment,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _commentController.text.trim().isEmpty 
                          ? Colors.grey.withOpacity(0.3)
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
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
