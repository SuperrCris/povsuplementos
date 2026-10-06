import 'package:flutter/material.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/widgets/botonMaterial.dart';

class GestionUsuarios extends StatefulWidget {
  const GestionUsuarios({Key? key}) : super(key: key);

  @override
  _GestionUsuariosState createState() => _GestionUsuariosState();
}

class _GestionUsuariosState extends State<GestionUsuarios> {
  late List<Map<String, dynamic>> usuarios = [];
  Map<int, bool> seleccionados = {}; // Para almacenar el estado de los checkboxes
  @override
  void initState() {
    super.initState();
    // Aquí puedes inicializar datos relacionados con los usuarios desde la base de datos
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    usuarios = await Basededatos.obtenerUsuarios();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),

                child: Row(
                  spacing: 8,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        BotonNavegacion(texto: 'Agregar Usuario', ),
                        SizedBox(height: 10),
                        BotonNavegacion(texto: 'Eliminar Usuario', ),
                        SizedBox(height: 10),
                        BotonNavegacion(texto: 'Modificar Usuario', ),
                      ],
                    ),
                   
             
                      Expanded(
                        child: Container(
                          height: 420,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (var usuario in usuarios)
                                  ListTile(
                                    title: Text(usuario['nombre'] ?? 'Nombre no disponible'),
                                    leading: Checkbox(
                                      value: seleccionados[usuario['id']] ?? false,
                                      onChanged: (bool? valor) {
                                        setState(() {
                                          seleccionados[usuario['id']] = valor ?? false;
                                          print(seleccionados);
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}