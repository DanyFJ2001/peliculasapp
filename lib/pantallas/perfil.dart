import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PerfilScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final List<String> userFavorites;
  final List<dynamic> allMovies;
  final VoidCallback onProfileUpdate;

  const PerfilScreen({
    super.key,
    required this.userProfile,
    required this.userFavorites,
    required this.allMovies,
    required this.onProfileUpdate,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildProfileInfo(),
                const SizedBox(height: 30),
                _buildProfileStats(),
                const SizedBox(height: 30),
                _buildProfileOptions(),
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
            'Perfil',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showSignOutDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.logout,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    String userName = widget.userProfile['nombre'] ?? 'Cargando...';
    String userEmail = widget.userProfile['correo'] ?? '';
    int userAge = widget.userProfile['edad'] ?? 0;
    
    // ← AQUÍ ESTÁ LA CLAVE: obtener la URL de la imagen de Supabase
    String? fotoPerfil = widget.userProfile['fotoPerfil'];
    
    // Debug: para verificar que la URL llegue correctamente
    print('🖼️ URL de imagen en perfil: $fotoPerfil');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.15),
            Colors.purple.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar con imagen del usuario desde Supabase
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Imagen del usuario o icono por defecto
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Solo aplicar gradiente si no hay imagen
                    gradient: (fotoPerfil == null || fotoPerfil.isEmpty) 
                        ? LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) 
                        : null,
                  ),
                  child: (fotoPerfil != null && fotoPerfil.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          fotoPerfil,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Error cargando imagen: $error');
                            // Si falla cargar la imagen, mostrar icono por defecto
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ Imagen cargada exitosamente');
                              return child;
                            }
                            print('⏳ Cargando imagen...');
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                ),
                
                // Botón de editar avatar
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Nombre del usuario
          Text(
            userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Email
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información de edad y restricciones
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: userAge >= 18 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: userAge >= 18 
                        ? Colors.green.withOpacity(0.4)
                        : Colors.orange.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userAge >= 18 ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: userAge >= 18 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$userAge años',
                      style: TextStyle(
                        color: userAge >= 18 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  userAge >= 18 ? 'Sin restricciones' : 'Control parental',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Películas en biblioteca
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.userFavorites.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'En biblioteca',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Contenido disponible
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.movie_filter,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.allMovies.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Disponibles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Editar perfil
          _buildProfileOption(
            icon: Icons.edit,
            title: 'Editar perfil',
            subtitle: 'Cambiar nombre y configuraciones',
            onTap: _showEditProfileDialog,
          ),
          
          const SizedBox(height: 12),
          
          // Control parental
          _buildProfileOption(
            icon: Icons.family_restroom,
            title: 'Control parental',
            subtitle: 'Configurar restricciones de edad',
            onTap: _showParentalControlDialog,
          ),
          
          const SizedBox(height: 12),
          
          // Configuración de notificaciones
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            subtitle: 'Gestionar alertas y recordatorios',
            onTap: _showNotificationSettings,
          ),
          
          const SizedBox(height: 12),
          
          // Información de cuenta
          _buildProfileOption(
            icon: Icons.info_outline,
            title: 'Información de cuenta',
            subtitle: 'Ver detalles de tu cuenta',
            onTap: _showAccountInfoDialog,
          ),
          
          const SizedBox(height: 12),
          
          // Ayuda y soporte
          _buildProfileOption(
            icon: Icons.help_outline,
            title: 'Ayuda y soporte',
            subtitle: 'Centro de ayuda y contacto',
            onTap: _showHelpDialog,
          ),
          
          const SizedBox(height: 24),
          
          // Cerrar sesión
          _buildProfileOption(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta',
            onTap: _showSignOutDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ========== MÉTODOS DE DIÁLOGOS ==========

  void _showEditProfileDialog() {
    TextEditingController nameController = TextEditingController(
      text: widget.userProfile['nombre']
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar perfil', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar', 
              style: TextStyle(color: Colors.white.withOpacity(0.6))
            ),
          ),
          TextButton(
            onPressed: () {
              _updateUserProfile({'nombre': nameController.text.trim()});
              Navigator.pop(context);
            },
            child: const Text(
              'Guardar', 
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)
            ),
          ),
        ],
      ),
    );
  }

  void _showParentalControlDialog() {
    int currentAge = widget.userProfile['edad'] ?? 18;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Control parental', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edad actual: $currentAge años',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Restricciones activas:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8), 
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 8),
            if (currentAge < 13) 
              const Text(
                '• Solo contenido G y PG', 
                style: TextStyle(color: Colors.orange, fontSize: 14)
              )
            else if (currentAge < 18)
              const Text(
                '• Contenido hasta PG-13', 
                style: TextStyle(color: Colors.orange, fontSize: 14)
              )
            else
              const Text(
                '• Sin restricciones', 
                style: TextStyle(color: Colors.green, fontSize: 14)
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                'Las restricciones de edad se basan en la calificación de contenido estándar (G, PG, PG-13, R).',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido', 
              style: TextStyle(color: Colors.blue)
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Configuración de notificaciones', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationTile('Nuevos estrenos', true),
            _buildNotificationTile('Recomendaciones personalizadas', true),
            _buildNotificationTile('Recordatorios de películas', false),
            _buildNotificationTile('Promociones especiales', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar', 
              style: TextStyle(color: Colors.blue)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(String title, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {
              // Implementar lógica de cambio
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _showAccountInfoDialog() {
    String fechaRegistro = widget.userProfile['fechaRegistro'] ?? '';
    DateTime? fecha = DateTime.tryParse(fechaRegistro);
    String fechaFormateada = fecha != null 
        ? '${fecha.day}/${fecha.month}/${fecha.year}'
        : 'No disponible';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Información de cuenta', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email:', widget.userProfile['correo'] ?? ''),
            _buildInfoRow('Edad:', '${widget.userProfile['edad'] ?? 0} años'),
            _buildInfoRow('Miembro desde:', fechaFormateada),
            _buildInfoRow('Películas guardadas:', '${widget.userFavorites.length}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Cuenta verificada',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar', 
              style: TextStyle(color: Colors.blue)
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Ayuda y soporte', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpOption('📋 Preguntas frecuentes'),
            _buildHelpOption('💬 Chat en vivo'),
            _buildHelpOption('📧 Contactar soporte'),
            _buildHelpOption('📖 Guía de usuario'),
            _buildHelpOption('🔄 Reportar problema'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar', 
              style: TextStyle(color: Colors.blue)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withOpacity(0.3),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7), 
                fontWeight: FontWeight.w500
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cerrar sesión', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
        ),
        content: const Text(
          '¿Estás seguro que quieres cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar', 
              style: TextStyle(color: Colors.white.withOpacity(0.6))
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text(
              'Cerrar sesión', 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)
            ),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS DE FIREBASE ==========

  Future<void> _updateUserProfile(Map<String, dynamic> updates) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _database
            .child('usuarios')
            .child(user.uid)
            .update(updates);
        
        widget.onProfileUpdate();
        
        _showSnackBar(
          'Perfil actualizado correctamente', 
          Icons.check_circle, 
          Colors.green
        );
      } catch (e) {
        _showSnackBar(
          'Error al actualizar perfil', 
          Icons.error, 
          Colors.red
        );
        print('Error actualizando perfil: $e');
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', 
          (route) => false
        );
      }
    } catch (e) {
      _showSnackBar('Error al cerrar sesión', Icons.error, Colors.red);
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
}