import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/funciones/gestor_imagenes.dart';

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

  ImageProvider? imagenSeleccionada;
  String? nombreArchivoImagen;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar Objeto'),
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
                      controller: _codigoController,
                      decoration: InputDecoration(
                        labelText: 'Código de Barras',
                      ),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                    ),
                    TextField(
                      controller: _cantidadController,
                      decoration: InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _categoriaController.text.isNotEmpty
                          ? _categoriaController.text
                          : null,
                      decoration: InputDecoration(labelText: 'Categoría'),

                      items: ['Snack', 'Suplemento', 'Otro']
                          .map(
                            (categoria) => DropdownMenuItem(
                              value: categoria,
                              child: Text(categoria),
                            ),
                          )
                          .toList(),
                      onChanged: (nuevaCategoria) {
                        _categoriaController.text = nuevaCategoria ?? '';
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                            );

                        if (result != null) {
                          PlatformFile file = result.files.first;
                          print('Imagen seleccionada: ${file.name}');
                          print('Ruta: ${file.path}');
                          setState(() {
                            imagenSeleccionada = FileImage(File(file.path!));
                            nombreArchivoImagen = file.name;
                          });
                        } else {
                          print('No se seleccionó ninguna imagen.');
                        }
                      },
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Builder(
                          builder: (context) {
                            if (imagenSeleccionada != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image(
                                  image: imagenSeleccionada!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.grey[600],
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Agregar\nImagen',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Text(
                      nombreArchivoImagen ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
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
            final nuevoCodigo = _codigoController.text.trim();
            final nuevaMarca = _marcaController.text;
            final nuevoNombre = _nombreController.text;
            final nuevoPrecio = double.tryParse(_precioController.text) ?? 0.0;
            final nuevaCantidad = int.tryParse(_cantidadController.text) ?? 0;
            final nuevaCategoria = _categoriaController.text;

            if (nuevoCodigo.isEmpty ||
                nuevaMarca.isEmpty ||
                nuevoNombre.isEmpty ||
                nuevaCategoria.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Todos los campos son obligatorios')),
              );
              return;
            }
            try {
              var nombreImagen = '';
              final imagen = imagenSeleccionada;
              if (imagen is FileImage && nombreArchivoImagen != null) {
                nombreImagen = await GestorImagenes.guardarImagen(
                  imagen.file.path,
                  nombreArchivoImagen!,
                );
              }

              final resultado = await Basededatos.guardarProductos([
                {
                  'codigo': nuevoCodigo,
                  'marcaNombre': nuevaMarca,
                  'productoNombre': nuevoNombre,
                  'precio': nuevoPrecio,
                  'existencias': nuevaCantidad,
                  'categoria': nuevaCategoria,
                  'imagen': nombreImagen,
                },
              ]);

              print(resultado);

              widget.alTenerExito?.call();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Producto agregado con éxito')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al agregar el producto: $e')),
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
