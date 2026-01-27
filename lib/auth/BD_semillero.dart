
import 'package:pov_suplementos/auth/modelo_usuario.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';

class DBSemillero {

  static Future<void> createSampleUsers() async {
    await listarTodosLosUsuarios();
    await ensureAdminExists();
    
    try {
      final existingCajero = await Basededatos.buscarUsuarioPorNombre('cajero');
      if (!existingCajero['encontrado']) {
        final cajeroResult = await Basededatos.crearUsuario(
          Usuario(
            nombre: 'cajero',
            contrasena: 'caja123',
            rol: RolUsuario.cajero,
              ),
            );
        
        if (cajeroResult['exito']) {
          print('✅ Usuario cajero creado: caja123');
        } else {
          print('❌ Error creando cajero: ${cajeroResult['mensaje']}');
        }
      } else {
        print('✅ Usuario cajero ya existe');
      }
      
      // Crear usuario supervisor solo si no existe
      final existingSupervisor = await Basededatos.buscarUsuarioPorNombre('supervisor');
      if (!existingSupervisor['encontrado']) {
        final supervisorResult = await Basededatos.crearUsuario(
          Usuario(
            nombre: 'supervisor',
            contrasena: 'super123',
            rol: RolUsuario.supervisor,
          ),
        );
        
        if (supervisorResult['exito']) {
          print('✅ Usuario supervisor creado: super123');
        } else {
          print('❌ Error creando supervisor: ${supervisorResult['mensaje']}');
        }
      } else {
        print('✅ Usuario supervisor ya existe');
      }
      
      print('\n📋 Usuarios disponibles:');
      print('👤 admin      (contraseña: admin123)    - Rol: Administrador');
      print('👤 cajero     (contraseña: caja123)     - Rol: Cajero');
      print('👤 supervisor (contraseña: super123)    - Rol: Supervisor');
      print('\n🎉 Inicialización completada!\n');
      
      
    } catch (e) {
      print('❌ Error durante la inicialización: $e');
    }
  }
  
  /// Asegura que el usuario admin exista
  static Future<void> ensureAdminExists() async {
    try {
      final adminCheck = await Basededatos.buscarUsuarioPorNombre('admin');
      if (!adminCheck['encontrado']) {
        print('⚠️ Usuario admin no encontrado, creándolo...');
        final result = await Basededatos.crearUsuario(
          Usuario(
            nombre: 'admin',
            contrasena: 'admin123',
            rol: RolUsuario.admin,
          ),
        );
        if (result['exito']) {
          print('✅ Usuario admin creado exitosamente');
        } else {
          print('❌ Error creando admin: ${result['mensaje']}');
        }
      } else {
        print('✅ Usuario admin ya existe');
      }
    } catch (e) {
      print('❌ Error verificando admin: $e');
    }
  }
  
  /// Lista todos los usuarios existentes
  static Future<void> listarTodosLosUsuarios() async {
    try {
      final result = await Basededatos.obtenerTodosLosUsuarios();
      
      if (result['exito']) {
        final users = result['usuarios'] as List<Usuario>;
        print('\n📋 Usuarios en la base de datos:');
        print('═══════════════════════════════════════');
        
        for (final user in users) {
          final status = user.activo ? '🟢 Activo' : '🔴 Inactivo';
          final lastAccess = user.ultimoAcceso != null 
              ? user.ultimoAcceso!.toString().substring(0, 19)
              : 'Nunca';
              
          print('ID: ${user.id?.toString().padLeft(2)} | ${user.nombre.padRight(12)} | ${user.rol.nombre.padRight(12)} | $status | Último acceso: $lastAccess');
        }
        print('═══════════════════════════════════════\n');
      } else {
        print('❌ Error obteniendo usuarios: ${result['mensaje']}');
      }
    } catch (e) {
      print('❌ Error listando usuarios: $e');
    }
  }
  


}