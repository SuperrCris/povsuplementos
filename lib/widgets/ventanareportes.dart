import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as selectorDeFecha;
import 'package:pov_suplementos/funciones/basededatos.dart';

enum TipoReporte { inventario, ultimoreporte, compras }

class Reporte extends StatefulWidget {
  TipoReporte tipo = TipoReporte.ultimoreporte;
  Reporte({super.key, this.tipo = TipoReporte.ultimoreporte});

  @override
  ReporteState createState() => ReporteState();
}

class ReporteState extends State<Reporte> {
  DateTime fechaInicio = DateTime.now();
  DateTime fechaFin = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reporte')),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Fecha de inicio",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    selectorDeFecha.TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(10),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today),
                          Text(
                            "${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}",
                          ),
                        ],
                      ),

                      onPressed: () async {
                        final DateTime? picked =
                            await selectorDeFecha.showDatePicker(
                              helpText: "Fecha de inicio",
                              locale: const Locale('es', 'ES'),
                              context: context,
                              initialDate: fechaInicio,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2101),
                            );
                        if (picked != null && picked != fechaInicio) {
                          setState(() {
                            fechaInicio = picked;
                          });
                        }
                      },
                    ),

                    Text(
                      "Fecha de fin",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    selectorDeFecha.TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(10),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today),
                          Text(
                            "${fechaFin.day}/${fechaFin.month}/${fechaFin.year}",
                          ),
                        ],
                      ),

                      onPressed: () async {
                        final DateTime? fechaSeleccionada =
                            await selectorDeFecha.showDatePicker(
                              helpText: "Fecha de fin",
                              locale: const Locale('es', 'ES'),
                              context: context,
                              initialDate: fechaFin,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2101),
                            );
                        if (fechaSeleccionada != null &&
                            fechaSeleccionada != fechaFin) {
                          setState(() {
                            fechaFin = fechaSeleccionada;
                          });
                        }
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Creado por mi:"),
                        Checkbox(value: true, onChanged: (value) {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 4,
              child: Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(8.0),
                child: FutureBuilder(
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      switch (widget.tipo) {
                        case TipoReporte.inventario:
                          final inventarioData =
                              snapshot.data as Map<String, dynamic>;
                          final productos =
                              (inventarioData['productos'] as List<dynamic>?)
                                  ?.cast<Map<String, dynamic>>() ??
                              <Map<String, dynamic>>[];

                          if (inventarioData['exito'] == false) {
                            return Text('Error: ${inventarioData['mensaje']}');
                          }

                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                Text('Reporte de Inventario'),
                                SizedBox(height: 20),
                                if (productos.isEmpty)
                                  Text('No hay productos en el inventario')
                                else
                                  ...productos.map(
                                    (producto) => Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4.0,
                                      ),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          side: BorderSide(
                                            color: const Color.fromARGB(
                                              255,
                                              119,
                                              119,
                                              119,
                                            ),
                                          ),
                                        ),

                                        subtitle: Text('${producto['codigo']}'),
                                        title: Text(
                                          '${producto['productoNombre']}',
                                        ),
                                        trailing: Text(
                                          'Existencias: ${producto['existencias']}',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );

                        case TipoReporte.ultimoreporte:
                          final reporteData =
                              snapshot.data as Map<String, dynamic>;
                          final reporte = reporteData['reporte'];
                          final productos =
                              reporteData['productos'] ??
                              <Map<String, dynamic>>[];

                          return reporte != null
                              ? Column(
                                  children: [
                                    Text('Reporte ID: ${reporte['id']}'),
                                    Text('Título: ${reporte['titulo']}'),
                                    Text(
                                      'Descripción: ${reporte['descripcion']}',
                                    ),
                                    SizedBox(height: 20),
                                    Text('Productos en el reporte:'),
                                    ...productos
                                        .map(
                                          (producto) => Text(
                                            'Producto ID: ${producto['producto_id']}, Cantidad: ${producto['cantidad']}',
                                          ),
                                        )
                                        .toList(),
                                  ],
                                )
                              : _reporteNoEncontrado();
                        default:
                          return Text('No encontrado');
                      }
                    }
                    return SizedBox();
                  },
                  future: _cargarReporte(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _cargarReporte() async {
    if (widget.tipo == TipoReporte.ultimoreporte) {
      return Basededatos.obtenerUltimoReporte();
    }

    if (widget.tipo == TipoReporte.inventario) {
      return Basededatos.obtenerObjetos();
    }
    return {};
  }

  Widget _reporteNoEncontrado() {
    return Expanded(
      child: Center(
        child: Column(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No se encontró ningún reporte'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.tipo = TipoReporte.inventario;
                });
              },
              child: Text("Crear reporte con inventario actual"),
            ),
          ],
        ),
      ),
    );
  }
}
