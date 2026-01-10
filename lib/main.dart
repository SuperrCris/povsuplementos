import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/funciones/descargarimagenes.dart';
import 'package:pov_suplementos/funciones/obtenerimagenes.dart';
import 'package:pov_suplementos/widgets/agregarobjeto.dart';
import 'package:pov_suplementos/widgets/botonesbusqueda.dart';
import 'package:pov_suplementos/widgets/botonusuario.dart';
import 'package:pov_suplementos/widgets/busquedasucursales.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';
import 'package:pov_suplementos/widgets/conexiones.dart';
import 'package:pov_suplementos/widgets/ventanacompra.dart';
import 'package:pov_suplementos/widgets/ventanareportes.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Importaciones del sistema de autenticación
import 'package:pov_suplementos/auth/gestorsesion.dart';
import 'package:pov_suplementos/auth/iniciopagina.dart';
import 'package:pov_suplementos/auth/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  await Basededatos.database;  
  await DatabaseSeeder.createSampleUsers();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final Map<String, dynamic> config = {"tema": ThemeMode.light, "sucursal": 3};

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
      supportedLocales: [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],

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
        alExpirarSesion: () {
        },
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
  Database? db;

  final CarritoControlador _carritoController = CarritoControlador();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  late Future<List<Objeto>> _productosFuture;

  Future<Image> loadImage() async {
    await Future.delayed(const Duration(seconds: 2));
    return Image.network('https://via.placeholder.com/150');
  }

  @override
  void initState() {
    super.initState();
    _productosFuture = obtenerInfo();
    _carritoController.setRefreshCallback(_actualizarTablaProductos);
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
    for (var _producto in productos['productos']) {
      print(_producto);
      Objeto objetoactual = Objeto(
        codigo: _producto['codigo'],
        productoNombre: _producto['productoNombre'],
        marcaNombre: _producto['marcaNombre'],
        descripcion: _producto['descripcion'] ?? '',
        precio: (_producto['precio']?.toDouble()) ?? 0.0,
        imagen: _producto['imagen']?? '',
        categoria: _producto['categoria'],
        existencias: _producto['existencias'],
      );
      for (var imageFile in images) {
        if (_producto['imagen'] != null && imageFile.path.contains(_producto['imagen'])) {
          objetoactual.imagenWidget = Image.file(imageFile, fit: BoxFit.cover);
          break;
        } else {
          print(
            "no hubo imagen para el objeto: ${_producto['productoNombre']}",
          );
        }
      }
      print(
        "Objeto agregado: ${objetoactual.productoNombre} con codigo ${objetoactual.codigo}",
      );
      objetos.add(objetoactual);
    }

    await Future.delayed(Duration(seconds: 1));
    return objetos;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color.fromARGB(255, 242, 254, 255),
      body: Column(
        children: [
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
            child: Expanded(
              flex: 2,
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
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Información del usuario actual

                        // Tiempo restante de sesión
                        //SessionTimeoutWidget(),
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
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Flexible(
                          child: Row(
                            spacing: 10,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Reporte(tipo: TipoReporte.ultimoreporte,),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(45),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 23, 161, 57),
                                        Color.fromARGB(255, 1, 204, 45),
                                      ],
                                      stops: [0, 1],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Text(
                                    '👍 Reporte inicial',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(45),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 255, 158, 32),
                                        Color.fromARGB(255, 245, 140, 3),
                                      ],
                                      stops: [0, 1],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Text(
                                    '⌛ Reporte final',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              ElevatedButton(onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Agregarobjeto(alTenerExito: () {
                                    _actualizarTablaProductos();
                                  },),
                                );
                              }, child: Text('+'))
                            ],
                          ),
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
                                  labelText: 'Buscar productos...',
                                  labelStyle: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.blue.shade600,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                                onChanged: (value) {
                            
                                },
                              ),
                            ),
                          ),
                          Busquedasucursales(),
                          SizedBox(width: 10),
                        ],
                      ),
                      BotonesBusqueda(),
                      SizedBox(height: 5),
                      Divider(height: 2, color: Colors.blue.shade100),
                      Expanded(
                        flex: 2,
                        child: RefreshIndicator(
                          key: _refreshKey,
                          onRefresh: _actualizarTablaProductos,
                          child: FutureBuilder<List<Objeto>>(
                            future: _productosFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
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
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount:
                                              MediaQuery.of(context).size.width >
                                                  300
                                              ? MediaQuery.of(
                                                      context,
                                                    ).size.width ~/
                                                    300
                                              : 1,
                                          crossAxisSpacing: 8.0,
                                          mainAxisSpacing: 8.0,
                                          childAspectRatio: 0.6,
                                        ),
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final objeto = snapshot.data![index];
                                      return widgetVenta(
                                        objeto: objeto,
                                        callback: () => _agregarAlCarrito(objeto),
                                      );
                                    },
                                  ),
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
}
