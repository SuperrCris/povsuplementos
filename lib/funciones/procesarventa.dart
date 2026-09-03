import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';

class VentaControlador {
  final List<ItemCarrito> carrito;
  VentaControlador({required this.carrito});

  Future<Map<String, dynamic>> procesarVenta(dynamic usuario, String metodopago) async {
  try {
                final resultado = await Basededatos.guardarVenta({
                  'usuario_id': usuario.id,
                  'metodo_pago': metodopago,
                  'fecha': DateTime.now().toIso8601String(),
                  'total': carrito.fold(0.0, (sum, item) => sum + item.subtotal),
                }, List.generate(carrito.length, (index) => {
                  'productoCodigo': carrito[index].producto.codigo,
                  'cantidad': carrito[index].cantidad,
                  'precio': carrito[index].producto.precio,
                }));
                
if (!resultado['exito']) {
                  return {'exito': false, 'mensaje': resultado['mensaje']};
                }

    StringBuffer ticket = StringBuffer();
    ticket.writeln("SUPLEMENTOS BEG");
    ticket.writeln("----- Ticket de Venta -----");
    for (final p in carrito){
      ticket.writeln("${p.cantidad} ${p.producto.productoNombre}");
    }

    ticket.writeln("---------------");
    ticket.writeln("Total: \$${carrito.fold(0.0, (sum, item) => sum + item.subtotal).toStringAsFixed(2)}");
    print(ticket.toString());

    return {'exito': true, 'mensaje': 'Venta procesada exitosamente'};
  }
    catch (e) {
                return {'exito': false, 'mensaje': 'Error al procesar venta: $e'};
              }
  }
}