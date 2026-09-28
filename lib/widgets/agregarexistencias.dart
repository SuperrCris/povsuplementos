import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';

class ActualizarExistencias extends StatefulWidget {
  String codigo;
  int cantidad;
  OperacionInventario operacion;
  void Function()? alTenerExito;

  ActualizarExistencias({
    required this.codigo,
    required this.cantidad,
    required this.alTenerExito,
    this.operacion = OperacionInventario.agregar,
  });

  @override
  _ActualizarExistenciasState createState() => _ActualizarExistenciasState();
}

class _ActualizarExistenciasState extends State<ActualizarExistencias> {
  final TextEditingController _cantidadControlador = TextEditingController();

  int cantidadActualizada = 0;

  @override
  void initState() {
    super.initState();
    _cantidadControlador.text = widget.cantidad.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Actualizar Existencias'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  cantidadActualizada = widget.cantidad;
                  int valorIngresado = int.tryParse(value) ?? 0;
                  switch (widget.operacion) {
                    case OperacionInventario.agregar:
                      cantidadActualizada += valorIngresado;
                      break;
                    case OperacionInventario.restar:
                      cantidadActualizada -= valorIngresado;
                      break;
                    case OperacionInventario.actualizar:
                      cantidadActualizada = valorIngresado;
                      break;
                  }
                });
              },
              decoration: InputDecoration(labelText: 'Cantidad a Actualizar'),
              keyboardType: TextInputType.number,
              controller: _cantidadControlador,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            DropdownButton<OperacionInventario>(
              value: widget.operacion,
              items: [
                DropdownMenuItem(
                  value: OperacionInventario.agregar,
                  child: Text('Agregar'),
                ),
                DropdownMenuItem(
                  value: OperacionInventario.restar,
                  child: Text('Restar'),
                ),
                DropdownMenuItem(
                  value: OperacionInventario.actualizar,
                  child: Text('Actualizar'),
                ),
              ],
              onChanged: (OperacionInventario? nuevaOperacion) {
                if (nuevaOperacion != null) {
                  setState(() {
                    cantidadActualizada = calcularNuevaCantidad(
                      widget.cantidad,
                      int.tryParse(_cantidadControlador.text) ?? 0,
                      nuevaOperacion,
                    );
                    widget.operacion = nuevaOperacion;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        Text(
          'La nueva cantidad seria: ${calcularNuevaCantidad(widget.cantidad, int.tryParse(_cantidadControlador.text) ?? 0, widget.operacion)}',
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final resultado = await Basededatos.actualizarExistencias(
              widget.codigo,
              int.parse(_cantidadControlador.text),
              widget.operacion,
            );
            if (resultado['exito'] && widget.alTenerExito != null) {
              widget.alTenerExito!();
              SnackBar snackBar = SnackBar(
                content: Text('Existencias actualizadas exitosamente.'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            } else {
              SnackBar snackBar = SnackBar(
                content: Text(
                  'Error al actualizar existencias: ${resultado['mensaje']}',
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            Navigator.of(context).pop();
          },
          child: Text('Actualizar'),
        ),
      ],
    );
  }

  // Función para calcular la nueva cantidad basada en la operación, pero solo para placeholder
  int calcularNuevaCantidad(
    int cantidadActual,
    int cantidadCambio,
    OperacionInventario operacion,
  ) {
    switch (operacion) {
      case OperacionInventario.agregar:
        return cantidadActual + cantidadCambio;
      case OperacionInventario.restar:
        return cantidadActual - cantidadCambio;
      case OperacionInventario.actualizar:
        return cantidadCambio;
    }
  }
}
