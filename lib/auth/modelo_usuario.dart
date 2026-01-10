/// Modelo de Usuario para el sistema POS
/// 
/// Este archivo define la estructura de datos de los usuarios del sistema.
/// Incluye validaciones, serialización y roles de usuario.

/// Enumeración de roles disponibles en el sistema
enum RolUsuario {
  admin(1, 'Administrador'),
  cajero(2, 'Cajero'), 
  supervisor(3, 'Supervisor');
  

  const RolUsuario(this.id, this.nombre);
  
  final int id;
  final String nombre;
  
  /// Convierte un ID numérico a UserRole
  static RolUsuario segunID(int id) {
    return RolUsuario.values.firstWhere(
      (rol) => rol.id == id,
      orElse: () => RolUsuario.cajero, // Rol por defecto
    );
  }
}


/// Clase modelo para representar un usuario del sistema
class Usuario {
  final int? id;           // ID autoincremental de la base de datos
  final String nombre;     // Nombre de usuario único
  final String contrasena; // Contraseña (se guardará hasheada)
  final RolUsuario rol;      // Rol del usuario
  final DateTime? ultimoAcceso; // Último acceso registrado
  final bool activo;       // Si el usuario está activo o no

  const Usuario({
    this.id,
    required this.nombre,
    required this.contrasena,
    required this.rol,
    this.ultimoAcceso,
    this.activo = true,
  });

  /// Constructor para crear un usuario desde datos de base de datos
  factory Usuario.fromMap(Map<String, dynamic> map) {
    // Manejo seguro del campo rol
    int rolId;
    if (map['rol'] is int) {
      rolId = map['rol'] as int;
    } else if (map['rol'] is String) {
      rolId = int.parse(map['rol'] as String);
    } else {
      rolId = RolUsuario.cajero.id; // Default fallback
    }
    
    return Usuario(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      contrasena: map['contrasena'] as String,
      rol: RolUsuario.segunID(rolId),
      ultimoAcceso: map['ultimo_acceso'] != null 
          ? DateTime.parse(map['ultimo_acceso'] as String)
          : null,
      activo: (map['activo'] as int) == 1,
    );
  }

  /// Convierte el usuario a formato Map
  Map<String, dynamic> aMapa() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'contrasena': contrasena,
      'rol': rol.id,
      'ultimo_acceso': ultimoAcceso?.toIso8601String(),
      'activo': activo ? 1 : 0,
    };
  }

  /// Crea una copia del usuario con algunos campos modificados
  Usuario copiarUsuario({
    int? id,
    String? nombre,
    String? contrasena,
    RolUsuario? rol,
    DateTime? ultimoAcceso,
    bool? activo,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      contrasena: contrasena ?? this.contrasena,
      rol: rol ?? this.rol,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
      activo: activo ?? this.activo,
    );
  }

  /// Verifica si el usuario tiene permisos de administrador
  bool get esAdmin => rol == RolUsuario.admin;
  
  /// Verifica si el usuario puede realizar ventas
  bool get puedeVender => rol == RolUsuario.cajero || rol == RolUsuario.supervisor || rol == RolUsuario.admin;
  
  /// Verifica si el usuario puede ver reportes
  bool get puedeManejarReportes => rol == RolUsuario.supervisor || rol == RolUsuario.admin;

  /// Representación en string del usuario
  @override
  String toString() {
    return 'Usuario(id: $id, nombre: $nombre, rol: ${rol.nombre}, activo: $activo)';
  }

  /// Comparación de usuarios
  @override
  bool operator == (Object otro) {
    if (identical(this, otro)) return true;
    return otro is Usuario &&
        otro.id == id &&
        otro.nombre == nombre;
  }

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode;
}

/// Clase para manejar la respuesta de autenticación
class AutenticacionResultado {
  final bool exito;
  final String mensaje;
  final Usuario? usuario;
  final String? error;

  const AutenticacionResultado({
    required this.exito,
    required this.mensaje,
    this.usuario,
    this.error,
  });


  factory AutenticacionResultado.exito(Usuario usuario, [String mensaje = 'Login exitoso']) {
    return AutenticacionResultado(
      exito: true,
      mensaje: mensaje,
      usuario: usuario,
    );
  }

  /// Constructor para resultado fallido
  factory AutenticacionResultado.fallo(String error) {
    return AutenticacionResultado(
      exito: false,
      mensaje: error,
      error: error,
    );
  }
}