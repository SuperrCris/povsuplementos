import 'package:flutter/material.dart';
import 'package:pov_suplementos/auth/autenticacion.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';

class ReporteFaltantes extends StatefulWidget {
  const ReporteFaltantes({super.key, required this.productos});

  final List<Objeto> productos;

  @override
  State<ReporteFaltantes> createState() => _ReporteFaltantesState();
}

class _ReporteFaltantesState extends State<ReporteFaltantes> {
  late final Map<String, TextEditingController> _cantidadControllers;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cantidadControllers = {
      for (final producto in widget.productos)
        producto.codigo: TextEditingController(
          text: producto.existencias.toString(),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _cantidadControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _enviarReporte() async {
    final cantidades = <Map<String, dynamic>>[];
    for (final producto in widget.productos) {
      final texto = _cantidadControllers[producto.codigo]!.text.trim();
      final cantidadReal = int.tryParse(texto);
      if (cantidadReal == null || cantidadReal < 0) {
        _mostrarMensaje(
          'Ingresa una cantidad válida para ${producto.productoNombre}.',
        );
        return;
      }
      if (cantidadReal != producto.existencias) {
        cantidades.add({
          'codigo': producto.codigo,
          'cantidadEsperada': producto.existencias,
          'cantidadReal': cantidadReal,
        });
      }
    }

    if (cantidades.isEmpty) {
      _mostrarMensaje('No hay productos modificados para reportar.');
      return;
    }

    final usuarioId = Autenticacion().id;
    if (usuarioId <= 0) {
      _mostrarMensaje('No hay una usuaria autenticada.');
      return;
    }

    setState(() => _enviando = true);
    final resultado = await Basededatos.crearReporteFaltantes(
      creadoPor: usuarioId,
      productos: cantidades,
    );
    if (!mounted) return;
    setState(() => _enviando = false);

    _mostrarMensaje(resultado['mensaje'] as String);
    if (resultado['exito'] == true) {
      Navigator.of(context).pop(true);
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar faltantes')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Verifica la cantidad real y modifica solo los productos con diferencias.',
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final producto = widget.productos[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.productoNombre,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text('Código: ${producto.codigo}'),
                              Text(
                                'Cantidad esperada: ${producto.existencias}',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _cantidadControllers[producto.codigo],
                            enabled: !_enviando,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad real',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _enviarReporte,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_enviando ? 'Enviando...' : 'Enviar reporte'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
