import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';

class VentaControlador {
  final List<ItemCarrito> carrito;
  VentaControlador({required this.carrito});

  Future<void> procesarVenta(BuildContext context) async {

    StringBuffer ticket = StringBuffer();
    ticket.writeln("SUPLEMENTOS BEG");
    ticket.writeln("----- Ticket de Venta -----");
    for (final p in carrito){
      ticket.writeln("${p.cantidad} ${p.producto.productoNombre}");
    }

    ticket.writeln("---------------");
    ticket.writeln("Total: \$${carrito.fold(0.0, (sum, item) => sum + item.subtotal).toStringAsFixed(2)}");
    print(ticket.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Venta procesada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}