import 'dart:io';
import 'package:appcine/screens/loginscreen.dart';
import 'package:appcine/screens/pantallaPrincipalscreeen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  // Variables para la imagen
  XFile? _imagen;
  bool _isUploadingImage = false;
  String? _imageUrl;

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

  // Función para actualizar la imagen
  void actualizarImagen(XFile? nuevaImagen) {
    setState(() {
      _imagen = nuevaImagen;
    });
  }

  // Función para abrir la cámara
  Future<void> abrirCamara(Function actualizarImagen) async {
    final imagenSeleccionada = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imagenSeleccionada != null) {
      actualizarImagen(imagenSeleccionada);
    }
  }

  // Función para abrir la galería
  Future<void> abrirGaleria(void Function(XFile?) actualizarImagen) async {
    final imagenSeleccionada = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imagenSeleccionada != null) {
      actualizarImagen(imagenSeleccionada);
    }
  }

  // Función para subir imagen a Supabase
  Future<String?> subirImagen(XFile? imagen) async {
    if (imagen == null) return null;
    
    try {
      setState(() {
        _isUploadingImage = true;
      });
      
      final supabase = Supabase.instance.client;
      final avatarFile = File(imagen.path);
      
      // Generar un nombre único para la imagen
      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final String fullPath = await supabase.storage.from('usuarios').upload(
        'public/$fileName',
        avatarFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      // Obtener la URL pública de la imagen
      final String publicUrl = supabase.storage.from('usuarios').getPublicUrl('public/$fileName');
      
      return publicUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
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
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
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
                                
                                const SizedBox(height: 24),
                                
                                // Sección de foto de perfil
                                _buildProfileImageSection(),
                                
                                const SizedBox(height: 24),
                                
                                // Formulario
                                _buildForm(),
                                
                                const SizedBox(height: 24),
                                
                                // Botón de registro
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: _buildRegisterButton(),
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Enlaces adicionales
                                _buildAdditionalLinks(),
                                
                                const SizedBox(height: 20),
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
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Únete a la comunidad StreamFlix',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      children: [
        // Avatar circular
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _imagen == null
                ? Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipOval(
                        child: Image.file(
                          File(_imagen!.path),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007AFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          _imagen == null ? 'Agregar foto de perfil' : 'Cambiar foto',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // Indicador de carga de imagen
        if (_isUploadingImage) ...[
          const SizedBox(height: 6),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              strokeWidth: 2,
            ),
          ),
        ],
      ],
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador superior
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Seleccionar foto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                // Botón Cámara
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      abrirCamara(actualizarImagen);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cámara',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Botón Galería
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      abrirGaleria(actualizarImagen);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Galería',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
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
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
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
          onTap: (_isLoading || _isUploadingImage) ? null : _handleRegister,
          borderRadius: BorderRadius.circular(25),
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
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: (_isLoading || _isUploadingImage)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Crear Cuenta',
                      style: TextStyle(
                        fontSize: 16,
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

  // Función principal de registro con subida de imagen
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
      // 1. Subir imagen a Supabase si existe
      String? imageUrl;
      if (_imagen != null) {
        imageUrl = await subirImagen(_imagen);
      }

      // 2. Crear usuario en Authentication
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _contrasenaController.text,
      );

      // 3. Actualizar el perfil del usuario con el nombre
      await credential.user?.updateDisplayName(_nombreController.text.trim());

      // 4. Guardar datos adicionales en Realtime Database incluyendo la URL de la imagen
      await _guardarUsuarioEnDatabase(credential.user!.uid, imageUrl);

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

  // Función para guardar en Realtime Database incluyendo la URL de la imagen
  Future<void> _guardarUsuarioEnDatabase(String userId, String? imageUrl) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("usuarios/$userId");
    
    await ref.set({
      "nombre": _nombreController.text.trim(),
      "correo": _correoController.text.trim(),
      "edad": int.parse(_edadController.text.trim()),
      "fechaRegistro": DateTime.now().toIso8601String(),
      "peliculasFavoritas": [], // Lista vacía inicial
      "ultimaActividad": DateTime.now().toIso8601String(),
      "fotoPerfil": imageUrl, // URL de la imagen de perfil
    });
  }
}