import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/funciones/gestor_imagenes.dart';
import 'package:pov_suplementos/widgets/agregarobjeto.dart';
import 'package:pov_suplementos/widgets/reportefaltantes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventarioPlutoGrid extends StatefulWidget {
  const InventarioPlutoGrid({super.key});

  @override
  State<InventarioPlutoGrid> createState() => _InventarioPlutoGridState();
}

class _InventarioPlutoGridState extends State<InventarioPlutoGrid> {
  static const _codigo = 'codigo';
  static const _nombre = 'nombre';
  static const _marca = 'marca';
  static const _categoria = 'categoria';
  static const _precio = 'precio';
  static const _existencias = 'existencias';
  static const _activo = 'activo';
  static const _imagen = 'imagen';
  static const _metodoPago = 'metodoPago';
  static const _productosVendidos = 'productosVendidos';
  static const _usuario = 'usuario';
  static const _fecha = 'fecha';
  static const _tipoMovimiento = 'tipoMovimiento';
  static const _cantidadMovimiento = 'cantidadMovimiento';
  static const _montoMovimiento = 'montoMovimiento';
  static const _fechaDesdeGuardada = 'inventario_fecha_desde';
  static const _fechaHastaGuardada = 'inventario_fecha_hasta';
  static const _horarios = {"mañana":["05:00","13:30"],
                            "tarde":["13:30","21:00"]
  };

  bool verDesactivados = true;

  final TextEditingController _busquedaController = TextEditingController();
  final ScrollController _inventarioScrollController = ScrollController();
  final ScrollController _ventassalidasScrollController = ScrollController();
  final ScrollController _movimientosScrollController = ScrollController();
  PlutoGridStateManager? _stateManagerSnack;
  PlutoGridStateManager? _stateManagerDemas;
  PlutoGridStateManager? _stateManagerVentas;
  PlutoGridStateManager? _stateManagerMovimientos;
  PlutoGridStateManager? _stateManagerSalidas;
  int _sucursalSeleccionada = 1;
  bool _cargando = true;
  String? _error;
  List<Objeto> _productos = [];
  List<Map<String, dynamic>> _ventas = [];
  List<Map<String, dynamic>> _salidas = [];
  List<Map<String, dynamic>> _movimientos = [];
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  double _subtotal = 0;
  double _salida = 0;
  double _entrada = 0;
  double _impuestos = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _restaurarRangoFechas();
    _cargarProductos();
    obtenerVentas();
    obtenerSalidas();
    obtenerMovimientos();
    _calcularTotal();
  }

  Future<void> _restaurarRangoFechas() async {
    final preferencias = await SharedPreferences.getInstance();
    final desde = preferencias.getInt(_fechaDesdeGuardada);
    final hasta = preferencias.getInt(_fechaHastaGuardada);
    if (!mounted || desde == null || hasta == null) return;

    setState(() {
      _fechaDesde = DateTime.fromMillisecondsSinceEpoch(desde);
      _fechaHasta = DateTime.fromMillisecondsSinceEpoch(hasta);
    });
    _actualizarFilas();
  }

  Future<void> _guardarRangoFechas() async {
    final preferencias = await SharedPreferences.getInstance();
    if (_fechaDesde == null || _fechaHasta == null) {
      await preferencias.remove(_fechaDesdeGuardada);
      await preferencias.remove(_fechaHastaGuardada);
      return;
    }

    await preferencias.setInt(
      _fechaDesdeGuardada,
      _fechaDesde!.millisecondsSinceEpoch,
    );
    await preferencias.setInt(
      _fechaHastaGuardada,
      _fechaHasta!.millisecondsSinceEpoch,
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _inventarioScrollController.dispose();
    _ventassalidasScrollController.dispose();
    _movimientosScrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await Basededatos.obtenerObjetosPorSucursal(
        _sucursalSeleccionada,
      );
      final productos = (resultado['productos'] as List<dynamic>? ?? [])
          .map(
            (producto) => Objeto(
              codigo: producto['codigo'] as String,
              productoNombre: producto['productoNombre'] as String,
              marcaNombre: producto['marcaNombre'] as String,
              descripcion: producto['descripcion'] as String? ?? '',
              precio: (producto['precio'] as num?)?.toDouble() ?? 0,
              imagen: producto['imagen'] as String? ?? '',
              categoria: producto['categoria'] as String?,
              existencias: producto['existencias'] as int? ?? 0,
              activo: producto['activo'] == 1,
            ),
          )
          .toList();

      final productosFiltrados = verDesactivados
          ? productos
          : productos.where((p) => p.activo).toList();

      if (!mounted) return;
      setState(() {
        _productos = productosFiltrados;
        _cargando = false;
      });
      _actualizarFilas();    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }

  Future<void> obtenerVentas() async {
    try {
      final resultado = await Basededatos.obtenerVentas();
      _ventas = (resultado['ventas'] as List<dynamic>? ?? [])
          .map((venta) => Map<String, dynamic>.from(venta as Map))
          .toList();
      _actualizarFilas();
      print('Ventas obtenidas: $_ventas');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }
  Future<void> obtenerMovimientos() async {
    try {
      final resultado = await Basededatos.obtenerMovimientosInventario();
      _movimientos = (resultado['movimientos'] as List<dynamic>? ?? [])
          .map((movimiento) => Map<String, dynamic>.from(movimiento as Map))
          .toList();
      _actualizarFilas();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }

  Future<void> obtenerSalidas() async {
    try {
      final resultado = await Basededatos.obtenerVentasYSalidas(
        sucursal: _sucursalSeleccionada,
      );
      _salidas = (resultado['movimientos'] as List<dynamic>? ?? [])
          .where((movimiento) => movimiento['naturaleza'] == 'egreso')
          .map((movimiento) => Map<String, dynamic>.from(movimiento as Map))
          .toList();
      _actualizarFilas();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _cargando = false;
      });
    }
  }
  
  Future<void> _calcularTotal() async {
    final resultado = await Basededatos.obtenerVentasYSalidas(
      desde: _fechaDesde,
      hasta: _fechaHasta,
      sucursal: _sucursalSeleccionada,
    );
    final movimientos = resultado['movimientos'];
    if (movimientos is! List) {
      if (!mounted) return;
      setState(() {
        _subtotal = 0;
        _salida = 0;
        _entrada = 0;
        _impuestos = 0;
        _total = 0;
      });
      return;
    }

    var subtotal = 0.0;
    var salida = 0.0;
    var entrada = 0.0;
    var impuestos = 0.0;
    for (final movimiento in movimientos) {
      if (movimiento is! Map) continue;
      final monto = (movimiento['monto'] as num?)?.toDouble() ?? 0.0;
      if (movimiento['naturaleza'] == 'egreso') {
        salida += monto;
      } else {
        subtotal += (movimiento['subtotal'] as num?)?.toDouble() ?? monto;
        impuestos += (movimiento['impuesto'] as num?)?.toDouble() ?? 0.0;
        entrada += monto;
      }
    }

    if (!mounted) return;
    setState(() {
      _subtotal = subtotal;
      _salida = salida;
      _entrada = entrada;
      _impuestos = impuestos;
      _total = entrada - salida;
    });
  }

  Future<void> _actualizarFilas() async {
    await _calcularTotal();
  
    final stateManagerSnack = _stateManagerSnack;
    if (stateManagerSnack != null) {
      stateManagerSnack.removeAllRows();
      stateManagerSnack.appendRows(_filas(categoria: 'snack'));
    }

    final stateManagerDemas = _stateManagerDemas;
    if (stateManagerDemas != null) {
      stateManagerDemas.removeAllRows();
      stateManagerDemas.appendRows(_filas());
    }

    final stateManagerVentas = _stateManagerVentas;
    if (stateManagerVentas != null) {
      stateManagerVentas.removeAllRows();
      stateManagerVentas.appendRows(_filasVentas());
    }

    final stateManagerMovimientos = _stateManagerMovimientos;
    if (stateManagerMovimientos != null) {
      stateManagerMovimientos.removeAllRows();
      stateManagerMovimientos.appendRows(_filasMovimientos());
    }

    final stateManagerSalidas = _stateManagerSalidas;
    if (stateManagerSalidas != null) {
      stateManagerSalidas.removeAllRows();
      stateManagerSalidas.appendRows(_filasSalidas());
    }
  }

  List<PlutoColumn> _columnasVentas() {
    return [
      PlutoColumn(
        title: 'Fecha',
        field: _fecha,
        type: PlutoColumnType.text(),
        width: 80,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Total',
        field: _precio,
        type: PlutoColumnType.number(),
        width: 40,
        textAlign: PlutoColumnTextAlign.left,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Método de pago',
        field: _metodoPago,
        type: PlutoColumnType.text(),
        width: 60,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Usuario',
        field: _usuario,
        type: PlutoColumnType.text(),
        width: 28,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Productos vendidos',
        field: _productosVendidos,
        type: PlutoColumnType.text(),
        width: 100,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
    ];
  }

  List<PlutoColumn> _columnasMovimientos() {
    return [
      PlutoColumn(
        title: 'Fecha',
        field: _fecha,
        type: PlutoColumnType.text(),
        width: 135,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Tipo',
        field: _tipoMovimiento,
        type: PlutoColumnType.text(),
        width: 125,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Producto / concepto',
        field: _nombre,
        type: PlutoColumnType.text(),
        width: 100,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Cantidad',
        field: _cantidadMovimiento,
        type: PlutoColumnType.number(),
        width: 90,
        textAlign: PlutoColumnTextAlign.left,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Monto',
        field: _montoMovimiento,
        type: PlutoColumnType.number(),
        width: 110,
        textAlign: PlutoColumnTextAlign.left,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Usuario',
        field: _usuario,
        type: PlutoColumnType.text(),
        width: 120,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
    ];
  }

  List<PlutoColumn> _columnasSalidas() {
    return [
      PlutoColumn(
        title: 'Fecha',
        field: _fecha,
        type: PlutoColumnType.text(),
        width: 135,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Concepto',
        field: _nombre,
        type: PlutoColumnType.text(),
        width: 240,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Monto',
        field: _montoMovimiento,
        type: PlutoColumnType.number(),
        width: 110,
        textAlign: PlutoColumnTextAlign.left,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Método de pago',
        field: _metodoPago,
        type: PlutoColumnType.text(),
        width: 140,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Usuario',
        field: _usuario,
        type: PlutoColumnType.text(),
        width: 120,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
    ];
  }

  List<PlutoColumn> _columnasInventario() {
    return [
      PlutoColumn(
        title: 'Codigo',
        field: _codigo,
        type: PlutoColumnType.text(),
        width: 16,
        enableRowChecked: true,
        renderer: (context) => _textoConElipsis(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Producto',
        field: _nombre,
        type: PlutoColumnType.text(),
        minWidth: 60,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Precio',
        field: _precio,
        type: PlutoColumnType.number(),
        width: 110,
        textAlign: PlutoColumnTextAlign.left,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Existencias',
        field: _existencias,
        type: PlutoColumnType.number(),
        textAlign: PlutoColumnTextAlign.left,
        width: 110,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
    ];
  }

  Widget _textoCompleto(Object? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        valor?.toString() ?? '',
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _textoConElipsis(Object? valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        valor?.toString() ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<PlutoRow> _filasVentas() {
    return _ventas
        .where((venta) => _estaEnRango(venta['fecha']))
        .map(
          (venta) => PlutoRow(
          
            cells: {
              _fecha: PlutoCell(value: _formatearFecha(venta['fecha'])),
              _nombre: PlutoCell(value: venta['productosVendidos'] ?? ''),
              _precio: PlutoCell(value: venta['total'] ?? 0),
              _metodoPago: PlutoCell(value: venta['metodo_pago'] ?? ''),
              _usuario: PlutoCell(
                value: venta['usuarioNombre'] ?? 'Sin usuario',
              ),
              _productosVendidos: PlutoCell(
                value: venta['productosVendidos'] ?? '',
              ),
            },
          ),
        )
        .toList();
  }

  List<PlutoRow> _filasMovimientos() {
    return _movimientos
        .where((movimiento) => _estaEnRango(movimiento['fecha']))
        .map(
          (movimiento) => PlutoRow(
            cells: {
              _codigo: PlutoCell(value: movimiento['producto_codigo']),
              _nombre: PlutoCell(
                value: movimiento['productoNombre'] ??
                    movimiento['concepto'] ??
                    'Sin objeto',
              ),
              _fecha: PlutoCell(value: _formatearFecha(movimiento['fecha'])),
              _tipoMovimiento: PlutoCell(
                value: movimiento['tipo'] ?? 'Sin tipo',
              ),
              _cantidadMovimiento: PlutoCell(
                value: movimiento['cantidad'] ?? 0,
              ),
              _montoMovimiento: PlutoCell(
                value: movimiento['naturaleza'] == 'egreso'
                    ? -((movimiento['monto'] as num?)?.toDouble() ?? 0.0)
                    : ((movimiento['monto'] as num?)?.toDouble() ?? 0.0),
              ),
              _usuario: PlutoCell(
                value: movimiento['usuarioNombre'] ?? 'Sin usuario',
              ),
            },
          ),
        )
        .toList();
  }

  List<PlutoRow> _filasSalidas() {
    return _salidas
        .where((salida) => _estaEnRango(salida['fecha']))
        .map(
          (salida) => PlutoRow(
            cells: {
              _fecha: PlutoCell(value: _formatearFecha(salida['fecha'])),
              _nombre: PlutoCell(value: salida['concepto'] ?? 'Sin concepto'),
              _montoMovimiento: PlutoCell(
                value: -((salida['monto'] as num?)?.toDouble() ?? 0.0),
              ),
              _metodoPago: PlutoCell(value: salida['metodo_pago'] ?? ''),
              _usuario: PlutoCell(
                value: salida['usuarioNombre'] ?? 'Sin usuario',
              ),
            },
          ),
        )
        .toList();
  }

  String _formatearFecha(Object? valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '');
    if (fecha == null) return 'Sin fecha';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year} '
        '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  bool _estaEnRango(Object? valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '');
    if (fecha == null) return false;
    if (_fechaDesde != null && fecha.isBefore(_fechaDesde!)) return false;
    if (_fechaHasta != null && fecha.isAfter(_fechaHasta!)) return false;
    return true;
  }

  List<PlutoRow> _filas({String? categoria}) {
    return _productos
        .where(
          (producto) {
            final categoriaProducto = producto.categoria?.trim().toLowerCase();
            return categoria == null
              ? !const {
                  'snack',
                  'otro',
                  'otros',
                }.contains(categoriaProducto)
              : categoriaProducto == categoria.trim().toLowerCase();
          },
        )
        .map(
          (producto) => PlutoRow(
            cells: {
              _codigo: PlutoCell(value: producto.codigo),
              _nombre: PlutoCell(value: producto.productoNombre),
              _marca: PlutoCell(value: producto.marcaNombre),
              _categoria: PlutoCell(value: producto.categoria ?? ''),
              _precio: PlutoCell(value: producto.precio),
              _existencias: PlutoCell(value: producto.existencias),
              _activo: PlutoCell(
                value: producto.activo ? 'Activo' : 'Inactivo',
              ),
            },
          ),
        )
        .toList();
  }

  List<PlutoRow> get _filasSeleccionadas {
    return [
      ...?_stateManagerSnack?.rows,
      ...?_stateManagerDemas?.rows,
    ].where((fila) => fila.checked == true).toList();
  }

  void _editarSeleccionados() {
    final filasSeleccionadas = _filasSeleccionadas;
    if (filasSeleccionadas.isEmpty || !mounted) return;

    final ediciones = filasSeleccionadas.map((fila) {
      final codigo = fila.cells[_codigo]?.value?.toString() ?? '';
      final producto = _productos.firstWhere((item) => item.codigo == codigo);

      return <String, dynamic>{
        _codigo: codigo,
        _nombre: fila.cells[_nombre]?.value?.toString() ?? '',
        _marca: fila.cells[_marca]?.value?.toString() ?? '',
        _categoria: fila.cells[_categoria]?.value?.toString() ?? '',
        _precio: fila.cells[_precio]?.value?.toString() ?? '',
        _existencias: fila.cells[_existencias]?.value?.toString() ?? '',
        _activo: fila.cells[_activo]?.value?.toString() ?? 'Activo',
        _imagen: producto.imagen,
        '_imagenRutaNueva': null,
        '_imagenNombreNuevo': null,
      };
    }).toList();

    final pageController = PageController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final tamanoPantalla = MediaQuery.sizeOf(dialogContext);
        final anchoDialogo = tamanoPantalla.width < 760
            ? tamanoPantalla.width * 0.82
            : 720.0;
        final altoDialogo = tamanoPantalla.height < 650
            ? tamanoPantalla.height * 0.55
            : 420.0;
        var paginaActual = 0;
        final messenger = ScaffoldMessenger.of(context);

        Future<ImageProvider?> obtenerImagenProducto(String nombreImagen) async {
          final imagenGuardada = await GestorImagenes.obtenerImageProvider(
            nombreImagen,
          );
          if (imagenGuardada != null) return imagenGuardada;

          final imagenActivos = File(
            '${Directory.current.path}${Platform.pathSeparator}activos'
            '${Platform.pathSeparator}$nombreImagen',
          );
          if (await imagenActivos.exists()) {
            return FileImage(imagenActivos);
          }
          return null;
        }

        Future<bool> guardarEdicion(Map<String, dynamic> edicion) async {
          final precio = double.tryParse(edicion[_precio].toString());
          final existencias = int.tryParse(
            edicion[_existencias].toString(),
          );

          if (edicion[_nombre].toString().trim().isEmpty ||
              edicion[_marca].toString().trim().isEmpty ||
              edicion[_categoria].toString().trim().isEmpty ||
              precio == null ||
              precio < 0 ||
              existencias == null ||
              existencias < 0) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Revisa los datos: nombre, marca, categoría, precio y existencias.',
                ),
              ),
            );
            return false;
          }

          final datos = <String, Object?>{
            'productoNombre': edicion[_nombre].toString().trim(),
            'marcaNombre': edicion[_marca].toString().trim(),
            'categoria': edicion[_categoria].toString().trim(),
            'precio': precio,
            'existencias': existencias,
            'activo': edicion[_activo] == 'Activo' ? 1 : 0,
          };

          final rutaImagenNueva = edicion['_imagenRutaNueva'] as String?;
          if (rutaImagenNueva != null) {
            final nombreImagen = edicion['_imagenNombreNuevo'] as String?;
            if (nombreImagen == null || nombreImagen.isEmpty) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('La imagen seleccionada no es válida.'),
                ),
              );
              return false;
            }

            final imagenGuardada = await GestorImagenes.guardarImagen(
              rutaImagenNueva,
              nombreImagen,
            );
            datos[_imagen] = imagenGuardada;
            edicion[_imagen] = imagenGuardada;
            edicion['_imagenRutaNueva'] = null;
            edicion['_imagenNombreNuevo'] = null;
          }

          final resultado = await Basededatos.actualizarProducto(
            edicion[_codigo].toString(),
            datos,
          );

          if (resultado['exito'] != true) {
            messenger.showSnackBar(
              SnackBar(content: Text(resultado['mensaje'].toString())),
            );
            return false;
          }
          return true;
        }

        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: Text(
                'Editar productos (${ediciones.length})',
              ),
              content: SizedBox(
                width: anchoDialogo,
                height: altoDialogo,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: ediciones.length,
                  onPageChanged: (indice) {
                    actualizarDialogo(() => paginaActual = indice);
                  },
                  itemBuilder: (context, index) {
                    final edicion = ediciones[index];

                    Widget campoTexto(
                      String clave,
                      String etiqueta, {
                      TextInputType? tipoTeclado,
                    }) {
                      return TextFormField(
                        initialValue: edicion[clave]?.toString() ?? '',
                        keyboardType: tipoTeclado,
                        decoration: InputDecoration(labelText: etiqueta),
                        onChanged: (valor) => edicion[clave] = valor,
                      );
                    }

                    Widget imagenProducto() {
                      final rutaNueva = edicion['_imagenRutaNueva'] as String?;
                      if (rutaNueva != null) {
                        return Image.file(File(rutaNueva), fit: BoxFit.cover);
                      }

                      final nombreImagen = edicion[_imagen].toString();
                      if (nombreImagen.isEmpty) {
                        return const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        );
                      }

                      return FutureBuilder<ImageProvider?>(
                        future: obtenerImagenProducto(nombreImagen),
                        builder: (context, snapshot) {
                          final imagen = snapshot.data;
                          if (imagen == null) {
                            return const Center(
                              child: Icon(Icons.image_not_supported_outlined),
                            );
                          }
                          return Image(image: imagen, fit: BoxFit.cover);
                        },
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Producto ${index + 1} de ${ediciones.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text('Código: ${edicion[_codigo]}'),
                          const SizedBox(height: 12),
                          Center(
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: imagenProducto(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final resultado = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.image,
                                          allowMultiple: false,
                                        );
                                    if (resultado == null ||
                                        resultado.files.isEmpty ||
                                        !context.mounted) {
                                      return;
                                    }

                                    final archivo = resultado.files.first;
                                    final ruta = archivo.path;
                                    if (ruta == null) return;

                                    actualizarDialogo(() {
                                      edicion['_imagenRutaNueva'] = ruta;
                                      edicion['_imagenNombreNuevo'] = archivo.name;
                                    });
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(
                                    edicion['_imagenNombreNuevo']?.toString() ??
                                        'Cambiar imagen',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          campoTexto(_nombre, 'Nombre'),
                          const SizedBox(height: 12),
                          campoTexto(_marca, 'Marca'),
                          const SizedBox(height: 12),
                          campoTexto(_categoria, 'Categoría'),
                          const SizedBox(height: 12),
                          campoTexto(
                            _precio,
                            'Precio',
                            tipoTeclado: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          campoTexto(
                            _existencias,
                            'Existencias',
                            tipoTeclado: TextInputType.number,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: edicion[_activo] == 'Activo'
                                ? 'Activo'
                                : 'Inactivo',
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Activo',
                                child: Text('Activo'),
                              ),
                              DropdownMenuItem(
                                value: 'Inactivo',
                                child: Text('Inactivo'),
                              ),
                            ],
                            onChanged: (valor) {
                              if (valor != null) {
                                actualizarDialogo(() {
                                  edicion[_activo] = valor;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final guardado = await guardarEdicion(
                      ediciones[paginaActual],
                    );
                    if (!guardado || !mounted) return;

                    if (paginaActual < ediciones.length - 1) {
                      final siguiente = paginaActual + 1;
                      actualizarDialogo(() => paginaActual = siguiente);
                      await pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Producto guardado. Continúa con el producto ${siguiente + 1}.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    await _cargarProductos();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Productos actualizados correctamente.'),
                      ),
                    );
                  },
                  icon: Icon(
                    paginaActual < ediciones.length - 1
                        ? Icons.arrow_forward
                        : Icons.save,
                  ),
                  label: Text(
                    paginaActual < ediciones.length - 1
                        ? 'Guardar y siguiente'
                        : 'Guardar y cerrar',
                  ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(pageController.dispose);
  }

  Future<void> _guardarCambios() async {
    final stateManagersVentas = [
      _stateManagerSnack,
      _stateManagerDemas,
    ].whereType<PlutoGridStateManager>();
    if (stateManagersVentas.isEmpty) return;

    try {
      for (final stateManager in stateManagersVentas) {
        for (final fila in stateManager.rows) {
          final resultado = await Basededatos.actualizarProducto(
            fila.cells[_codigo]!.value as String,
            {
              'productoNombre': fila.cells[_nombre]!.value as String,
              'marcaNombre': fila.cells[_marca]!.value as String,
              'categoria': fila.cells[_categoria]!.value as String,
              'precio': (fila.cells[_precio]!.value as num).toDouble(),
              'existencias': (fila.cells[_existencias]!.value as num).toInt(),
            },
          );
          if (resultado['exito'] != true) {
            throw Exception(resultado['mensaje']);
          }
        }
      }

      await _cargarProductos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar los cambios: $error')),
        );
      }
    }
  }

  Future<void> _desactivarSeleccionados() async {
    final filas = _filasSeleccionadas;
    if (filas.isEmpty) {
      print('No hay filas seleccionadas.');
      return;
    }

    final codigos = filas
        .map((fila) => fila.cells[_codigo]!.value as String)
        .toList();
    final resultado = await Basededatos.desactivarProductos(codigos);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultado['mensaje'] as String)));
    if (resultado['exito'] == true) {
      await _cargarProductos();
    }
  }

  Future<void> _marcarComoFaltantes() async {
    final filas = _filasSeleccionadas;
    if (filas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos seleccionados.')),
      );
      return;
    }

    final productos = filas
        .map(
          (fila) => _productos.firstWhere(
            (producto) => producto.codigo == fila.cells[_codigo]!.value,
          ),
        )
        .toList();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReporteFaltantes(productos: productos)),
    );
  }

  void _agregarProducto() {
    showDialog<void>(
      context: context,
      builder: (context) => Agregarobjeto(alTenerExito: _cargarProductos),
    );
  }

  void _aplicarBusqueda(String texto) {
    final consulta = texto.trim().toLowerCase();
    final filtro = consulta.isEmpty
        ? null
        : (PlutoRow fila) {
            final nombre = fila.cells[_nombre]?.value.toString().toLowerCase();
            final codigo = fila.cells[_codigo]?.value.toString().toLowerCase();
            return (nombre?.contains(consulta) ?? false) || (codigo?.contains(consulta) ?? false);
          };

    _stateManagerSnack?.setFilter(filtro);
    _stateManagerDemas?.setFilter(filtro);
    _stateManagerVentas?.setFilter(filtro);
    _stateManagerMovimientos?.setFilter(filtro);
  }

  Future<void> _seleccionarRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime.now(),
      initialDateRange: _fechaDesde != null && _fechaHasta != null
          ? DateTimeRange(
              start: DateTime(
                _fechaDesde!.year,
                _fechaDesde!.month,
                _fechaDesde!.day,
              ),
              end: DateTime(
                _fechaHasta!.year,
                _fechaHasta!.month,
                _fechaHasta!.day,
              ),
            )
          : null,
    );
    if (rango == null || !mounted) return;

    final horaDesde = _fechaDesde?.hour ?? 0;
    final minutoDesde = _fechaDesde?.minute ?? 0;
    final horaHasta = _fechaHasta?.hour ?? 23;
    final minutoHasta = _fechaHasta?.minute ?? 59;

    setState(() {
      _fechaDesde = DateTime(
      rango.start.year,
      rango.start.month,
      rango.start.day,
        horaDesde,
        minutoDesde,
      );
      _fechaHasta = DateTime(
      rango.end.year,
      rango.end.month,
      rango.end.day,
        horaHasta,
        minutoHasta,
        59,
        999,
      );
    });
    _guardarRangoFechas();
    _actualizarFilas();
  }

void _seleccionarFechaHoy(){
    setState(() {
      final ahora = DateTime.now();
      _fechaDesde = DateTime(ahora.year, ahora.month, ahora.day, 0, 0);
      _fechaHasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59, 999);
    });
    _guardarRangoFechas();
    _actualizarFilas();
  }

  void _seleccionarHorario(String periodo) {
    final ahora = DateTime.now();
    final rango = _horarios[periodo];
    if (rango == null) return;
    final partesDesde = rango[0].split(':');
    final partesHasta = rango[1].split(':');
    setState(() {
      _fechaDesde = DateTime(ahora.year, ahora.month, ahora.day, int.parse(partesDesde[0]), int.parse(partesDesde[1]));
      _fechaHasta = DateTime(ahora.year, ahora.month, ahora.day, int.parse(partesHasta[0]), int.parse(partesHasta[1]), 59, 999);
    });
    _guardarRangoFechas();
    _actualizarFilas();
  }

  Future<void> _seleccionarRangoHoras() async {
    final ahora = DateTime.now();
    final fechaDesdeActual = _fechaDesde ?? DateTime(ahora.year, ahora.month, ahora.day);
    final fechaHastaActual = _fechaHasta ?? fechaDesdeActual;

    final horaDesde = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaDesdeActual),
      helpText: 'Hora inicial',
    );


    
    if (horaDesde == null || !mounted) return;

    final horaHasta = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(fechaHastaActual),
      helpText: 'Hora final',
    );
    if (horaHasta == null || !mounted) return;

    final fechaDesde = DateTime(
      fechaDesdeActual.year,
      fechaDesdeActual.month,
      fechaDesdeActual.day,
      horaDesde.hour,
      horaDesde.minute,
    );
    final fechaHasta = DateTime(
      fechaHastaActual.year,
      fechaHastaActual.month,
      fechaHastaActual.day,
      horaHasta.hour,
      horaHasta.minute,
      59,
      999,
    );

    if (fechaDesde.isAfter(fechaHasta)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora inicial debe ser anterior a la hora final.'),
        ),
      );
      return;
    }

    setState(() {
      _fechaDesde = fechaDesde;
      _fechaHasta = fechaHasta;
    });
    _guardarRangoFechas();
    _actualizarFilas();
  }

  void _limpiarRangoFechas() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
    });
    _guardarRangoFechas();
    _actualizarFilas();
  }

  Future<void> _alternarDesactivados() async {
    setState(() {
      verDesactivados = !verDesactivados;
    });
    await _cargarProductos();
  }

  String _textoRangoFechas() {
    if (_fechaDesde == null || _fechaHasta == null) return 'Todas las fechas';
    return '${_formatearSoloFecha(_fechaDesde!)} - ${_formatearSoloFecha(_fechaHasta!)}';
  }

  String _textoRangoHoras() {
    if (_fechaDesde == null || _fechaHasta == null) return 'Todas las horas';
    return '${_formatearSoloHora(_fechaDesde!)} - ${_formatearSoloHora(_fechaHasta!)}';
  }

  String _formatearSoloFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _formatearSoloHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  Widget _tablaProductos({
    required String titulo,
    required List<PlutoRow> filas,
    required List<PlutoColumn> columnas,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 400,
          width: titulo == 'Movimientos'
              ? 700
             : 520,
              
          child: PlutoGrid(
  
            columns: columnas,
            rows: filas,
            onLoaded: (evento) {
              final manager = evento.stateManager;
              manager.setShowColumnFilter(false);
              if (titulo == 'Snacks') {
                _stateManagerSnack = manager;
              } else if (titulo == 'Ventas') {
                _stateManagerVentas = manager;
              } else if (titulo == 'Salidas') {
                _stateManagerSalidas = manager;
              } else if (titulo == 'Movimientos') {
                _stateManagerMovimientos = manager;
              } else {
                _stateManagerDemas = manager;
              }
              _aplicarBusqueda(_busquedaController.text);
            },
            configuration: PlutoGridConfiguration(
              columnSize: const PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.scale,
              ),
              style: PlutoGridStyleConfig(
                rowHeight: titulo == 'Movimientos' || titulo == 'Ventas'
                    ? 50
                    : 24,
                gridBorderColor: Theme.of(context).colorScheme.outlineVariant,
                activatedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _mouseSobreCaja = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        padding: const EdgeInsets.all(2),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            ContenedorCantidad(etiqueta: 'Subtotal', subtotal: _subtotal),
            ContenedorCantidad(etiqueta: 'Salida', subtotal: _salida),
            ContenedorCantidad(etiqueta: 'Entrada', subtotal: _entrada),
            ContenedorCantidad(etiqueta: 'Impuestos', subtotal: _impuestos),
            ContenedorCantidad(etiqueta: 'Total', subtotal: _total),
          ],
        ),
      ),
     
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              onHover: (hovered) {
                setState(() => _mouseSobreCaja = hovered);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                elevation: 0,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(45),
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(45),
                  gradient: LinearGradient(
                    colors: _mouseSobreCaja
                        ? const [Color(0xFF514EFF), Color(0xFF5661D9)]
                        : const [Color(0xFF0F0CDA), Color(0xFF1720A1)],
                  ),
                ),
                child: const Text(
                  '📄 Caja',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const Divider(height: 10, thickness: 3),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                runSpacing: 10,
                children: [
                    //Selector de fechas
                               Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Fecha',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                            if (_fechaDesde != null)
                  Tooltip(
                    message: 'Limpiar filtro de fechas',
                    child: IconButton(
                      onPressed: _limpiarRangoFechas,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                        ],
                      ),
                      Row(
                        spacing: 3,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _seleccionarRangoFechas,
                            icon: const Icon(Icons.date_range),
                            label: Text(_textoRangoFechas()),
                          ),
                                                    Tooltip(
                            message: 'Hoy',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: _seleccionarFechaHoy,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.today),
                                ],
                              ),
                            
                            ),
                       
                      ),
                    
                        ],
                   
                  
                ),
  
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 3,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _seleccionarRangoHoras,
                            icon: const Icon(Icons.access_time),
                            label: Text(_textoRangoHoras()),
                          ),
                          Tooltip(
                            message: 'Horario de la mañana',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: () => _seleccionarHorario("mañana"),
                              child: Row(
                              
                                children: const [
                                  Icon(Icons.wb_sunny_outlined),
                                  Icon(Icons.sunny),
                                ],
                              ),
                            
                            ),
                          ),
                          Tooltip(
                            message: 'Horario de la tarde',
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.all(0),
                              ),
                              onPressed: () => _seleccionarHorario("tarde"),
                              child: Row(
                                children: const [
                                  Icon(Icons.sunny),
                                  Icon(Icons.nightlight_round),
                                ],
                              ),
                            
                            ),
                       
                      ),
                    ],),
             ],
                ),
                
                Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,

                children: [


                                  Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
  
               Tooltip(
                  message: 'Guardar cambios',
                  child: IconButton.filledTonal(
                    onPressed: () {
                      _guardarCambios();
                      setState(() {});
                    },
                    icon: const Icon(Icons.save_outlined),
                  ),
                ),
                Tooltip(
                  message: 'Agregar producto',
                  child: IconButton.filledTonal(
                    onPressed: _agregarProducto,
                    icon: const Icon(Icons.add),
                  ),
                ),
                                Tooltip(
                  message: 'Editar productos seleccionados',
                  child: IconButton.filledTonal(
                    onPressed: _editarSeleccionados,
                    icon: const Icon(Icons.edit),
                  ),
                ),
 
                Tooltip(
                  message: 'Desactivar productos seleccionados',
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: colors.errorContainer,
                      foregroundColor: colors.onErrorContainer,
                    ),
                    onPressed: _desactivarSeleccionados,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
                Tooltip(
                  message: verDesactivados
                      ? 'Ocultar productos desactivados'
                      : 'Mostrar productos desactivados',
                  child: IconButton.filledTonal(
                    onPressed: _alternarDesactivados,
                    icon: Icon(
                      verDesactivados ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Reportar faltantes',
                  child: IconButton.filledTonal(
                    onPressed: _marcarComoFaltantes,
                    icon: const Icon(Icons.report_gmailerrorred),
                  ),
                ),
                                  ],
                ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _busquedaController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar producto',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _aplicarBusqueda,
                  ),
                ),

                                Container(
                                 
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(45),
                                    
                                  ),
                                  child: DropdownButton<int>(
                                    style: TextStyle(color: Colors.black
                                
                                    ),
                                    focusColor: Colors.transparent,
                                    enableFeedback: false,
                                    borderRadius: BorderRadius.circular(30),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    value: _sucursalSeleccionada,
                                                    items: const [
                                                      DropdownMenuItem(value: 1, child: Text('BODY 1')),
                                                      DropdownMenuItem(value: 2, child: Text('BODY 2')),
                                                    ],
                                                    onChanged: (sucursal) {
                                                      if (sucursal == null) return;
                                                      setState(() => _sucursalSeleccionada = sucursal);
                                                      _cargarProductos();
                                                      obtenerSalidas();
                                                    },
                                                  ),
                                ),
                ],
              ),




                ],
                ),


              
              ],
            ),
            ),
            const SizedBox(height: 10),
           Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
           ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text('Error al cargar el inventario: $_error'),
                    )
                  : SingleChildScrollView(
             
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Scrollbar(
                               thumbVisibility: true,
                                controller: _inventarioScrollController,
                                scrollbarOrientation: ScrollbarOrientation.bottom,
                                trackVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.depth == 0,
                                child: SingleChildScrollView(
                                  controller: _inventarioScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: Row(
                                    spacing: 4,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _tablaProductos(
                                        titulo: 'Snacks',
                                        filas: _filas(categoria: 'snack'),
                                        columnas: _columnasInventario(),
                                      ),
                                      _tablaProductos(
                                        titulo: 'Suplementos',
                                        filas: _filas(),
                                        columnas: _columnasInventario(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                           Scrollbar(
                               thumbVisibility: true,
                                controller: _ventassalidasScrollController,
                                scrollbarOrientation: ScrollbarOrientation.bottom,
                                trackVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.depth == 0,
                                child: SingleChildScrollView(
                                  controller: _ventassalidasScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: Row(
                                    spacing: 4,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                              _tablaProductos(
                                titulo: 'Ventas',
                                filas: _filasVentas(),
                                columnas: _columnasVentas(),
                              ),
                              _tablaProductos(
                                titulo: 'Salidas',
                                filas: _filasSalidas(),
                                columnas: _columnasSalidas(),
                              ),
                            ],
                          ),
                        ),
                      ),
             
                              Scrollbar(
                                controller: _movimientosScrollController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                notificationPredicate: (notification) =>
                                    notification.depth == 0,
                                child: SingleChildScrollView(
                                  controller: _movimientosScrollController,
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: _tablaProductos(
                                    titulo: 'Movimientos',
                                    filas: _filasMovimientos(),
                                    columnas: _columnasMovimientos(),
                                  ),
                                ),
                              ),
                        
                            ],
                          ),
          
                      
              )   ),
        
      ),]
       ),
       ), 
       );


    
  }


}

class ContenedorCantidad extends StatelessWidget {
  const ContenedorCantidad({
    super.key,
    required String etiqueta,
    required double subtotal,
  }) : _etiqueta = etiqueta,
       _subtotal = subtotal;

  final String _etiqueta;
  final double _subtotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: const Color.fromARGB(255, 34, 0, 251),
            width: 3,
          ),
        ),

      ),
      child: Text("$_etiqueta: \$${_subtotal.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleMedium));
  }
}



Future<TimeOfDay?> _selectorDeHora(BuildContext context, String titulo, DateTime fechaDesdeActual, Map<String,TimeOfDay> horasPredefinidas,) {
  return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Wrap(
          spacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: '${fechaDesdeActual.hour.toString().padLeft(2, '0')}:${fechaDesdeActual.minute.toString().padLeft(2, '0')}',
              ),
              decoration: const InputDecoration(
                labelText: 'Hora seleccionada',
              ),
            ),
          ...[ for (var entry in horasPredefinidas.entries)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(entry.value);
                },
                child: Text(entry.key),
              ),]
          ],
        ),
      ),
    );
}