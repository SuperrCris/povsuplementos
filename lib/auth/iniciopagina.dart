

import 'package:flutter/material.dart';
import 'package:pov_suplementos/auth/autenticacion.dart';


class Iniciopagina extends StatefulWidget {
  const Iniciopagina({super.key});

  @override
  State<Iniciopagina> createState() => _IniciopaginaState();
}

class _IniciopaginaState extends State<Iniciopagina> with SingleTickerProviderStateMixin {
  final Autenticacion _authService = Autenticacion();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _cargando = false;
  bool _ocultarContrasena = true;
  String? _mensajeError;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    // Iniciar animación
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _mensajeError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final result = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (result.exito) {
        _showSuccessMessage('¡Bienvenido ${result.usuario!.nombre}!');
      } else {
        setState(() {
          _mensajeError = result.mensaje;
        });
      }
    } catch (e) {
      setState(() {
        _mensajeError  = 'Error inesperado: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  /// Muestra mensaje de éxito
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Valida el campo de usuario
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El usuario es requerido';
    }
    if (value.trim().length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    return null;
  }

  /// Valida el campo de contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:  Colors.blue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Container(
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              color:theme.scaffoldBackgroundColor,
              ),
              constraints: BoxConstraints(
                maxWidth: size.width < 500 ? size.width : 400,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SUPLEMENTOS BEG',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _txfUsuario(),
                    const SizedBox(height: 16),
                    _txfContrasena(),
                    const SizedBox(height: 24),
                    _btnIniciarSesion(),
                    if (_mensajeError != null) ...[
                      const SizedBox(height: 16),
                      _msjError(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el header con logo y título
  Widget _cabecera(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.store,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height:  16),
        Text(
          'Suplementos BEG',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
            fontSize: 24,
          ),
        ),
        const SizedBox(height:8),
      ],
    );
  }

  /// Construye el campo de usuario
  Widget _txfUsuario() {
    return TextFormField(
      controller: _usernameController,
      validator: _validateUsername,
      textInputAction: TextInputAction.next,
      enabled: !_cargando,
      decoration: InputDecoration(
        labelText: 'Usuario',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Construye el campo de contraseña
  Widget _txfContrasena() {
    return TextFormField(
      controller: _passwordController,
      validator: _validatePassword,
      obscureText: _ocultarContrasena,
      textInputAction: TextInputAction.done,
      enabled: !_cargando,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _ocultarContrasena ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _ocultarContrasena = !_ocultarContrasena;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Construye el texto de "Olvidé mi contraseña"



  Widget _btnIniciarSesion() {
    return ElevatedButton(
      onPressed: _cargando ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _cargando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  /// Construye el mensaje de error
  Widget _msjError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _mensajeError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

}