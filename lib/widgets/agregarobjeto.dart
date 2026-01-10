import 'package:flutter/material.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';

class Agregarobjeto extends StatefulWidget {
  void Function()? alTenerExito;
  Agregarobjeto({super.key, this.alTenerExito});

  @override
  _AgregarobjetoState createState() => _AgregarobjetoState();
}

class _AgregarobjetoState extends State<Agregarobjeto> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar Objeto'),
      content: SingleChildScrollView(
        child: Column(
          spacing: 10,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(labelText: 'Código de Barras'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: _marcaController,
              decoration: InputDecoration(labelText: 'Marca'),
            ),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _precioController,
              decoration: InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _cantidadController,
              decoration: InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _categoriaController,
              decoration: InputDecoration(labelText: 'Categoría'),
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
          onPressed: () async{
            final nuevoCodigo = _codigoController.text.trim();
            final nuevaMarca = _marcaController.text;
            final nuevoNombre = _nombreController.text;
            final nuevoPrecio = double.tryParse(_precioController.text) ?? 0.0;
            final nuevaCantidad = int.tryParse(_cantidadController.text) ?? 0;
            final nuevaCategoria = _categoriaController.text;

            if (nuevoCodigo.isEmpty || nuevaMarca.isEmpty || nuevoNombre.isEmpty || nuevaCategoria.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Todos los campos son obligatorios')),
              );
              return;
            }

          final resultado = await Basededatos.guardarProductos([
              {'codigo': nuevoCodigo,
              'marcaNombre': nuevaMarca,
              'productoNombre': nuevoNombre,
              'precio': nuevoPrecio,
              'existencias': nuevaCantidad,
              'categoria': nuevaCategoria
              }]
            );
          
          print(resultado);

          widget.alTenerExito?.call();
          if (context.mounted){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Producto agregado con éxito')),
            );
            Navigator.of(context).pop();
          }

            
          },
          child: Text('Agregar'),),
      ]
          );
  }
}
  
    

