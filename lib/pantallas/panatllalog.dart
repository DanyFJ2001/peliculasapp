import 'package:appcine/screens/loginscreen.dart';
import 'package:appcine/screens/registroscreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(logpantalla());
}

class logpantalla extends StatelessWidget {
  const logpantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamFlix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
    
    // Delay para animación de botones
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _buttonAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://cloudfront-us-east-1.images.arcpublishing.com/infobae/4DPM42K2SNBQJIFZE7AKFJNOC4.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.95),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          
                          // Título principal con estilo iOS
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFE8E8E8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Text(
                              'StreamFlix',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subtítulo principal
                          Text(
                            'El cine en la palma de tu mano',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Subtítulo secundario
                          Text(
                            'Miles de películas y series en alta definición',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const Spacer(flex: 2),
                          
                          // Botones con animación
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                // Botón Iniciar Sesión estilo iOS
                                _buildIOSButton(
                                  text: 'Iniciar Sesión',
                                  onPressed: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                          const LoginScreen(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                      transitionDuration: const Duration(milliseconds: 300),
                                    ),
                                  ),
                                  isPrimary: true,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Botón Crear Cuenta estilo iOS
                                _buildIOSButton(
                                  text: 'Crear Cuenta',
                                  onPressed: () => Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => 
                                          const RegistroScreen(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                      transitionDuration: const Duration(milliseconds: 300),
                                    ),
                                  ),
                                  isPrimary: false,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Footer minimalista estilo iOS
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    'Contenido Premium • Sin Anuncios • HD',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(27),
          child: Container(
            decoration: BoxDecoration(
              gradient: isPrimary ? const LinearGradient(
                colors: [
                  Color(0xFF007AFF),
                  Color(0xFF0051D5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: isPrimary ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(27),
              border: isPrimary ? null : Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}