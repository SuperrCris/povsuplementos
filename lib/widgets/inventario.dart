import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/widgets/agregarexistencias.dart';
import 'package:pov_suplementos/widgets/agregarobjeto.dart';

Set<String> seleccionados = {};
List<int> rango = [];

enum Accion { ver, eliminar, agregar }

String texto = '';
int bodySeleccionado = 1;
void actualizarSeleccionados(var codigo, bool seleccionado) {
  if (seleccionado) {
    seleccionados.add(codigo);
  } else {
    seleccionados.remove(codigo);
  }

  print('Seleccionados actualizados: $seleccionados');
}



class Inventario extends StatefulWidget {
  const Inventario({super.key});
  @override
  State<Inventario> createState() => _InventarioState();
}

class _InventarioState extends State<Inventario> {
  Accion accionActual = Accion.ver;
  late Future<List<Objeto>> _productosFuture;
  OverlayEntry? _menuContextual;

  bool _teclaEstaPresionada(LogicalKeyboardKey tecla) {
    return HardwareKeyboard.instance.logicalKeysPressed.contains(tecla);
  }

  bool _shiftEstaPresionado() {
    return _teclaEstaPresionada(LogicalKeyboardKey.shiftLeft) ||
        _teclaEstaPresionada(LogicalKeyboardKey.shiftRight);
  }

  bool _ctrlEstaPresionado() {
    return _teclaEstaPresionada(LogicalKeyboardKey.controlLeft) ||
        _teclaEstaPresionada(LogicalKeyboardKey.controlRight);
  }

  void _manejarOpcionSeleccionada(String opcion, Objeto objeto) {
    switch (opcion) {
      case 'ver_detalles':
        _mostrarDetallesProducto(objeto);
        break;
      case 'editar':
        _editarProducto(objeto);
        break;
      case 'ajustar_stock':
        _ajustarStock(objeto);
        break;
      case 'historial':
        _verHistorial(objeto);
        break;
    }
  }

  void _cerrarMenuContextual() {
    _menuContextual?.remove();
    _menuContextual = null;
  }

  void _mostrarMenuContextual(TapDownDetails detalles, Objeto objeto) {
    _cerrarMenuContextual();

    _menuContextual = OverlayEntry(
      builder: (context) => Positioned(
        left: detalles.globalPosition.dx,
        top: detalles.globalPosition.dy,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _opcionMenuContextual(
                  Icons.info_outline,
                  'Ver detalles',
                  'ver_detalles',
                  objeto,
                ),
                _opcionMenuContextual(
                  Icons.edit_outlined,
                  'Editar producto',
                  'editar',
                  objeto,
                ),
                _opcionMenuContextual(
                  Icons.inventory_outlined,
                  'Ajustar stock',
                  'ajustar_stock',
                  objeto,
                ),
                _opcionMenuContextual(
                  Icons.history,
                  'Ver historial',
                  'historial',
                  objeto,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_menuContextual!);
  }

  Widget _opcionMenuContextual(
    IconData icono,
    String titulo,
    String opcion,
    Objeto objeto,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icono),
      title: Text(titulo),
      onTap: () {
        _cerrarMenuContextual();
        _manejarOpcionSeleccionada(opcion, objeto);
      },
    );
  }

  void _mostrarDetallesProducto(Objeto objeto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles del Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${objeto.productoNombre}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Código: ${objeto.codigo}'),
              SizedBox(height: 8),
              Text('Existencias: ${objeto.existencias}'),
              SizedBox(height: 8),
              Text('Precio: \$${objeto.precio}'),
              SizedBox(height: 8),
              Text('Categoría: ${objeto.categoria}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _editarProducto(Objeto objeto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles del Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: TextEditingController(text: objeto.productoNombre),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                controller: TextEditingController(
                  text: objeto.existencias.toString(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: TextEditingController(
                  text: objeto.precio.toString(),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: objeto.categoria),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async =>
                  await Basededatos.actualizarProducto(objeto.codigo, {
                    'productoNombre': objeto.productoNombre,
                    'existencias': objeto.existencias,
                    'precio': objeto.precio,
                    'categoria': objeto.categoria,
                  }).then((result) {
                    if (result['exito']) {
                      print('✅ Producto actualizado exitosamente');
                      setState(() {
                        _productosFuture = obtenerInfo();
                      });
                    } else {
                      print(
                        '❌ Error actualizando producto: ${result['mensaje']}',
                      );
                    }
                  }),
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _ajustarStock(Objeto objeto) {
    print('Ajustar stock de: ${objeto.productoNombre}');
    showDialog(
      context: context,
      builder: (context) => ActualizarExistencias(
        codigo: int.tryParse(objeto.codigo) ?? -1,
        cantidad: objeto.existencias,
        alTenerExito: () {
          setState(() {
            _productosFuture = obtenerInfo();
          });
        },
      ),
    );
  }

  void _verHistorial(Objeto objeto) {
    print('Ver historial de: ${objeto.productoNombre}');
  }

  TextEditingController controladorBusqueda = TextEditingController();

  Future<List<Objeto>> obtenerInfo() async {
    List<Objeto> objetos = [];
    final productos = await Basededatos.obtenerObjetosPorSucursal(
      bodySeleccionado,
    );
    for (var producto in productos['productos']) {
      print(producto);
      Objeto objetoactual = Objeto(
        codigo: producto['codigo'],
        productoNombre: producto['productoNombre'],
        marcaNombre: producto['marcaNombre'],
        descripcion: producto['descripcion'] ?? '',
        precio: (producto['precio']?.toDouble()) ?? 0.0,
        imagen: producto['imagen'] ?? '',
        categoria: producto['categoria'],
        existencias: producto['existencias'],
        activo: producto['activo'] == 1 ? true : false,
      );

      print(
        "Objeto agregado: ${objetoactual.productoNombre} con codigo ${objetoactual.codigo}",
      );
      objetos.add(objetoactual);
    }
    return objetos;
  }

  @override
  void initState() {
    super.initState();
    _productosFuture = obtenerInfo();
  }

  @override
  void dispose() {
    _cerrarMenuContextual();
    controladorBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(
                    'Salir',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Inventario de productos',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              // Barra de busqueda, botones de restar, ver y añadir. Selector de sucursal
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: anchoPantalla < 600 ? double.infinity : 360,
                    child: TextField(
                      controller: controladorBusqueda,
                      decoration: InputDecoration(
                        labelText: 'Buscar producto',
                        hintText: 'Nombre o codigo',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                      ),
                      onChanged: (valor) {
                        setState(() {
                          texto = valor;
                        });
                      },
                    ),
                  ),
                  SelectorSucursal(context, {
                    1: {'nombre': 'BODY 1'},
                    2: {'nombre': 'BODY 2'},
                  }),
                  Tooltip(
                    message: 
                    seleccionados.isNotEmpty
                        ? 'Eliminar ${seleccionados.length} ${seleccionados.length == 1 ? 'producto' : 'productos'} \n${seleccionados.join('\n')}'
                        : 'Sin productos por eliminar',
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: accionActual == Accion.ver
                            ? colors.errorContainer
                            : colors.secondaryContainer,
                        foregroundColor: accionActual == Accion.ver
                            ? colors.onErrorContainer
                            : colors.onSecondaryContainer,
                      ),
                      onPressed: () {
                        setState(() {
                          if (accionActual == Accion.ver) {
                            accionActual = Accion.eliminar;
                          } else {
                            accionActual = Accion.ver;
                            seleccionados.clear();
                          }
                          print('accionActual: $accionActual');
                        });
                      },
                      icon: Icon(
                        accionActual == Accion.ver
                            ? Icons.delete_outline
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),

                  //Boton de añadir
                  Tooltip(
                    message: 'Agregar producto',
                    child: IconButton.filled(
                      onPressed: () {
                        setState(() {
                          if (accionActual == Accion.eliminar) {
                            accionActual = Accion.ver;
                          }
                        });

                        _mostrarDialogoAgregarObjeto();
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Confirmar inventario'),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              FutureBuilder(
                future: _productosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return Text(
                      'Error al cargar el inventario: ${snapshot.error}',
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No hay objetos en el inventario.');
                  } else {
                    ///Mostrar primero los productos activos
                    List<Objeto> productosFiltrados = _filtrarProductos(
                      snapshot.data!,
                    );
                    productosFiltrados.sort((a, b) {
                      if (a.activo && !b.activo) {
                        return -1; // a viene antes que b
                      } else if (!a.activo && b.activo) {
                        return 1; // b viene antes que a
                      } else {
                        return 0; // mantienen el mismo orden relativo
                      }
                    });
                    if (productosFiltrados.isEmpty) {
                      return Text(
                        'No se encontraron productos que coincidan con "${texto}"',
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: productosFiltrados.map((objeto) {
                        return GestureDetector(
                          onSecondaryTapDown: (detalles) {
                            _mostrarMenuContextual(detalles, objeto);
                          },
                          onTap: () {
                            _cerrarMenuContextual();
                            setState(() {
                              if (_shiftEstaPresionado()) {

                                if (seleccionados.contains(objeto.codigo)) {
                                  seleccionados.remove(objeto.codigo);
                                } else {
                                  seleccionados.add(objeto.codigo);
                                  rango[0] = productosFiltrados.indexOf(objeto);
                                }
                              } else if (_ctrlEstaPresionado()) {
                                
                                  seleccionados.add(objeto.codigo);
                                   if (rango.length == 0) {
                                     rango[0] = productosFiltrados.indexOf(objeto);
                                   } else if (rango.length == 1) {
                                     rango[1] = productosFiltrados.indexOf(objeto);
                                   }
                                  print(
                                    'Rango actualizado: $rango',
                                  );
                                  if (rango.length > 2) {
                                    rango.sort();
                                    for (var i = rango[0] + 1; i < rango[1]; i++) {
                                      seleccionados.add(productosFiltrados[i].codigo);
                                    }
                                    rango.clear();
                                  }
                                
                              } else {
                                
                                if (!seleccionados.contains(objeto.codigo)) {
                                  seleccionados
                                    ..clear()
                                    ..add(objeto.codigo);
                                  rango[0] = productosFiltrados.indexOf(objeto);
                                } else {
                                  seleccionados.clear();
                                }
                              }
                              print(
                                'Seleccionados actualizados: $seleccionados',
                              );
                            });
                          },
                          child: SizedBox(
                            width: anchoPantalla < 600
                                ? double.infinity
                                : (anchoPantalla - 56) / 3,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              margin: const EdgeInsets.all(1),
                              color: seleccionados.contains(objeto.codigo)
                                  ? colors.primaryFixed
                                  : colors.surfaceContainerHighest,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                side: BorderSide(color: colors.outlineVariant),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      spacing: 4,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            objeto.productoNombre,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: objeto.activo
                                                      ? colors.onSurface
                                                      : colors.onSurfaceVariant,
                                                ),

                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            '\$${objeto.precio}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.green,
                                            ),
                                            maxLines: 1,

                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Hay: ${objeto.existencias}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            // minFontSize: 12,
                                            maxLines: 1,
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        /*    SizedBox(
                                            width: 48,
                                            child: accionActual == Accion.eliminar
                                                ? Seleccionador(
                                                    codigo: objeto.codigo,
                                                    actualizarLista:
                                                        actualizarSeleccionados,
                                                  )
                                                : PopupMenuButton<String>(
                                                    icon: Icon(
                                                      Icons.more_vert,
                                                      color: Theme.of(
                                                        context,
                                                      ).iconTheme.color,
                                                    ),
                                                    onSelected: (String value) {
                                                      _manejarOpcionSeleccionada(
                                                        value,
                                                        objeto,
                                                      );
                                                    },
                                                    itemBuilder:
                                                        (BuildContext context) => [
                                                          PopupMenuItem<String>(
                                                            value: 'ver_detalles',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                ),
                                                                SizedBox(width: 8),
                                                                Text(
                                                                  'Ver detalles',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem<String>(
                                     
                                                            value: 'editar',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .edit_outlined,
                                                                ),
                                                                SizedBox(width: 8),
                                                                Text(
                                                                  'Editar producto',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem<String>(
                                                            value: 'ajustar_stock',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .inventory_outlined,
                                                                ),
                                                                SizedBox(width: 8),
                                                                Text(
                                                                  'Ajustar stock',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem<String>(
                                                            value: 'historial',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.history),
                                                                SizedBox(width: 8),
                                                                Text(
                                                                  'Ver historial',
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                  ),
                                          ), */
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoAgregarObjeto() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Agregarobjeto(
          alTenerExito: () {
            setState(() {
              _productosFuture = obtenerInfo();
            });
          },
        );
      },
    );
  }

  Widget SelectorSucursal(BuildContext context, Map<int, dynamic> sucursales) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: DropdownButton<int>(
        focusColor: Colors.transparent,
        underline: const SizedBox(),
        value: bodySeleccionado,
        hint: Text('BODY $bodySeleccionado'),
        items: sucursales.entries.map((entry) {
          return DropdownMenuItem<int>(
            value: entry.key,
            child: Text(entry.value['nombre']),
          );
        }).toList(),
        onChanged: (int? selectedKey) {
          if (selectedKey != null) {
            setState(() {
              bodySeleccionado = selectedKey;
              _productosFuture = obtenerInfo();
              print('Sucursal seleccionada: $selectedKey');
              _cargarInventario(sucursales[selectedKey]);
            });
          }
        },
      ),
    );
  }

  void _manejarBotonEliminar() async {
    await Basededatos.desactivarProductos(seleccionados.toList());
    setState(() {
      seleccionados.clear();
      accionActual = Accion.ver;
      _productosFuture = obtenerInfo();
    });
  }
}

List<Objeto> _filtrarProductos(List<Objeto> objetos) {
  if (texto.isEmpty) {
    return objetos;
  }

  return objetos.where((producto) {
    final nombre = producto.productoNombre.toLowerCase();
    final codigo = producto.codigo.toString().toLowerCase();
    final textito = texto.toLowerCase();
    return nombre.contains(textito) || codigo.contains(textito);
  }).toList();
}

Future<List<Map<String, dynamic>>> cargarInventario() async {
  try {
    final resultado = await Basededatos.obtenerObjetos();
    print("Resultado de BD: $resultado");

    if (resultado["productos"] == null) {
      print("productos es null");
      return [];
    }

    List<Map<String, dynamic>> inventario = List<Map<String, dynamic>>.from(
      resultado["productos"],
    );
    print("Devolviendo inventario: $inventario");
    return inventario;
  } catch (e) {
    print("Error cargando inventario: $e");
    return [];
  }
}

// ignore: must_be_immutable
class Seleccionador extends StatefulWidget {
  void Function(int, bool)? actualizarLista;
  bool criteroActual = false;
  final codigo;
  Seleccionador({
    super.key,
    this.actualizarLista,
    this.criteroActual = false,
    this.codigo = 0,
  });
  @override
  State<Seleccionador> createState() => _SeleccionadorState();
}

class _SeleccionadorState extends State<Seleccionador> {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: widget.criteroActual,
      onChanged: (nuevoValor) {
        setState(() {
          actualizarSeleccionados(widget.codigo, nuevoValor);
          widget.criteroActual = nuevoValor;
        });
      },
    );
  }
}

void _cargarInventario(var sucursal) {
  print('Sucursal seleccionada: $sucursal');
}
