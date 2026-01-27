/// Gestor de Sesiones para el sistema POS
/// 
/// Este widget maneja el estado global de autenticación de la aplicación:
/// - Redirige automáticamente al login si no hay sesión activa
/// - Mantiene la sesión durante la navegación
/// - Muestra información del usuario actual
/// - Actualiza automáticamente la actividad del usuario

import 'package:flutter/material.dart';
import 'package:pov_suplementos/auth/autenticacion.dart';
import 'package:pov_suplementos/auth/modelo_usuario.dart';


class GestorDeSesion extends StatefulWidget {
  final Widget child;
  final Widget Function() paginaDeInicioBuilder;
  final VoidCallback? alExpirarSesion;

  const GestorDeSesion    ({
    super.key,
    required this.child,
    required this.paginaDeInicioBuilder,
    this.alExpirarSesion,
  });

  @override
  State<GestorDeSesion> createState() => _GestorDeSesionState();
}

class _GestorDeSesionState extends State<GestorDeSesion> {
  final Autenticacion _autenticacion = Autenticacion();
  Usuario? _usuarioActual;

  @override
  void initState() {
    super.initState();
    _usuarioActual = _autenticacion.usuarioActual;
    
    _autenticacion.userStream.listen((user) {
      if (mounted) {
        setState(() {
          _usuarioActual = user;
        });
        
        // Si la sesión expira, ejecutar callback
        if (user == null && widget.alExpirarSesion != null) {
          widget.alExpirarSesion!();
        }
      }
    });
  }

  void _actualizarActividad() {
    _autenticacion.actualizarActividad();
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay usuario autenticado, mostrar página de login
    if (_usuarioActual == null) {
      return widget.paginaDeInicioBuilder();
    }

    // Si hay usuario autenticado, mostrar la aplicación principal
    // y detectar actividad del usuario
    return GestureDetector(
      onTap: _actualizarActividad,
      onPanUpdate: (_) => _actualizarActividad(),
      behavior: HitTestBehavior.translucent,
      child: ProveedorDeInformacionDeSesion(
        usuario: _usuarioActual!,
        child: widget.child,
      ),
    );
  }
}

/// Widget que proporciona información de la sesión a widgets hijos
class ProveedorDeInformacionDeSesion extends InheritedWidget {
  final Usuario usuario;

  const ProveedorDeInformacionDeSesion({
    super.key,
    required this.usuario,
    required super.child,
  });

  /// Obtiene la información de sesión desde el contexto
  static ProveedorDeInformacionDeSesion? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProveedorDeInformacionDeSesion>();
  }

  /// Obtiene el usuario actual desde el contexto (lanza excepción si no existe)
  static Usuario usuarioDe(BuildContext context) {
    final provider = of(context);
    if (provider == null) {
      throw FlutterError('SessionInfoProvider not found in widget tree');
    }
    return provider.usuario;
  }

  @override
  bool updateShouldNotify(ProveedorDeInformacionDeSesion oldWidget) {
    return usuario != oldWidget.usuario;
  }
}

/// Widget para mostrar información del usuario en la barra superior
class UserInfoWidget extends StatelessWidget {
  final bool mostrarRol;
  final VoidCallback? alCerrarSesion;
  final VoidCallback? alTocarUsuario;

  const UserInfoWidget({
    super.key,
    this.mostrarRol = true,
    this.alCerrarSesion,
    this.alTocarUsuario,
  });

  @override
  Widget build(BuildContext context) {
    final infoSesion = ProveedorDeInformacionDeSesion.of(context);
    if (infoSesion == null) {
      return const SizedBox.shrink();
    }

    final user = infoSesion.usuario;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: alTocarUsuario,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor,
              child: Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          GestureDetector(
            onTap: alTocarUsuario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.primaryColor,
                  ),
                ),
                 mostrarRol ? Text(
                    user.rol.nombre,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.primaryColor.withOpacity(0.7),
                    ),
                  ) : const SizedBox.shrink(),
              ],
            ),
          ),
          
          if (alCerrarSesion != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: alCerrarSesion,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.logout,
                  size: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


mixin RequiereAutenticacion<T extends StatefulWidget> on State<T> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final sessionInfo = ProveedorDeInformacionDeSesion.of(context);
    if (sessionInfo == null) {
      // Redirigir al login si no hay sesión
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    }
  }
}


mixin RolRequerido<T extends StatefulWidget> on State<T> {
  RolUsuario get rolRequerido;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final informacionSesion = ProveedorDeInformacionDeSesion.of(context);
    if (informacionSesion == null || !_hasRequiredRole(informacionSesion.usuario)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showPermissionError();
        }
      });
    }
  }
  
  bool _hasRequiredRole(Usuario usuario) {
    final authService = Autenticacion();
    return authService.tieneRolMinimo(rolRequerido);
  }
  
  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acceso Denegado'),
        content: Text('No tiene permisos para acceder a esta función.\nSe requiere rol: ${rolRequerido.nombre}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}