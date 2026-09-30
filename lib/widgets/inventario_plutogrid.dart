import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/widgets/agregarobjeto.dart';
import 'package:pov_suplementos/widgets/reportefaltantes.dart';

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
  static const _montoMovimiento = 'montoMovimiento';

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
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    obtenerVentas();
    obtenerSalidas();
    obtenerMovimientos();
    _calcularTotal();
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
      setState(() => _total = 0);
      return;
    }

    final total = movimientos.fold<double>(
      0.0,
      (sum, movimiento) {
        if (movimiento is! Map) return sum;
        final monto = (movimiento['monto'] as num?)?.toDouble() ?? 0.0;
        return movimiento['naturaleza'] == 'egreso'
            ? sum - monto
            : sum + monto;
      },
    );

    if (!mounted) return;
    setState(() => _total = total);
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
      floatingActionButton: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45),
          color: Colors.lightGreen,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
            Text("\$${_total.toStringAsFixed(2)}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
          ]
        )
      ),
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
                    obtenerSalidas();
                  },
                ),
                Row(
                  spacing: 2,
                  mainAxisSize: MainAxisSize.min,
                  children: [
  
               Tooltip(
                  message: 'Guardar cambios',
                  child: IconButton.filled(
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
                                Container(
                                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    spacing: 3,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                              onPressed: _seleccionarRangoHoras,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.swipe_down_alt_rounded),
                                ],
                              ),
                            
                            ),
                       
                      ),
                    
                        ],
                   
                  
                ),
  
                      Row(
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
                                minimumSize: const Size(40, 40),
                              ),
                              onPressed: _seleccionarRangoHoras,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
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
                                minimumSize: const Size(40, 40),
                              ),
                              onPressed: _seleccionarRangoHoras,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.sunny),
                                  Icon(Icons.nightlight_round),
                                ],
                              ),
                            
                            ),
                       
                      ),
                    ],),
             ],
                ),),
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
        ),
      ),]
       ),
       ), 
       );


    
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