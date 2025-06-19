import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class ReproduccionScreen extends StatefulWidget {
  final String titulo;
  final String videoId;
  final String description;
  final String year;
  final String duration;
  final String rating;
  final String image;
  final String movieUrl; // Añadido movieUrl
  
  const ReproduccionScreen({
    super.key, 
    required this.titulo,
    required this.videoId,
    required this.description,
    required this.year,
    required this.duration,
    required this.rating,
    required this.image,
    required this.movieUrl, // Requerido
  });

  @override
  State<ReproduccionScreen> createState() => _ReproduccionScreenState();
}

class _ReproduccionScreenState extends State<ReproduccionScreen>
    with TickerProviderStateMixin {
  
  late YoutubePlayerController _controller;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _videoFadeController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _videoFadeAnimation;
  
  bool _showVideo = false;
  bool _showControls = true;
  Timer? _autoPlayTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Pantalla completa inmersiva
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Inicializar controlador de YouTube
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: true,
        hideControls: false,
        forceHD: true,
        enableCaption: false,
      ),
    );
    
    // Controladores de animación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _videoFadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animaciones
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _videoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _videoFadeController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar animaciones
    _animationController.forward();
    _fadeController.forward();
    
    // Animación de pulso continua
    _pulseController.repeat(reverse: true);
    
    // Auto-reproducir trailer después de 5 segundos
    _startAutoPlayTimer();
  }
  
  void _startAutoPlayTimer() {
    _autoPlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_showVideo) {
        _playTrailerAutomatically();
      }
    });
  }
  
  void _playTrailerAutomatically() {
    setState(() {
      _showVideo = true;
    });
    
    _videoFadeController.forward();
  }
  
  void _playTrailerManually() {
    _autoPlayTimer?.cancel();
    
    setState(() {
      _showVideo = true;
    });
    
    _videoFadeController.forward();
  }

  // Función para reproducir la película completa
  void _playMovie() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MoviePlayerScreen(
          movieUrl: widget.movieUrl,
          movieTitle: widget.titulo,
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _autoPlayTimer?.cancel();
    _controller.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _videoFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con imagen de la película
          _buildMovieBackground(),
          
          // Video del trailer (aparece después de un tiempo)
          if (_showVideo) _buildVideoPlayer(),
          
          // Overlay con gradientes
          _buildGradientOverlay(),
          
          // Contenido principal
          _buildMainContent(),
          
          // Botón de regreso
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildMovieBackground() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _videoFadeAnimation,
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: false,
          progressIndicatorColor: Colors.transparent,
          aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
          bottomActions: [],
          topActions: [],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.9),
            ],
            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned.fill(
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Botón de play grande en el centro
                if (!_showVideo) _buildPlayButton(),
                
                const Spacer(flex: 2),
                
                // Información de la película
                _buildMovieInfo(),
                
                const SizedBox(height: 40),
                
                // Botón de acción
                _buildActionButton(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: _playTrailerManually,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                  size: 50,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Título
          Text(
            widget.titulo,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Información adicional
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '${widget.year} • ${widget.duration} • ${widget.rating}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Descripción
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _playMovie, // Llama a la función para reproducir la película
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 24),
              SizedBox(width: 8),
              Text(
                'Reproducir Película',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// Nueva pantalla para reproducir la película completa
class MoviePlayerScreen extends StatefulWidget {
  final String movieUrl;
  final String movieTitle;
  
  const MoviePlayerScreen({
    super.key,
    required this.movieUrl,
    required this.movieTitle,
  });

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  late VideoPlayerController _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.movieUrl));
      await _videoController.initialize();
      _videoController.setLooping(false);
      _videoController.play();
      
      setState(() {
        _isLoading = false;
      });
      
      _startHideControlsTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _videoController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video Player
            if (!_isLoading && !_hasError)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),
            
            // Loading
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            
            // Error
            if (_hasError)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Error al cargar el video',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            
            // Controls
            if (_showControls && !_isLoading && !_hasError)
              _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        children: [
          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.movieTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Bottom controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress bar
                VideoProgressIndicator(
                  _videoController,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.black54,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Retroceder 10 segundos
                    GestureDetector(
                      onTap: () {
                        final currentPosition = _videoController.value.position;
                        final newPosition = currentPosition - const Duration(seconds: 10);
                        _videoController.seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                        _startHideControlsTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.replay_10,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Play/Pause button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoController.value.isPlaying
                              ? _videoController.pause()
                              : _videoController.play();
                        });
                        _startHideControlsTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          _videoController.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Adelantar 10 segundos
                    GestureDetector(
                      onTap: () {
                        final currentPosition = _videoController.value.position;
                        final totalDuration = _videoController.value.duration;
                        final newPosition = currentPosition + const Duration(seconds: 10);
                        _videoController.seekTo(newPosition > totalDuration ? totalDuration : newPosition);
                        _startHideControlsTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.forward_10,
                          color: Colors.white,
                          size: 28,
                        ),
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
}