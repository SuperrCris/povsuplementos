
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';


class agregarSalidas extends StatefulWidget {
  void Function()? alTenerExito;
  agregarSalidas  ({super.key, this.alTenerExito});

  @override
  _AgregarSalidasState createState() => _AgregarSalidasState();
}

class _AgregarSalidasState extends State<agregarSalidas> {
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  ImageProvider? imagenSeleccionada;
  String? nombreArchivoImagen;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar salida de efectivo'),
      content: SingleChildScrollView(
        child: Row(
            spacing: 10,
            children: [
              Flexible(
                child: Column(
                  spacing: 10,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    
                    TextField(
                      controller: _cantidadController,
                      decoration: InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    SizedBox(
                      height: 60,
                      child: TextField(
                        controller: _conceptoController,
                        decoration: InputDecoration(labelText: 'Concepto'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final nuevaCantidad = int.tryParse(_cantidadController.text) ?? 0;
            final nuevoConcepto = _conceptoController.text.trim();

            if (nuevoConcepto.isEmpty || nuevaCantidad <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Todos los campos son obligatorios')),
              );
              return;
            }
            try {
    

              final resultado = await Basededatos.guardarSalidasEfectivo(
                concepto: nuevoConcepto,
                monto: nuevaCantidad.toDouble(),
              );

              print(resultado);

              widget.alTenerExito?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Salida de efectivo agregada con éxito')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al agregar la salida de efectivo: $e')),
                );
              }
            }
          },
          child: Text('Agregar'),
        ),
      ],
    );
  }
}
