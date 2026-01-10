/// Servicio de Autenticación para el sistema POS
/// 
/// Este servicio maneja toda la lógica de autenticación, incluyendo:
/// - Login y logout de usuarios
/// - Validación de credenciales  
/// - Gestión de sesiones activas
/// - Timeouts de inactividad

import 'dart:async';
import 'package:pov_suplementos/auth/modelo_usuario.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';

/// Servicio principal para manejar autenticación
class Autenticacion {

  static final Autenticacion _instancia = Autenticacion._internal();
  factory Autenticacion() => _instancia;
  Autenticacion._internal();

  // Estado actual del usuario
  Usuario? _usuarioActual;
  DateTime? _ultimaActividad;
  Timer? _tempSesion;

  // Configuración de sesión
  static const Duration tiempoSesion = Duration(minutes: 30);
  
  // Stream para notificar cambios de estado de autenticación
  final StreamController<Usuario?> _usuarioStreamControlador = StreamController<Usuario?>.broadcast();
  Stream<Usuario?> get userStream => _usuarioStreamControlador.stream;

  /// Usuario actualmente autenticado (null si no hay sesión activa)
  Usuario? get usuarioActual => _usuarioActual;

  int get id => _usuarioActual?.id ?? -1;
  
  bool get estaAutenticado => _usuarioActual != null;

  bool get esAdmin => _usuarioActual?.esAdmin ?? false;

  bool get puedeVender => _usuarioActual?.puedeVender ?? false;

  bool get puedeVerReportes => _usuarioActual?.puedeManejarReportes ?? false;

  /// Realiza el proceso de login
  /// Retorna [AutenticacionResultado] con el resultado del login
  Future<AutenticacionResultado> login(String username, String password) async {
    try {
      // Validar parámetros de entrada
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return AutenticacionResultado.fallo('Usuario y contraseña son requeridos');
      }

      // Validar credenciales en la base de datos
      final result = await Basededatos.validarCredenciales(
        username.trim().toLowerCase(),
        password,
      );

      if (result['valido'] != true) {
        return AutenticacionResultado.fallo(result['mensaje'] ?? 'Credenciales inválidas');
      }

      // Establecer sesión activa
      _usuarioActual = result['usuario'] as Usuario;
      _ultimaActividad = DateTime.now();
      _empezarTempSesion();

      // Notificar a los listeners que hay un nuevo usuario autenticado
      _usuarioStreamControlador.add(_usuarioActual);

      return AutenticacionResultado.exito(_usuarioActual!, 'Login exitoso');

    } catch (e) {
      return AutenticacionResultado.fallo('Error durante el login: $e');
    }
  }

  /// Cierra la sesión del usuario actual
  void cerrarSesion() {
    _usuarioActual = null;
    _ultimaActividad = null;
    _detenerTempSesion();
    
    // Notificar que ya no hay usuario autenticado
    _usuarioStreamControlador.add(null);
  }

  /// Actualiza la actividad del usuario para resetear el timeout
  void actualizarActividad() {
    if (estaAutenticado) {
      _ultimaActividad = DateTime.now();
      _reiniciarTempSesion();
    }
  }

  /// Inicia el temporizador de sesión para timeout automático
  void _empezarTempSesion() {
    _detenerTempSesion(); // Detener timer anterior si existe
    
    _tempSesion = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (_deberiaExpirarSesion()) {
        cerrarSesion();
        timer.cancel();
      }
    });
  }

  void _detenerTempSesion() {
    _tempSesion?.cancel();
    _tempSesion = null;
  }
  void _reiniciarTempSesion() {
    if (_tempSesion?.isActive == true) {
      _empezarTempSesion();
    }
  }

  /// Verifica si la sesión debe expirar por inactividad
  bool _deberiaExpirarSesion() {
    if (_ultimaActividad == null || !estaAutenticado) {
      return true;
    }
    
    final tiempoDesdeUltimaActividad = DateTime.now().difference(_ultimaActividad!);
    return tiempoDesdeUltimaActividad >= tiempoSesion;
  }

  /// Obtiene el tiempo restante de la sesión
  Duration? get tiempoRestanteParaExpiracion {
    if (_ultimaActividad == null || !estaAutenticado) return null;
    
    final transcurrido = DateTime.now().difference(_ultimaActividad!);
    final restante = tiempoSesion - transcurrido;
    
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Verifica si el usuario actual tiene un rol específico
  bool tieneRol(RolUsuario rol) {
    return _usuarioActual?.rol == rol;
  }

  /// Verifica si el usuario actual tiene al menos el nivel de permisos especificado
  bool tieneRolMinimo(RolUsuario rolMinimo) {
    if (_usuarioActual == null) return false;
    
    // Jerarquía de roles (mayor número = más permisos)
    final rolActual = _usuarioActual!.rol.id;
    final rolRequerido = rolMinimo.id;
    
    return rolActual <= rolRequerido; // Menor ID = mayor jerarquía
  }

  /// Crea un nuevo usuario (solo admins)
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    required RolUsuario role,
  }) async {
    // Verificar permisos
    if (!esAdmin) {
      return {
        'exito': false,
        'mensaje': 'No tiene permisos para crear usuarios',
      };
    }

    // Validar datos
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return {
        'exito': false,
        'mensaje': 'Usuario y contraseña son requeridos',
      };
    }

    if (password.length < 4) {
      return {
        'exito': false,
        'mensaje': 'La contraseña debe tener al menos 4 caracteres',
      };
    }

    // Crear usuario
    final newUser = Usuario(
      nombre: username.trim().toLowerCase(),
      contrasena: password,
      rol: role,
    );

    return await Basededatos.crearUsuario(newUser);
  }

  /// Obtiene lista de usuarios (solo admins)
  Future<Map<String, dynamic>> getAllUsers() async {
    if (!esAdmin) {
      return {
        'exito': false,
        'mensaje': 'No tiene permisos para ver usuarios',
        'usuarios': <Usuario>[],
      };
    }

    return await Basededatos.obtenerTodosLosUsuarios();
  }

  /// Cambia la contraseña del usuario actual
  Future<Map<String, dynamic>> cambiarContrasena(
    String contrasenaActual,
    String nuevaContrasena,
  ) async {
    if (!estaAutenticado) {
      return {
        'exito': false,
        'mensaje': 'Debe estar autenticado para cambiar contraseña',
      };
    }

    // Validar contraseña actual
    final validacionResultados = await Basededatos.validarCredenciales(
      _usuarioActual!.nombre,
      contrasenaActual,
    );

    if (validacionResultados['valido'] != true) {
      return {
        'exito': false,
        'mensaje': 'La contraseña actual es incorrecta',
      };
    }

    // Validar nueva contraseña
    if (nuevaContrasena.length < 4) {
      return {
        'exito': false,
        'mensaje': 'La nueva contraseña debe tener al menos 4 caracteres',
      };
    }

    return await Basededatos.cambiarContrasena(_usuarioActual!.id!, nuevaContrasena);
  }

  /// Libera recursos al destruir el servicio
  void dispose() {
    _detenerTempSesion();
    _usuarioStreamControlador.close();
  }
}