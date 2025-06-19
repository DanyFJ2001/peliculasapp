import 'package:appcine/pantallas/panatllalog.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await Supabase.initialize(
    url: 'https://czaffqfczhddlmxnbfao.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN6YWZmcWZjemhkZGxteG5iZmFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2NDQwMzYsImV4cCI6MjA2NTIyMDAzNn0.XafLg4MWf1MhZRQEW8N1DErug4L9c1Bvk6HaV22DsOs',
  );
  
  runApp(StreamFlixApp());
}

class StreamFlixApp extends StatelessWidget {
  const StreamFlixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamFlix',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'SF Pro Display', // Fuente estilo iOS
        scaffoldBackgroundColor: const Color(0xFF000000),
      ),
      home: const PantallaBienvenida(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida>
    with TickerProviderStateMixin {
  
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  
  // Lista de imágenes de películas populares (puedes cambiar estas URLs)
  final List<String> _movieImages = [
    'https://i.pinimg.com/736x/f6/73/49/f67349a27cd2819ec96cd6cf66d9b62c.jpg',
    'https://i.pinimg.com/736x/2c/dd/6a/2cdd6aa54fae05d3bd1ad24a98b0bd95.jpg', // Cinema
    'https://i.pinimg.com/736x/18/5b/01/185b01d9295e9e1d4106a05c401da0e4.jpg', // Movies
    'https://i.pinimg.com/736x/d4/60/c7/d460c770509372adb94db3c609db8735.jpg', // Theater
    'https://i.pinimg.com/736x/b2/12/14/b21214fb3ff3db8ba3b9f8deb780d522.jpg', // Film
     // Cinema hall
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
    
    // Delay para la animación del botón
    Future.delayed(const Duration(milliseconds: 1500), () {
      _buttonAnimationController.forward();
    });

    // Auto-scroll del carrusel
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextPage();
        _startAutoSlide();
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _movieImages.length - 1) {
      _currentPage++;
    } else {
      _currentPage = 0;
    }
    
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Carrusel de imágenes a pantalla completa
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _movieImages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(_movieImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Indicadores de página estilo iOS
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_movieImages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Contenido inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título principal elegante
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFE1E1E1),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'StreamFlix',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtítulo
                        Text(
                          'El cine en la palma de tu mano',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Miles de películas • Series • Documentales',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Botón Empezar estilo iOS
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            onTap: () {
                              // Navegar a login o pantalla principal
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => 
                                      const logpantalla(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF007AFF), // iOS Blue
                                    Color(0xFF0051D5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF007AFF).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Empezar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}