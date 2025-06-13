import 'package:appcine/screens/loginscreen.dart';
import 'package:appcine/screens/pantallaPrincipalscreeen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // ← Agregar este import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen>
    with TickerProviderStateMixin {
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  
  late AnimationController _animationController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _buttonController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _edadController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.black,
              const Color(0xFF1a1a1a),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height - 
                     MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Header con botón de regreso
                  _buildHeader(context),
                  
                  // Contenido principal
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Título
                              _buildTitle(),
                              
                              const SizedBox(height: 40),
                              
                              // Formulario
                              _buildForm(),
                              
                              const SizedBox(height: 32),
                              
                              // Botón de registro
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildRegisterButton(),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Enlaces adicionales
                              _buildAdditionalLinks(),
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
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE1E1E1),
            ],
          ).createShader(bounds),
          child: const Text(
            'Crear Cuenta',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Únete a la comunidad StreamFlix',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Campo de nombre
        _buildTextField(
          controller: _nombreController,
          label: 'Nombre Completo',
          icon: Icons.person_outline,
          keyboardType: TextInputType.name,
        ),
        
        const SizedBox(height: 16),
        
        // Campo de email
        _buildTextField(
          controller: _correoController,
          label: 'Correo Electrónico',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 16),
        
        // Campo de edad
        _buildTextField(
          controller: _edadController,
          label: 'Edad',
          icon: Icons.cake_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Campo de contraseña
        _buildTextField(
          controller: _contrasenaController,
          label: 'Contraseña',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.6),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        
        // Indicador de fortaleza de contraseña
        if (_contrasenaController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPasswordStrengthIndicator(),
        ],
        
        // Mensaje de error
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        onChanged: (value) {
          if (controller == _contrasenaController) {
            setState(() {});
          }
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.6),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    String password = _contrasenaController.text;
    int strength = _calculatePasswordStrength(password);
    
    Color strengthColor;
    String strengthText;
    
    switch (strength) {
      case 0:
      case 1:
        strengthColor = Colors.red;
        strengthText = 'Débil';
        break;
      case 2:
        strengthColor = Colors.orange;
        strengthText = 'Media';
        break;
      case 3:
        strengthColor = Colors.yellow;
        strengthText = 'Buena';
        break;
      case 4:
        strengthColor = Colors.green;
        strengthText = 'Fuerte';
        break;
      default:
        strengthColor = Colors.red;
        strengthText = 'Débil';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fortaleza: ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 2,
        ),
      ],
    );
  }

  int _calculatePasswordStrength(String password) {
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    return strength > 4 ? 4 : strength;
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleRegister,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF007AFF),
                  Color(0xFF0051D5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Crear Cuenta',
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
    );
  }

  Widget _buildAdditionalLinks() {
    return Column(
      children: [
        Text(
          'Al registrarte, aceptas nuestros Términos y Condiciones',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿Ya tienes cuenta? ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        const LoginScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              child: const Text(
                'Inicia Sesión',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ← AQUÍ ESTÁ LA FUNCIÓN PRINCIPAL CON AUTHENTICATION + DATABASE
  void _handleRegister() async {
    // Validaciones
    if (_nombreController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa tu nombre';
      });
      return;
    }

    if (_correoController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa tu correo electrónico';
      });
      return;
    }

    if (_edadController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa tu edad';
      });
      return;
    }

    int? edad = int.tryParse(_edadController.text.trim());
    if (edad == null || edad < 13) {
      setState(() {
        _errorMessage = 'Debes tener al menos 13 años para registrarte';
      });
      return;
    }

    if (_contrasenaController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa una contraseña';
      });
      return;
    }

    if (_contrasenaController.text.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. Crear usuario en Authentication
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _contrasenaController.text,
      );

      // 2. Actualizar el perfil del usuario con el nombre
      await credential.user?.updateDisplayName(_nombreController.text.trim());

      // 3. Guardar datos adicionales en Realtime Database
      await _guardarUsuarioEnDatabase(credential.user!.uid);

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Cuenta creada exitosamente! Bienvenido ${_nombreController.text.trim()}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navegar a login
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error al crear la cuenta';
      
      switch (e.code) {
        case 'weak-password':
          message = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          message = 'Ya existe una cuenta con este correo';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        case 'operation-not-allowed':
          message = 'Operación no permitida';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado. Intenta nuevamente';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ← FUNCIÓN PARA GUARDAR EN REALTIME DATABASE
  Future<void> _guardarUsuarioEnDatabase(String userId) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("usuarios/$userId");
    
    await ref.set({
      "nombre": _nombreController.text.trim(),
      "correo": _correoController.text.trim(),
      "edad": int.parse(_edadController.text.trim()),
      "fechaRegistro": DateTime.now().toIso8601String(),
      "peliculasFavoritas": [], // Lista vacía inicial
      "ultimaActividad": DateTime.now().toIso8601String(),
    });
  }
}