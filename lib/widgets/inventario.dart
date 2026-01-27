import 'package:flutter/material.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';


List<String> seleccionados = [];
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
              Text('Nombre: ${objeto.productoNombre }', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Código: ${objeto.codigo}'),
              SizedBox(height: 8),
              Text('Existencias: ${objeto.existencias }'),
              SizedBox(height: 8),
              Text('Precio: \$${objeto.precio}'),
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
    print('Editar producto: ${objeto.productoNombre}');
    // Implementa la lógica para editar el producto
  }

  void _ajustarStock(Objeto objeto) {
    print('Ajustar stock de: ${objeto.productoNombre}');
    // Implementa la lógica para ajustar el stock
  }

  void _verHistorial(Objeto objeto) {
    print('Ver historial de: ${objeto.productoNombre}');
    // Implementa la lógica para ver el historial
  } 
  TextEditingController controladorBusqueda = TextEditingController();

    Future<List<Objeto>> obtenerInfo() async {
    List<Objeto> objetos = [];
    final productos = await Basededatos.obtenerObjetosPorSucursal(bodySeleccionado);
    for (var producto in productos['productos']) {
      print(producto);
      Objeto objetoactual = Objeto(
        codigo: producto['codigo'],
        productoNombre: producto['productoNombre'],
        marcaNombre:  producto['marcaNombre'],
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
    controladorBusqueda.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double anchoPantalla = MediaQuery.of(context).size.width;
    int crossAxisCount = (anchoPantalla / 400).round();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Inventario de productos', style: TextStyle(color: Theme.of(context).appBarTheme.iconTheme?.color),)),
      floatingActionButton: accionActual == Accion.eliminar ? FloatingActionButton(
        onPressed: _manejarBotonEliminar,
        backgroundColor: Colors.red,
        child: Icon(Icons.delete),
      ) : null,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controladorBusqueda,
                      decoration: InputDecoration(
                        labelText: 'Buscar producto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          texto = valor;
                        });
                      },
                    ),

                  ),
                  SizedBox(width: 10),
                  SelectorSucursal(context, {1: {'nombre': 'BODY 1'}, 2: {'nombre': 'BODY 2'}}),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accionActual == Accion.ver ? Colors.red : Colors.blue,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(10),
                    ),
                    onPressed: (){
                    setState(() {
                      if (accionActual == Accion.ver) {
                        accionActual = Accion.eliminar;
                      } else {
                        accionActual = Accion.ver;
                        seleccionados.clear();
                      }
                      print('accionActual: $accionActual');
                    });

                  }, child: Icon(accionActual == Accion.ver ? Icons.delete : Icons.visibility, size: 30,)),
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
                return Text('Error al cargar el inventario: ${snapshot.error}');
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No hay objetos en el inventario.');
              } else{ 
              ///Mostrar primero los productos activos
              List<Objeto> productosFiltrados = _filtrarProductos(snapshot.data!);
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
                return Text('No se encontraron productos que coincidan con "${texto}"');
              }
                return Container(
                  height: MediaQuery.of(context).size.height - 200,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 2.6 - (anchoPantalla / 1500),
                      crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
                    ),
                    itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    Objeto objeto = productosFiltrados[index];
                    
                    
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              objeto.productoNombre, 
                              style: TextStyle(fontWeight: FontWeight.bold, color: objeto.activo ? Colors.black : Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          accionActual == Accion.eliminar ? Seleccionador(codigo: objeto.codigo, actualizarLista: actualizarSeleccionados,) :
                     
                     PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                      onSelected: (String value) {
                        _manejarOpcionSeleccionada(value, objeto);
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'ver_detalles',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 8),
                              Text('Ver detalles'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Editar producto'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'ajustar_stock',
                          child: Row(
                            children: [
                              Icon(Icons.inventory_outlined),
                              SizedBox(width: 8),
                              Text('Ajustar stock'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'historial',
                          child: Row(
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 8),
                              Text('Ver historial'),
                            ],
                          ),
                        ),
                      ],
                    ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Codigo: ${objeto.codigo}', style: TextStyle(color: Colors.grey.shade600),overflow: TextOverflow.ellipsis),
                          Text(
                            'Hay: ${objeto.existencias}', style: TextStyle(fontSize: 24, overflow: TextOverflow.ellipsis),
                          ),
                          Text( 
                            '\$${objeto.precio}', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.green, overflow: TextOverflow.ellipsis),
                          ),
                         
                        ],
                      ),
                    
                    );  
                  },
                ),
              );
              }
            },
          ),
            ],
        ),
        
      ),
    ),);
  }


   
Widget SelectorSucursal(BuildContext context, Map<int, dynamic> sucursales) {

     return  DropdownButton<int>(
        focusColor: Colors.transparent,
        underline: SizedBox(),
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
      );
    
  } 

  void _manejarBotonEliminar() async {
    await Basededatos.desactivarProductos(seleccionados);
    setState(() {
      seleccionados.clear();
      accionActual = Accion.ver;
      _productosFuture = obtenerInfo();
    });

  }
  }

List<Objeto> _filtrarProductos(List<Objeto> objetos){
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
  Future <List<Map<String, dynamic>>> cargarInventario() async {
    try {
      final resultado = await Basededatos.obtenerObjetos();
      print("Resultado de BD: $resultado");

      if (resultado == null) {
        print("Resultado es null");
        return [];
      }
      
      if (resultado["productos"] == null) {
        print("productos es null");
        return [];
      }
      
      List<Map<String, dynamic>> inventario = List<Map<String, dynamic>>.from(resultado["productos"]);
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
    Seleccionador({super.key, this.actualizarLista, this.criteroActual = false, this.codigo = 0});
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

