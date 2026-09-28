import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/widgets/agregarobjeto.dart';

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
  static const _metodoPago = 'metodoPago';
  static const _productosVendidos = 'productosVendidos';
  static const _usuario = 'usuario';
  static const _fecha = 'fecha';
  static const _tipoMovimiento = 'tipoMovimiento';
  static const _cantidadMovimiento = 'cantidadMovimiento';

  bool verDesactivados = true;

  final TextEditingController _busquedaController = TextEditingController();
  PlutoGridStateManager? _stateManagerSnack;
  PlutoGridStateManager? _stateManagerDemas;
  PlutoGridStateManager? _stateManagerVentas;
  PlutoGridStateManager? _stateManagerMovimientos;
  int _sucursalSeleccionada = 1;
  bool _cargando = true;
  String? _error;
  List<Objeto> _productos = [];
  List<Map<String, dynamic>> _ventas = [];
  List<Map<String, dynamic>> _movimientos = [];
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    obtenerVentas();
    obtenerMovimientos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
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
      _actualizarFilas();
    } catch (error) {
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

  void _actualizarFilas() {
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
  }

  List<PlutoColumn> _columnasVentas() {
    return [
      PlutoColumn(
        title: 'Fecha',
        field: _fecha,
        type: PlutoColumnType.text(),
        width: 110,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Venta',
        field: _codigo,
        type: PlutoColumnType.number(),
        width: 80,
        textAlign: PlutoColumnTextAlign.right,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Total',
        field: _precio,
        type: PlutoColumnType.number(),
        width: 110,
        textAlign: PlutoColumnTextAlign.right,
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
      PlutoColumn(
        title: 'Productos vendidos',
        field: _productosVendidos,
        type: PlutoColumnType.text(),
        width: 280,
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
        width: 115,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Producto',
        field: _nombre,
        type: PlutoColumnType.text(),
        width: 190,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Movimiento',
        field: _tipoMovimiento,
        type: PlutoColumnType.text(),
        width: 110,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Cantidad',
        field: _cantidadMovimiento,
        type: PlutoColumnType.number(),
        width: 90,
        textAlign: PlutoColumnTextAlign.right,
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
        width: 110,
        enableRowChecked: true,
        renderer: (context) => _textoConElipsis(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Producto',
        field: _nombre,
        type: PlutoColumnType.text(),
        minWidth: 190,
        renderer: (context) => _textoCompleto(context.cell.value),
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Precio',
        field: _precio,
        type: PlutoColumnType.number(),
        width: 110,
        textAlign: PlutoColumnTextAlign.right,
        enableFilterMenuItem: false,
        enableContextMenu: false,
      ),
      PlutoColumn(
        title: 'Existencias',
        field: _existencias,
        type: PlutoColumnType.number(),
        textAlign: PlutoColumnTextAlign.right,
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
              _codigo: PlutoCell(value: venta['ventaCodigo']),
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
              _nombre: PlutoCell(value: movimiento['productoNombre'] ?? ''),
              _fecha: PlutoCell(value: _formatearFecha(movimiento['fecha'])),
              _tipoMovimiento: PlutoCell(value: movimiento['tipo'] ?? ''),
              _cantidadMovimiento: PlutoCell(
                value: movimiento['cantidad'] ?? 0,
              ),
              _usuario: PlutoCell(
                value: movimiento['usuarioNombre'] ?? 'Sin usuario',
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
        '${fecha.year}';
  }

  bool _estaEnRango(Object? valor) {
    final fecha = DateTime.tryParse(valor?.toString() ?? '');
    if (fecha == null) return false;
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    if (_fechaDesde != null && dia.isBefore(_fechaDesde!)) return false;
    if (_fechaHasta != null && dia.isAfter(_fechaHasta!)) return false;
    return true;
  }

  List<PlutoRow> _filas({String? categoria}) {
    return _productos
        .where(
          (producto) => categoria == null
              ? !const {
                  'snack',
                  'otro',
                  'otros',
                }.contains(producto.categoria?.toLowerCase())
              : producto.categoria?.toLowerCase() == categoria,
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
            final nombre = fila.cells[_nombre]!.value.toString().toLowerCase();
            final codigo = fila.cells[_codigo]!.value.toString().toLowerCase();
            return nombre.contains(consulta) || codigo.contains(consulta);
          };

    _stateManagerSnack?.setFilter(filtro);
    _stateManagerDemas?.setFilter(filtro);
    _stateManagerVentas?.setFilter(filtro);
    _stateManagerMovimientos?.setFilter(filtro);
  }

  Future<void> _seleccionarRangoFechas() async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fechaDesde != null && _fechaHasta != null
          ? DateTimeRange(start: _fechaDesde!, end: _fechaHasta!)
          : null,
    );
    if (rango == null || !mounted) return;
    setState(() {
      _fechaDesde = DateTime(
        rango.start.year,
        rango.start.month,
        rango.start.day,
      );
      _fechaHasta = DateTime(rango.end.year, rango.end.month, rango.end.day);
    });
    _actualizarFilas();
  }

  void _limpiarRangoFechas() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
    });
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
    return '${_formatearFecha(_fechaDesde)} - ${_formatearFecha(_fechaHasta)}';
  }

  Widget _tablaProductos({
    required String titulo,
    required List<PlutoRow> filas,
    required List<PlutoColumn> columnas,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 700,
          width: titulo == 'Movimientos'
              ? 700
              : 'Ventas' == titulo
              ? 1200
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
      body: Padding(
        padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
                DropdownButton<int>(
                  value: _sucursalSeleccionada,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('BODY 1')),
                    DropdownMenuItem(value: 2, child: Text('BODY 2')),
                  ],
                  onChanged: (sucursal) {
                    if (sucursal == null) return;
                    setState(() => _sucursalSeleccionada = sucursal);
                    _cargarProductos();
                  },
                ),
                OutlinedButton.icon(
                  onPressed: _seleccionarRangoFechas,
                  icon: const Icon(Icons.date_range),
                  label: Text(_textoRangoFechas()),
                ),
                if (_fechaDesde != null)
                  Tooltip(
                    message: 'Limpiar filtro de fechas',
                    child: IconButton(
                      onPressed: _limpiarRangoFechas,
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                Tooltip(
                  message: 'Agregar producto',
                  child: IconButton.filled(
                    onPressed: _agregarProducto,
                    icon: const Icon(Icons.add),
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text('Error al cargar el inventario: $_error'),
                    )
                  : SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _tablaProductos(
                                titulo: 'Snacks',
                                filas: _filas(categoria: 'snack'),
                                columnas: _columnasInventario(),
                              ),
                              const SizedBox(height: 20),
                              _tablaProductos(
                                titulo: 'Suplementos',
                                filas: _filas(),
                                columnas: _columnasInventario(),
                              ),

                              _tablaProductos(
                                titulo: 'Ventas',
                                filas: _filasVentas(),
                                columnas: _columnasVentas(),
                              ),
                              _tablaProductos(
                                titulo: 'Movimientos',
                                filas: _filasMovimientos(),
                                columnas: _columnasMovimientos(),
                              ),
                              // end of children
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
