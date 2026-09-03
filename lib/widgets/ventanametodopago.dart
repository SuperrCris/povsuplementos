
import 'package:flutter/material.dart';
import 'package:pov_suplementos/funciones/procesarventa.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/auth/gestorsesion.dart';
import 'package:pov_suplementos/widgets/ventanaterminalpago.dart';

class VentanaMetodoPago extends StatelessWidget {
  final List<ItemCarrito> carrito;
  final VoidCallback limpiarCarrito;
  final VoidCallback? onVentaProcesada;
  final Future<bool> Function()? onTerminalPago;

  const VentanaMetodoPago({
    super.key,
    required this.carrito,
    required this.limpiarCarrito,
    this.onVentaProcesada,
    required this.onTerminalPago,
  });

  @override
  Widget build(BuildContext context) {
    final usuario = ProveedorDeInformacionDeSesion.usuarioDe(context);
    
    return AlertDialog(
        title: Text('Método de pago'),
        content: 
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            _botonMetodoPago(context, 'Efectivo', Icon(Icons.money), () async {
             procesarVenta(context, "efectivo");
            }
            ),
            _botonMetodoPago(context, 'Terminal', Icon(Icons.credit_card), () async {
              
              final exito = await onTerminalPago?.call() ?? false;
              if (exito) {
                procesarVenta(context, "terminal");
              }
            }),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
  
        ],
      );

      
  }
   Future<Map<String, dynamic>> procesarVenta(BuildContext context, String metodopago) async {
    final usuario = ProveedorDeInformacionDeSesion.usuarioDe(context);

    VentaControlador controlador = VentaControlador(carrito: carrito);
    final resultado = await controlador.procesarVenta(usuario, metodopago);

    if (resultado['exito']) {
      limpiarCarrito();
      onVentaProcesada?.call();
      Navigator.pop(context);  
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar venta: ${resultado['mensaje']}')),
      );
    }

    return resultado;
  }
  
  
 

  Widget _botonMetodoPago(BuildContext context, String metodo, Icon icono, VoidCallback? alPresionar) {
    return GestureDetector(
      onTap: alPresionar,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              icono,
              SizedBox(width: 8),
              Text(
                metodo,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

}