import 'package:pov_suplementos/auth/autenticacion.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/auth/modelo_usuario.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:crypto/crypto.dart';

enum OperacionInventario { agregar, restar, actualizar }

class Basededatos {
  static Database? _database;
  static const String _databaseName = 'pov_suplementos.db';
  static const int _databaseVersion = 8;

  static final List<Map<String, dynamic>> _productosIniciales = [
    {
      'codigo': 'SUP-WHEY-001',
      'productoNombre': 'Proteina Whey 2 kg',
      'marcaNombre': 'Muscletech',
      'descripcion':
          'Proteina de suero para apoyar la recuperacion y el crecimiento muscular.',
      'precio': 1299.0,
      'imagen': 'mtnitrotechwhey.png',
      'existencias': 15,
      'categoria': 'proteina',
    },
    {
      'codigo': 'SUP-CREA-001',
      'productoNombre': 'Creatina Monohidratada 300 g',
      'marcaNombre': 'Universal Nutrition',
      'descripcion':
          'Creatina monohidratada para mejorar el rendimiento y la fuerza.',
      'precio': 499.0,
      'imagen': 'creatina-monohidratada.jpg',
      'existencias': 20,
      'categoria': 'creatina',
    },
    {
      'codigo': 'SUP-PREE-001',
      'productoNombre': 'Pre-entreno 30 servicios',
      'marcaNombre': 'Psychotic',
      'descripcion':
          'Formula pre-entreno para energia, enfoque y rendimiento durante la sesion.',
      'precio': 649.0,
      'imagen': 'inspsychoticrojo.png',
      'existencias': 12,
      'categoria': 'pre-entreno',
    },
    {
      'codigo': 'SUP-GANA-001',
      'productoNombre': 'Mass Gainer 3 kg',
      'marcaNombre': 'Mutant',
      'descripcion':
          'Suplemento hipercalorico para apoyar el aumento de masa muscular.',
      'precio': 899.0,
      'imagen': 'mass-gainer.jpg',
      'existencias': 10,
      'categoria': 'ganador de peso',
    },
    {
      'codigo': 'SUP-BCAA-001',
      'productoNombre': 'BCAA 2:1:1 300 g',
      'marcaNombre': 'Scivation',
      'descripcion':
          'Aminoacidos esenciales para complementar la recuperacion post-entrenamiento.',
      'precio': 579.0,
      'imagen': 'bcaa.jpg',
      'existencias': 14,
      'categoria': 'aminoacidos',
    },
    {
      'codigo': 'SUP-OMEGA-001',
      'productoNombre': 'Omega 3 100 capsulas',
      'marcaNombre': 'NOW Foods',
      'descripcion':
          'Capsulas de aceite de pescado como complemento para una dieta equilibrada.',
      'precio': 329.0,
      'imagen': 'omega-3.jpg',
      'existencias': 25,
      'categoria': 'salud y bienestar',
    },
  ];

  static Future<void> cerrarBaseDatos() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    print('Base de datos cerrada');
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _inicializarBD();
    return _database!;
  }

  static Future<Database> _inicializarBD() async {
    sqfliteFfiInit();
    var directoriobd = await databaseFactoryFfi.getDatabasesPath();
    String directorio = path.join(directoriobd, _databaseName);

    return await databaseFactoryFfi.openDatabase(
      directorio,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _crearTodasLasTablas,
        onUpgrade: _migrarBaseDatos,
      ),
    );
  }

  /// Maneja las migraciones de base de datos entre versiones
  static Future<void> _migrarBaseDatos(
    Database bd,
    int versionAntigua,
    int versionNueva,
  ) async {
    print("Migrando base de datos de versión $versionAntigua a $versionNueva");

    // Migración de versión 4 a 5: agregar columna 'activo' a productos
    if (versionAntigua < 5) {
      await bd.execute('''
        ALTER TABLE productos ADD COLUMN activo INTEGER NOT NULL DEFAULT 1
      ''');
      print("Columna 'activo' agregada a tabla productos");
    }

    // Migración de versión 5 a 6: agregar columna 'sucursal' a productos
    if (versionAntigua < 6) {
      await bd.execute('''
        ALTER TABLE productos ADD COLUMN sucursal INTEGER NOT NULL DEFAULT 1
      ''');
      print("Columna 'sucursal' agregada a tabla productos");
    }

    if (versionAntigua < 7) {
      await bd.delete('reportes_inventario');
      await bd.delete('venta_objetos');
      await bd.delete('productos');
      await _insertarProductosIniciales(bd);
      print('Catalogo de suplementos actualizado');
    }

    if (versionAntigua < 8) {
      final imagenesPorCodigo = {
        'SUP-CREA-001': 'creatina-monohidratada.jpg',
        'SUP-GANA-001': 'mass-gainer.jpg',
        'SUP-BCAA-001': 'bcaa.jpg',
        'SUP-OMEGA-001': 'omega-3.jpg',
      };
      for (final entrada in imagenesPorCodigo.entries) {
        await bd.update(
          'productos',
          {'imagen': entrada.value},
          where: 'codigo = ?',
          whereArgs: [entrada.key],
        );
      }
      print('Imagenes del catalogo de suplementos actualizadas');
    }
  }

  /// Crea todas las tablas necesarias en la base de datos
  static Future<void> _crearTodasLasTablas(Database bd, int version) async {
    print("creando tablas...");
    await bd.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        rol INTEGER NOT NULL,
        ultimo_acceso TEXT,
        activo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabla productos
    await bd.execute('''
      CREATE TABLE productos (
        codigo TEXT PRIMARY KEY,
        productoNombre TEXT NOT NULL,
        marcaNombre TEXT NOT NULL,
        descripcion TEXT,
        precio REAL NOT NULL,
        imagen TEXT,  
        existencias INTEGER NOT NULL,
        categoria TEXT NOT NULL DEFAULT 'snack',
        activo INTEGER NOT NULL DEFAULT 1,
        sucursal INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Tabla ventas
    await bd.execute('''
      CREATE TABLE ventas (
        codigo INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        subtotal REAL,
        impuesto REAL DEFAULT 0,
        descuento REAL DEFAULT 0,
        usuario_id INTEGER NOT NULL,
        metodo_pago TEXT DEFAULT 'efectivo',
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT
      )
    ''');

    // Tabla venta_objetos
    await bd.execute('''
      CREATE TABLE venta_objetos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ventaCodigo INTEGER NOT NULL,
        productoCodigo TEXT NOT NULL,
        cantidad INTEGER NOT NULL,
        precio REAL NOT NULL,
        FOREIGN KEY (ventaCodigo) REFERENCES ventas(codigo) ON DELETE CASCADE,
        FOREIGN KEY (productoCodigo) REFERENCES productos(codigo) ON DELETE RESTRICT
      )
    ''');

    await bd.execute('''
      CREATE TABLE reportes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_reporte TEXT NOT NULL DEFAULT 'inventario',
        creado_por INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        fecha_creacion TEXT NOT NULL,
        fecha_desde TEXT,
        fecha_hasta TEXT,
        estado TEXT NOT NULL DEFAULT 'generado',
        FOREIGN KEY (creado_por) REFERENCES usuarios(id) ON DELETE RESTRICT
      )
    ''');

    await bd.execute('''
      CREATE TABLE reportes_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reporte_id INTEGER NOT NULL,
        producto_id TEXT NOT NULL,
        cantidad_anterior INTEGER NOT NULL,
        cantidad_indicada INTEGER NOT NULL,
        cantidad_real INTEGER NOT NULL,
        motivo TEXT,
        fecha_registro TEXT NOT NULL,
        FOREIGN KEY (reporte_id) REFERENCES reportes(id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos(codigo) ON DELETE RESTRICT
      )
    ''');

    await _crearUsuarioAdmin(bd);
    await _insertarProductosIniciales(bd);
  }

  static Future<void> _insertarProductosIniciales(Database bd) async {
    for (final producto in _productosIniciales) {
      await bd.insert('productos', producto);
    }
  }

  static Future<Map<String, dynamic>> obtenerUltimoReporte() async {
    final db = await database;

    try {
      final resultado = await db.query(
        'reportes',
        orderBy: 'fecha_creacion DESC',
        limit: 1,
      );

      if (resultado.isEmpty) {
        return {
          'encontrado': false,
          'mensaje': 'No se encontró ningún reporte',
        };
      }

      return {
        'encontrado': true,
        'reporte': resultado.first,
        'productos': await db.query(
          'reportes_inventario',
          where: 'reporte_id = ?',
          whereArgs: [resultado.first['id']],
        ),
        'mensaje': 'Último reporte obtenido exitosamente',
      };
    } catch (e) {
      return {
        'encontrado': false,
        'mensaje': 'Error al obtener último reporte: $e',
      };
    }
  }

  static Future<void> _crearUsuarioAdmin(Database bd) async {
    const adminPassword = 'admin123';
    final hashedPassword = _hashPassword(adminPassword);

    try {
      await bd.insert('usuarios', {
        'nombre': 'admin',
        'contrasena': hashedPassword,
        'rol': RolUsuario.admin.id,
        'activo': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      print('Error creando usuario admin: $e');
    }
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }

  static Future<Map<String, dynamic>> crearUsuario(Usuario usuario) async {
    final db = await database;

    try {
      final existingUser = await buscarUsuarioPorNombre(usuario.nombre);
      if (existingUser['encontrado'] == true) {
        return {'exito': false, 'mensaje': 'El nombre de usuario ya existe'};
      }

      final usuarioConHasheada = usuario.copiarUsuario(
        contrasena: _hashPassword(usuario.contrasena),
      );

      final id = await db.insert(
        'usuarios',
        usuarioConHasheada.aMapa(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return {
        'exito': true,
        'mensaje': 'Usuario creado exitosamente',
        'usuarioId': id,
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al crear usuario: $e'};
    }
  }

  static Future<Map<String, dynamic>> buscarUsuarioPorNombre(
    String nombre,
  ) async {
    final db = await database;

    try {
      final resultado = await db.query(
        'usuarios',
        where: 'nombre = ? AND activo = 1',
        whereArgs: [nombre],
        limit: 1,
      );

      if (resultado.isEmpty) {
        return {'encontrado': false, 'mensaje': 'Usuario no encontrado'};
      }

      final usuario = Usuario.fromMap(resultado.first);
      return {
        'encontrado': true,
        'usuario': usuario,
        'mensaje': 'Usuario encontrado',
      };
    } catch (e) {
      return {'encontrado': false, 'mensaje': 'Error al buscar usuario: $e'};
    }
  }

  static Future<Map<String, dynamic>> validarCredenciales(
    String nombre,
    String contrasena,
  ) async {
    final db = await database;

    try {
      final resultado = await db.query(
        'usuarios',
        where: 'nombre = ? AND activo = 1',
        whereArgs: [nombre],
        limit: 1,
      );

      if (resultado.isEmpty) {
        return {'valido': false, 'mensaje': 'Usuario no encontrado'};
      }

      final userData = resultado.first;
      final hashedPassword = userData['contrasena'] as String;

      if (!_verifyPassword(contrasena, hashedPassword)) {
        return {'valido': false, 'mensaje': 'Contraseña incorrecta'};
      }

      await _actualizarUltimoAcceso(userData['id'] as int);

      final usuario = Usuario.fromMap(userData);
      return {
        'valido': true,
        'usuario': usuario,
        'mensaje': 'Credenciales válidas',
      };
    } catch (e) {
      return {'valido': false, 'mensaje': 'Error al validar credenciales: $e'};
    }
  }

  static Future<void> _actualizarUltimoAcceso(int userId) async {
    final db = await database;
    await db.update(
      'usuarios',
      {'ultimo_acceso': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Obtiene todos los usuarios (solo para administradores)
  static Future<Map<String, dynamic>> obtenerTodosLosUsuarios() async {
    final db = await database;

    try {
      final resultado = await db.query('usuarios', orderBy: 'nombre ASC');

      final usuarios = resultado
          .map((userData) => Usuario.fromMap(userData))
          .toList();

      return {
        'exito': true,
        'usuarios': usuarios,
        'mensaje': 'Usuarios obtenidos exitosamente',
      };
    } catch (e) {
      return {
        'exito': false,
        'usuarios': <Usuario>[],
        'mensaje': 'Error al obtener usuarios: $e',
      };
    }
  }

  /// Desactiva un usuario (no lo elimina, solo lo marca como inactivo)
  static Future<Map<String, dynamic>> desactivarUsuario(int usuarioId) async {
    final db = await database;

    try {
      final rowsAffected = await db.update(
        'usuarios',
        {'activo': 0},
        where: 'id = ?',
        whereArgs: [usuarioId],
      );

      if (rowsAffected == 0) {
        return {'exito': false, 'mensaje': 'Usuario no encontrado'};
      }

      return {'exito': true, 'mensaje': 'Usuario desactivado exitosamente'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al desactivar usuario: $e'};
    }
  }

  /// Cambia la contraseña de un usuario
  static Future<Map<String, dynamic>> cambiarContrasena(
    int userId,
    String nuevaContrasena,
  ) async {
    final db = await database;

    try {
      final hashedPassword = _hashPassword(nuevaContrasena);

      final rowsAffected = await db.update(
        'usuarios',
        {'contrasena': hashedPassword},
        where: 'id = ? AND activo = 1',
        whereArgs: [userId],
      );

      if (rowsAffected == 0) {
        return {'exito': false, 'mensaje': 'Usuario no encontrado o inactivo'};
      }

      return {'exito': true, 'mensaje': 'Contraseña actualizada exitosamente'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al cambiar contraseña: $e'};
    }
  }

  /// Guarda una venta
  static Future<Map<String, dynamic>> guardarVenta(
    Map<String, dynamic> venta,
    List<Map<String, dynamic>> objetos,
  ) async {
    if (objetos.isEmpty) {
      return {
        'exito': false,
        'mensaje': 'No se pueden guardar ventas sin productos',
      };
    }

    final db = await database;

    try {
      return await db.transaction((txn) async {
        for (final objeto in objetos) {
          final producto = await txn.query(
            'productos',
            where: 'codigo = ?',
            whereArgs: [objeto['productoCodigo']],
            limit: 1,
          );

          if (producto.isEmpty) {
            throw Exception(
              'Producto ${objeto['productoCodigo']} no encontrado',
            );
          }

          final disponible = producto.first['existencias'] as int;
          final solicitado = objeto['cantidad'] as int;

          if (disponible < solicitado) {
            throw Exception(
              'Inventario insuficiente para producto ${objeto['productoCodigo']}. '
              'Disponible: $disponible, Solicitado: $solicitado',
            );
          }
        }

        // 2. Insertar venta
        final ventaId = await txn.insert('ventas', {
          'fecha': venta['fecha'] ?? DateTime.now().toIso8601String(),
          'total': venta['total'] ?? 0.0,
          'subtotal': venta['subtotal'] ?? venta['total'] ?? 0.0,
          'impuesto': venta['impuesto'] ?? 0.0,
          'descuento': venta['descuento'] ?? 0.0,
          'usuario_id': venta['usuario_id'],
          'metodo_pago': venta['metodo_pago'] ?? 'efectivo',
        });

        for (final objeto in objetos) {
          await txn.insert('venta_objetos', {
            'ventaCodigo': ventaId,
            'productoCodigo': objeto['productoCodigo'],
            'cantidad': objeto['cantidad'],
            'precio': objeto['precio'],
          });

          await txn.rawUpdate(
            'UPDATE productos SET existencias = existencias - ? WHERE codigo = ?',
            [objeto['cantidad'], objeto['productoCodigo']],
          );
        }

        return {
          'exito': true,
          'mensaje': 'Venta guardada exitosamente con inventario actualizado',
          'ventaId': ventaId,
        };
      });
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al guardar venta: $e'};
    }
  }

  static Future<Map<String, dynamic>> obtenerVentas() async {
    final db = await database;
    try {
      final ventas = await db.query('ventas');
      final List<Map<String, dynamic>> resultado = [];

      for (final venta in ventas) {
        final items = await db.query(
          'venta_objetos',
          where: 'ventaCodigo = ?',
          whereArgs: [venta['codigo']],
        );
        final v = Map<String, dynamic>.from(venta);
        v['items'] = items;
        resultado.add(v);
      }

      return {
        'exito': true,
        'mensaje': 'Ventas obtenidas',
        'ventas': resultado,
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error obteniendo ventas: $e',
        'ventas': [],
      };
    }
  }

  static Future<Map<String, dynamic>> guardarProductos(
    List<Map<String, dynamic>> productos,
  ) async {
    if (productos.isEmpty) {
      return {
        'exito': false,
        'mensaje': 'Lista de productos vacia',
        'elementos guardados': 0,
      };
    }

    final db = await database;

    List<String> err = [];
    try {
      await db.transaction((trans) async {
        for (int i = 0; i < productos.length; i++) {
          Map<String, dynamic> producto = productos[i];
          if (!_validarProducto(producto)) {
            err.add(
              'Producto ${i + 1} no se pudo añadir. No tiene los campos validos',
            );
            continue;
          }

          await trans.insert(
            'productos',
            producto,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      err.add("DB: Error al guardar productos - $e");
    }
    return {
      'exito': err.isEmpty,
      'mensaje': err.isEmpty
          ? 'Productos guardados exitosamente'
          : 'Algunos productos no se pudieron guardar',
      'elementos guardados': productos.length - err.length,
      'errores': err,
    };
  }

  static Future<Map<String, dynamic>> actualizarInventario(
    OperacionInventario operacion,
    List<Map<String, dynamic>> productos,
  ) async {
    if (productos.isEmpty) {
      return {'exito': false, 'mensaje': 'Lista de productos vacía'};
    }

    try {
      final bd = await database;

      return await bd.transaction((trans) async {
        for (final producto in productos) {
          final codigo = producto['productoCodigo'];
          final cantidad = producto['cantidad'] ?? 0;

          if (codigo == null) {
            throw Exception('Código de producto requerido');
          }

          final productoActual = await trans.query(
            'productos',
            where: 'codigo = ?',
            whereArgs: [codigo],
            limit: 1,
          );

          if (productoActual.isEmpty) {
            throw Exception('Producto con código $codigo no encontrado');
          }

          final existenciasActuales =
              productoActual.first['existencias'] as int;
          int cantidadNueva;

          switch (operacion) {
            case OperacionInventario.agregar:
              cantidadNueva = existenciasActuales + cantidad as int;
              break;
            case OperacionInventario.restar:
              cantidadNueva = existenciasActuales - cantidad as int;
              if (cantidadNueva < 0) {
                throw Exception(
                  'Inventario insuficiente para producto $codigo. '
                  'Disponible: $existenciasActuales, Solicitado: $cantidad',
                );
              }
              break;
            case OperacionInventario.actualizar:
              cantidadNueva = cantidad;
              if (cantidadNueva < 0) {
                throw Exception('La cantidad no puede ser negativa');
              }
              break;
          }

          await trans.update(
            'productos',
            {'existencias': cantidadNueva},
            where: 'codigo = ?',
            whereArgs: [codigo],
          );
        }

        return {
          'exito': true,
          'mensaje': 'Inventario actualizado exitosamente',
          'productos_actualizados': productos.length,
        };
      });
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al actualizar inventario: $e'};
    }
  }

  static Future<Map<String, dynamic>> obtenerObjetos() async {
    final db = await database;
    return db
        .query('productos', where: 'activo = 1')
        .then((lista) {
          return {
            'exito': true,
            'mensaje': 'Productos obtenidos exitosamente',
            'productos': lista,
          };
        })
        .catchError((e) {
          return {
            'exito': false,
            'mensaje': 'Error al obtener productos: $e',
            'productos': [],
          };
        });
  }

  static Future<Map<String, dynamic>> obtenerObjetoPorCodigo(
    String codigo,
  ) async {
    final db = await database;
    try {
      final resultado = await db.query(
        'productos',
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (resultado.isEmpty) {
        return {'encontrado': false, 'mensaje': 'Producto no encontrado'};
      }

      return {
        'encontrado': true,
        'producto': resultado.first,
        'mensaje': 'Producto encontrado',
      };
    } catch (e) {
      return {'encontrado': false, 'mensaje': 'Error al buscar producto: $e'};
    }
  }

  /// Crea un nuevo reporte de inventario
  static Future<Map<String, dynamic>> crearReporteInventario({
    required int creadoPor,
    required String titulo,
    String? descripcion,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    final db = await database;

    try {
      final reporteId = await db.insert('reportes', {
        'tipo_reporte': 'inventario',
        'creado_por': creadoPor,
        'titulo': titulo,
        'descripcion': descripcion,
        'fecha_creacion': DateTime.now().toIso8601String(),
        'fecha_desde': fechaDesde?.toIso8601String(),
        'fecha_hasta': fechaHasta?.toIso8601String(),
        'estado': 'generado',
      });

      return {
        'exito': true,
        'reporteId': reporteId,
        'mensaje': 'Reporte de inventario creado exitosamente',
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al crear reporte: $e'};
    }
  }

  static Future<Map<String, dynamic>> agregarDetalleReporte({
    required int reporteId,
    required String productoId,
    required int cantidadAnterior,
    required int cantidadActual,
    String? motivo,
  }) async {
    final db = await database;

    try {
      final diferencia = cantidadActual - cantidadAnterior;

      await db.insert('reportes_inventario', {
        'reporte_id': reporteId,
        'producto_id': productoId,
        'cantidad_anterior': cantidadAnterior,
        'cantidad_actual': cantidadActual,
        'diferencia': diferencia,
        'motivo': motivo,
        'fecha_registro': DateTime.now().toIso8601String(),
      });

      return {'exito': true, 'mensaje': 'Detalle agregado al reporte'};
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al agregar detalle: $e'};
    }
  }

  /// Genera un reporte completo de inventario actual
  static Future<Map<String, dynamic>> generarReporteInventarioCompleto({
    required int creadoPor,
    String titulo = 'Reporte de Inventario',
  }) async {
    final db = await database;

    try {
      return await db.transaction((txn) async {
        final reporteId = await txn.insert('reportes', {
          'tipo_reporte': 'inventario',
          'creado_por': creadoPor,
          'titulo': titulo,
          'descripcion': 'Reporte automático de todo el inventario',
          'fecha_creacion': DateTime.now().toIso8601String(),
          'estado': 'generado',
        });

        final productos = await txn.query('productos');

        for (final producto in productos) {
          final cantidadActual = producto['existencias'] as int;

          await txn.insert('reportes_inventario', {
            'reporte_id': reporteId,
            'producto_id': producto['codigo'],
            'cantidad_anterior': cantidadActual,
            'cantidad_actual': cantidadActual,
            'diferencia': 0,
            'motivo': 'Inventario actual',
            'fecha_registro': DateTime.now().toIso8601String(),
          });
        }

        return {
          'exito': true,
          'reporteId': reporteId,
          'productosIncluidos': productos.length,
          'mensaje': 'Reporte de inventario completo generado exitosamente',
        };
      });
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al generar reporte: $e'};
    }
  }

  ///Obtener objetos por sucursal
  static Future<Map<String, dynamic>> obtenerObjetosPorSucursal(
    int sucursal,
  ) async {
    final bd = await database;

    try {
      final objetos = await bd.rawQuery(
        '''
      Select * from productos where sucursal = ?
      ''',
        [sucursal],
      );
      return {'productos': objetos};
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'No se pudieron obtener los objetos por sucursal: $e',
      };
    }
  }

  /// Obtiene un reporte con todos sus detalles
  static Future<Map<String, dynamic>> obtenerReporteCompleto(
    int reporteId,
  ) async {
    final db = await database;

    try {
      final reporteInfo = await db.rawQuery(
        '''
        SELECT r.*, u.nombre as creador_nombre
        FROM reportes r
        JOIN usuarios u ON r.creado_por = u.id
        WHERE r.id = ?
      ''',
        [reporteId],
      );

      if (reporteInfo.isEmpty) {
        return {'exito': false, 'mensaje': 'Reporte no encontrado'};
      }

      final detalles = await db.rawQuery(
        '''
        SELECT 
          ri.*,
          p.productoNombre,
          p.marcaNombre,
          p.categoria,
          p.precio
        FROM reportes_inventario ri
        JOIN productos p ON ri.producto_id = p.codigo
        WHERE ri.reporte_id = ?
        ORDER BY ri.fecha_registro ASC
      ''',
        [reporteId],
      );

      return {
        'exito': true,
        'reporte': reporteInfo.first,
        'detalles': detalles,
        'mensaje': 'Reporte obtenido exitosamente',
      };
    } catch (e) {
      return {'exito': false, 'mensaje': 'Error al obtener reporte: $e'};
    }
  }

  /// Listado de reportes
  static Future<Map<String, dynamic>> listarReportes({int? creadoPor}) async {
    final db = await database;

    try {
      String whereClause = '1=1';
      List<dynamic> whereArgs = [];

      if (creadoPor != null) {
        whereClause += ' AND r.creado_por = ?';
        whereArgs.add(creadoPor);
      }

      final reportes = await db.rawQuery('''
        SELECT 
          r.*,
          u.nombre as creador_nombre,
          COUNT(ri.id) as total_productos
        FROM reportes r
        JOIN usuarios u ON r.creado_por = u.id
        LEFT JOIN reportes_inventario ri ON r.id = ri.reporte_id
        WHERE $whereClause
        GROUP BY r.id
        ORDER BY r.fecha_creacion DESC
      ''', whereArgs);

      return {
        'exito': true,
        'reportes': reportes,
        'mensaje': 'Reportes obtenidos exitosamente',
      };
    } catch (e) {
      return {
        'exito': false,
        'reportes': [],
        'mensaje': 'Error al obtener reportes: $e',
      };
    }
  }

  static bool _validarProducto(Map<String, dynamic> producto) {
    return producto.containsKey('codigo') &&
        producto.containsKey('productoNombre') &&
        producto.containsKey('marcaNombre') &&
        producto.containsKey('precio') &&
        producto['codigo'] is String &&
        producto['precio'] is num &&
        producto['categoria'].toString().isNotEmpty &&
        producto['productoNombre'].toString().isNotEmpty;
  }

  //Guarda una lista de objetos a partir de una lista de objetos Objeto
  static Future<void> guardarProductosDeObjetos(List<Objeto> objetos) async {
    final productos = objetos
        .map(
          (obj) => {
            'codigo': obj.codigo,
            'productoNombre': obj.productoNombre,
            'marcaNombre': obj.marcaNombre,
            'descripcion': obj.descripcion,
            'precio': obj.precio,
            'imagen': obj.imagen,
            'categoria': obj.categoria,
            'existencias': obj.existencias,
          },
        )
        .toList();

    final resultado = await guardarProductos(productos);
    print(resultado);
  }

  /// Desactiva productos (soft delete) en lugar de eliminarlos
  static Future<Map<String, dynamic>> desactivarProductos(
    List<String> codigos,
  ) async {
    final db = await database;
    try {
      int productosAfectados = 0;
      await db.transaction((txn) async {
        for (final codigo in codigos) {
          final rowsAffected = await txn.update(
            'productos',
            {'activo': 0},
            where: 'codigo = ?',
            whereArgs: [codigo],
          );
          productosAfectados += rowsAffected;
        }
      });

      return {
        'exito': true,
        'mensaje': 'Productos desactivados exitosamente',
        'productos_desactivados': productosAfectados,
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al desactivar productos: $e',
        'productos_desactivados': 0,
      };
    }
  }

  /// Reactiva productos previamente desactivados
  static Future<Map<String, dynamic>> reactivarProductos(
    List<String> codigos,
  ) async {
    final db = await database;
    try {
      int productosAfectados = 0;
      await db.transaction((txn) async {
        for (final codigo in codigos) {
          final rowsAffected = await txn.update(
            'productos',
            {'activo': 1},
            where: 'codigo = ?',
            whereArgs: [codigo],
          );
          productosAfectados += rowsAffected;
        }
      });

      return {
        'exito': true,
        'mensaje': 'Productos reactivados exitosamente',
        'productos_reactivados': productosAfectados,
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al reactivar productos: $e',
        'productos_reactivados': 0,
      };
    }
  }

  /// Reactiva productos previamente desactivados
  static Future<Map<String, dynamic>> actualizarExistencias(
    int codigo,
    int cantidad,
    OperacionInventario operacion,
  ) async {
    final bd = await database;
    try {
      if (operacion == OperacionInventario.restar) {
        cantidad = -cantidad;
      }
      await bd.transaction((tns) async {
        await tns.rawUpdate(
          '''
        UPDATE productos
        SET existencias = 
        ${operacion == OperacionInventario.actualizar ? '?' : 'existencias + ?'}
          WHERE codigo = ?
          ''',
          [cantidad, codigo],
        );
      });
      return {
        'exito': true,
        'mensaje': 'Existencias agregadas exitosamente',
        'cantidad_agregada': cantidad,
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al agregar existencias: $e',
        'cantidad_agregada': 0,
      };
    }
  }

  /// MANTENER para casos excepcionales donde realmente necesites eliminar
  static Future<void> eliminarProductos(List<String> codigos) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        for (final codigo in codigos) {
          await txn.delete(
            'productos',
            where: 'codigo = ?',
            whereArgs: [codigo],
          );
        }
      });
      print('Productos eliminados exitosamente');
    } catch (e) {
      print('Error al eliminar productos: $e');
    }
  }

  static Future<Map<String, dynamic>> actualizarProducto(
    String codigo,
    Map<String, Object?> datos,
  ) async {
    if (codigo.trim().isEmpty) {
      return {
        'exito': false,
        'mensaje': 'El código del producto es requerido',
      };
    }

    if (datos.isEmpty) {
      return {
        'exito': false,
        'mensaje': 'No se enviaron datos para actualizar',
      };
    }

    final db = await database;

    try {
      final productoActual = await db.query(
        'productos',
        where: 'codigo = ?',
        whereArgs: [codigo],
        limit: 1,
      );

      if (productoActual.isEmpty) {
        return {
          'exito': false,
          'mensaje': 'Producto no encontrado',
        };
      }

      final cambios = <String, Object?>{};
      final validadores = <String, dynamic Function(Object?)>{
        'productoNombre': (valor) => valor is String && valor.trim().isNotEmpty,
        'marcaNombre': (valor) => valor is String && valor.trim().isNotEmpty,
        'descripcion': (valor) => valor == null || valor is String,
        'precio': (valor) => valor is num && valor >= 0,
        'imagen': (valor) => valor == null || valor is String,
        'existencias': (valor) => valor is int && valor >= 0,
        'categoria': (valor) => valor is String && valor.trim().isNotEmpty,
        'activo': (valor) => valor is int && (valor == 0 || valor == 1),
        'sucursal': (valor) => valor is int && valor >= 0,
      };

      for (final entrada in datos.entries) {
        final clave = entrada.key;
        final valor = entrada.value;

        if (clave == 'codigo') {
          return {
            'exito': false,
            'mensaje': 'No se permite cambiar el código del producto',
          };
        }

        if (!validadores.containsKey(clave)) {
          continue;
        }

        if (!validadores[clave]!(valor)) {
          return {
            'exito': false,
            'mensaje': 'El campo "$clave" tiene un valor inválido',
          };
        }

        cambios[clave] = valor;
      }

      if (cambios.isEmpty) {
        return {
          'exito': false,
          'mensaje': 'No se encontraron campos válidos para actualizar',
        };
      }

      final filasAfectadas = await db.update(
        'productos',
        cambios,
        where: 'codigo = ?',
        whereArgs: [codigo],
      );

      if (filasAfectadas == 0) {
        return {
          'exito': false,
          'mensaje': 'No se pudo actualizar el producto',
        };
      }

      return {
        'exito': true,
        'mensaje': 'Producto actualizado correctamente',
        'filas_afectadas': filasAfectadas,
      };
    } catch (e) {
      return {
        'exito': false,
        'mensaje': 'Error al actualizar producto: $e',
      };
    }
  }
}
