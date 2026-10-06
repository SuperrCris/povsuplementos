import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/funciones/descargarimagenes.dart';
import 'package:pov_suplementos/funciones/gestor_imagenes.dart';
import 'package:pov_suplementos/funciones/obtenerimagenes.dart';
import 'package:pov_suplementos/widgets/agregarobjeto.dart';
import 'package:pov_suplementos/widgets/botonesbusqueda.dart';
import 'package:pov_suplementos/widgets/botonusuario.dart';
import 'package:pov_suplementos/widgets/busquedasucursales.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';
import 'package:pov_suplementos/widgets/conexiones.dart';
import 'package:pov_suplementos/widgets/agregarsalidas.dart';
import 'package:pov_suplementos/widgets/inventario_plutogrid.dart';
import 'package:pov_suplementos/widgets/ventanacompra.dart';
import 'package:pov_suplementos/widgets/ventanareportes.dart';
import 'package:pov_suplementos/widgets/ventanaterminalpago.dart';

import 'package:pov_suplementos/widgets/botonMaterial.dart';

// Importaciones del sistema de autenticación
import 'package:pov_suplementos/auth/gestorsesion.dart';
import 'package:pov_suplementos/auth/iniciopagina.dart';
import 'package:pov_suplementos/auth/BD_semillero.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Basededatos.database;
  await DBSemillero.crearUsuariosDefecto();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic> config = {"tema": ThemeMode.light, "sucursal": 1};

  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode = widget.config["tema"];
  late int sucursal = widget.config["sucursal"];

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Suplementos BEG',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('es', 'ES'), Locale('en', 'US')],

      theme: ThemeData(
        hoverColor: Colors.blue.shade50,
        primaryColor: Colors.blue.shade300,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade300,
          brightness: Brightness.light,
        ),

        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade300,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey.shade800,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.blue.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.blue.shade300),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue.shade300),
      ),
      themeMode: _themeMode,

      home: GestorDeSesion(
        paginaDeInicioBuilder: () => const Iniciopagina(),
        alExpirarSesion: () {},
        child: HomeScreen(
          onThemeToggle: toggleTheme,
          currentThemeMode: _themeMode,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.onThemeToggle,
    required this.currentThemeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool enLinea = false;


  final CarritoControlador _carritoController = CarritoControlador();
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  late Future<List<Objeto>> _productosFuture;

  final TextEditingController _searchController = TextEditingController();
  String _filtroTexto = '';

  Future<bool> ventanaTerminalPago(BuildContext context, double total) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PagoTerminal(total: total)),
    );
    return resultado ?? false;
  }

  @override
  void initState() {
    super.initState();
    _productosFuture = obtenerInfo();
    _carritoController.setRefreshCallback(_actualizarTablaProductos);
    _carritoController.setTerminalPagoCallback(
      () => ventanaTerminalPago(context, _carritoController.total),
    );

    _searchController.addListener(() {
      setState(() {
        _filtroTexto = _searchController.text.toLowerCase();
      });
    });
  }

  void _agregarAlCarrito(Objeto objeto) {
    if (objeto.existencias <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${objeto.productoNombre} está agotado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _carritoController.agregarAlCarrito(objeto);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _actualizarTablaProductos() async {
    setState(() {
      _productosFuture = obtenerInfo();
    });
  }

  Future<List<Objeto>> obtenerInfo() async {
    List<Objeto> objetos = [];
    descargarImagenes();
    final images = await obtenerTodasLasImagenes('activos');

    final productos = await Basededatos.obtenerObjetos();
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
      final nombreImagen = producto['imagen']?.toString().trim() ?? '';
      if (nombreImagen.isNotEmpty) {
        final imagenGuardada = await GestorImagenes.obtenerImageProvider(
          nombreImagen,
        );
        if (imagenGuardada != null) {
          objetoactual.imagenWidget = Image(
            image: imagenGuardada,
            fit: BoxFit.cover,
          );
        } else {
          for (var imageFile in images) {
            if (imageFile.path.toLowerCase().endsWith(
              nombreImagen.toLowerCase(),
            )) {
              objetoactual.imagenWidget = Image.file(
                imageFile,
                fit: BoxFit.cover,
              );
              break;
            }
          }
        }
      }
      print(
        "Objeto agregado: ${objetoactual.productoNombre} con codigo ${objetoactual.codigo}",
      );
      objetos.add(objetoactual);
    }
    return objetos;
  }

  List<Objeto> _filtrarProductos(List<Objeto> productos) {
    if (_filtroTexto.isEmpty) {
      productos.sort((a, b) {
        final aEsSnack = a.categoria?.toLowerCase() == "snack";
        final bEsSnack = b.categoria?.toLowerCase() == "snack";

        if (aEsSnack && !bEsSnack) return -1;
        if (!aEsSnack && bEsSnack) return 1;
        return 0;
      });
      return productos;
    }

    return productos.where((producto) {
      return producto.codigo.toLowerCase().contains(_filtroTexto) ||
          producto.productoNombre.toLowerCase().contains(_filtroTexto) ||
          producto.marcaNombre.toLowerCase().contains(_filtroTexto);
    }).toList();
  }

  Widget _tituloSeccion(String titulo, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Text(
        titulo,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }



  SliverGrid _rejillaProductos(
    BuildContext context,
    List<Objeto> productos, {
    required bool snacks,
  }) {
    final anchoTarjeta = 300;
    final columnas = (MediaQuery.of(context).size.width / anchoTarjeta)
        .floor()
        .clamp(1, 8);

    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        final objeto = productos[index];
        return WidgetVenta(
          objeto: objeto,
          callback: () => _agregarAlCarrito(objeto),
        );
      }, childCount: productos.length),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: snacks ? 96 : 250,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    GestorImagenes.listarImagenes();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.scaffoldBackgroundColor : const Color.fromARGB(255, 242, 254, 255),
          border: Border(
            top: BorderSide(
              color: isDark ? const Color.fromARGB(255, 21, 21, 21) : Colors.grey.shade300,
              width: 3,
            ),
          ),
        ),
        height: 50,
        child: Row(
          spacing: 8.0,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 8),
              BotonNavegacion(
              alAccionar: () { _mostrarDialogoAgregarSalidas(context); },
              gradiente: LinearGradient(
                colors: isDark
                    ? [const Color.fromARGB(255, 192, 35, 21), const Color.fromARGB(255, 161, 134, 13)]
                    : [const Color.fromARGB(255, 185, 22, 7), const Color.fromARGB(255, 167, 0, 161)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              icono: Icons.money_off,
              texto: "Agregar salida",
            ),
            BotonNavegacion(
              alAccionar: () {},
              gradiente: LinearGradient(
                colors: isDark
                    ? [Colors.blue.shade800, Colors.blue.shade900]
                    : [const Color.fromARGB(255, 7, 185, 126), const Color.fromARGB(255, 39, 155, 176)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              icono: Icons.receipt,
              texto: "Facturación",
            ),
            BotonNavegacion(
              
              alAccionar: () {},
               gradiente: LinearGradient(
                colors: isDark
                    ? [const Color.fromARGB(255, 141, 21, 192), const Color.fromARGB(255, 9, 94, 105)]
                    : [const Color.fromARGB(255, 205, 33, 243), const Color.fromARGB(255, 39, 155, 176)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              icono: Icons.reply,
              texto: "Reembolsar",
            ),
            
          ],
        ),
      ),
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color.fromARGB(255, 242, 254, 255),
      body: Column(
        children: [
          //Barra superior  
                    Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue.shade800, Colors.blue.shade900]
                    : [Colors.blue, const Color.fromARGB(255, 39, 155, 176)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            height: 50,
            width: double.infinity,

            child: Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'SUPLEMENTOS BEG',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                Expanded(child: SizedBox()),
                Expanded(
                  child: Row(
                    spacing: 10.0,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: widget.onThemeToggle,
                        icon: Icon(
                          widget.currentThemeMode == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: Colors.white,
                        ),
                        tooltip: widget.currentThemeMode == ThemeMode.dark
                            ? 'Cambiar a modo claro'
                            : 'Cambiar a modo oscuro',
                      ),
                      widgetConexiones(),
                      BotonUsuario(),
                      SizedBox(width: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.start,
                          direction: Axis.horizontal,
                          spacing: 2,
                          children: [
                            BotonNavegacion(
                              texto: '📄 Inventario',
                              gradiente:  LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 1, 204, 45),
                                  Color.fromARGB(255, 23, 161, 57),
                                ],
                              ),
                              alAccionar: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InventarioPlutoGrid(),
                                  ),
                                );
                                if (!mounted) return;
                                await _actualizarTablaProductos();
                              },
                            ),

                            BotonNavegacion(
                              texto: '📖 Reporte',
                              gradiente:  LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 255, 158, 32),
                                  Color.fromARGB(255, 245, 140, 3),
                                ],
                              ),

                              alAccionar: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Reporte(
                                      tipo: TipoReporte.ultimoreporte,
                                    ),
                                  ),
                                );
                              },
                            ),

                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Divider(height: 2, color: Colors.blue.shade100),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              height: 60,
                              padding: EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.blue.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade300,
                                      width: 2.0,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade300,
                                      width: 2.0,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                    borderSide: BorderSide(
                                      color: Colors.blue.shade600,
                                      width: 2.5,
                                    ),
                                  ),
                                  labelText:
                                      'Buscar por código, nombre o marca...',
                                  labelStyle: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.blue.shade600,
                                  ),
                                  suffixIcon: _filtroTexto.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: Colors.blue.shade600,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          //    Busquedasucursales(),
                          SizedBox(width: 10),
                        ],
                      ),
                      BotonesBusqueda(),
                      SizedBox(height: 5),
                      Divider(height: 2, color: Colors.blue.shade100),

                      //Lista de productos
                      Expanded(
                        flex: 3,
                        child: RefreshIndicator(
                          key: _refreshKey,
                          onRefresh: _actualizarTablaProductos,
                          child: FutureBuilder<List<Objeto>>(
                            future: _productosFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error cargando objetos: ${snapshot.error}',
                                  ),
                                );
                              } else if (!snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Center(child: Text('No hay productos'));
                              } else {
                                final productosFiltrados = _filtrarProductos(
                                  snapshot.data!,
                                );

                                if (productosFiltrados.isEmpty &&
                                    _filtroTexto.isNotEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No se encontraron productos\ncon "$_filtroTexto"',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final snacks = productosFiltrados
                                    .where(
                                      (producto) =>
                                          producto.categoria?.toLowerCase() ==
                                          'snack',
                                    )
                                    .toList();
                                final demas = productosFiltrados
                                    .where(
                                      (producto) =>
                                          producto.categoria?.toLowerCase() !=
                                          'snack',
                                    )
                                    .toList();

                                return CustomScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    if (snacks.isNotEmpty) ...[
                                      SliverToBoxAdapter(
                                        child: _tituloSeccion(
                                          'Snacks',
                                          const Color.fromARGB(255, 22, 1, 107),
                                        ),
                                      ),
                                      _rejillaProductos(
                                        context,
                                        snacks,
                                        snacks: true,
                                      ),
                                    ],
                                    if (demas.isNotEmpty) ...[
                                      SliverToBoxAdapter(
                                        child: _tituloSeccion(
                                          'Suplementos',
                                          Colors.blue.shade700,
                                        ),
                                      ),
                                      _rejillaProductos(
                                        context,
                                        demas,
                                        snacks: false,
                                      ),
                                    ],
                                    const SliverPadding(
                                      padding: EdgeInsets.only(bottom: 8),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: WidgetCarritoCompra(controller: _carritoController),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _mostrarDialogoAgregarSalidas(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) => agregarSalidas(
      alTenerExito: () {
        _actualizarTablaProductos();
      },
    ),
  );
}
}
