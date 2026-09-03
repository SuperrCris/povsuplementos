
import 'package:flutter/material.dart';
import 'package:pov_suplementos/auth/autenticacion.dart';


class BotonUsuario extends StatefulWidget {
  const BotonUsuario({super.key});

  @override
  State<BotonUsuario> createState() => _BotonUsuarioState();
}

class _BotonUsuarioState extends State<BotonUsuario> {
  final Autenticacion _autenticacion = Autenticacion();
  
  void _mostrarUsuarioDialogo(BuildContext context) {
    if (_autenticacion.estaAutenticado) {
      _mostrarMenuUsuario(context);
    } else {
      _mostrarDialogoInicioSesion(context);
    }
  }


  void _mostrarMenuUsuario(BuildContext context) {
    final usuario = _autenticacion.usuarioActual;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                //Info de usuario
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  usuario!.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  usuario!.rol.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Opciones del menú
                _construirOpcionMenu(
                  icon: Icons.person_outline,
                  title: 'Cambiar Contraseña',
                  onTap: () {
                    Navigator.pop(context);
                    _mostrarDialogoCambiarContrasena(context);
                  },
                ),
                if (usuario!.esAdmin) ...[
                  _construirOpcionMenu(
                    icon: Icons.people_outline,
                    title: 'Gestionar Usuarios',
                    onTap: () {
                      Navigator.pop(context);
                      _showUsersDialog(context);
                    },
                  ),
                ],
                  _construirOpcionMenu(
                  icon: Icons.logout,
                  title: 'Cerrar Sesión',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  /// Construye una opción del menú
  Widget _construirOpcionMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final finalColor = color ?? Theme.of(context).primaryColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: finalColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: finalColor,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _mostrarDialogoInicioSesion(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Campo usuario
                    TextField(
                      controller: usernameController,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo contraseña
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () {
                              Navigator.pop(dialogContext);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () async {
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });

                              final resultado = await _autenticacion.login(
                                usernameController.text,
                                passwordController.text,
                              );

                              if (resultado.exito) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('¡Bienvenido ${resultado.usuario!.nombre}!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                setState(() {
                                  errorMessage = resultado.mensaje;
                                  isLoading = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Ingresar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Maneja el logout
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar su sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autenticacion.cerrarSesion();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesión cerrada'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo para cambiar contraseña
  void _mostrarDialogoCambiarContrasena(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas no coinciden'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final resultado = await _autenticacion.cambiarContrasena(
                currentPasswordController.text,
                newPasswordController.text,
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(resultado['mensaje']),
                  backgroundColor: resultado['exito'] ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }


  void _showUsersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestión de Usuarios'),
        content: const Text('Función en desarrollo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarUsuarioDialogo(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _autenticacion.estaAutenticado 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _autenticacion.estaAutenticado ? Icons.person : Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
            if (_autenticacion.estaAutenticado) ...[
              const SizedBox(width: 4),
              Text(
                _autenticacion.usuarioActual!.nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
