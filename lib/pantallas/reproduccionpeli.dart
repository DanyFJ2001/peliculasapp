import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class ReproduccionScreen extends StatefulWidget {
  final String titulo;
  final String videoId;
  final String description;
  final String year;
  final String duration;
  final String rating;
  final String image; // Cambio 1: usar 'image' del JSON
  
  const ReproduccionScreen({
    super.key, 
    required this.titulo,
    required this.videoId,
    required this.description,
    required this.year,
    required this.duration,
    required this.rating,
    required this.image, // Cambio 1: requerido
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
        autoPlay: true, // Cambio: true para que se reproduzca automáticamente
        mute: false, // Cambio: false para que tenga sonido
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
    // No necesitamos _controller.play() porque ya está en autoPlay: true
  }
  
  void _playTrailerManually() {
    _autoPlayTimer?.cancel();
    
    setState(() {
      _showVideo = true;
    });
    
    _videoFadeController.forward();
    // No necesitamos _controller.play() porque ya está en autoPlay: true
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
              image: NetworkImage(widget.image), // Cambio 2: usar widget.image directo
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
                
                // Botones de acción
                _buildActionButtons(),
                
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Botón Reproducir Película - Cambio 3
          Expanded(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton(
                onPressed: () {
                  // Sin funcionalidad por ahora
                },
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
                    Icon(Icons.play_arrow, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Reproducir',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Botón Compartir
          Expanded(
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () {
                  // Compartir película
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Compartir',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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