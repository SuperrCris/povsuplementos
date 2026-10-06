import 'package:flutter/material.dart';

class BotonNavegacion extends StatelessWidget {
  final IconData? icono;
  final String texto;
  final VoidCallback? alAccionar;
  final Gradient? gradiente;
    final Gradient? gradienteAlSeleccionar;
  const BotonNavegacion({
    super.key,
    required this.texto,
    this.icono,
    this.alAccionar,
    this.gradiente,
    this.gradienteAlSeleccionar ,
  });


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradiente ?? const LinearGradient(
            colors: [Colors.blue, Colors.teal],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          hoverColor: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          onTap: alAccionar ,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) Icon(icono, color: Colors.white),
                if (icono != null) SizedBox(width: 8),
                Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}