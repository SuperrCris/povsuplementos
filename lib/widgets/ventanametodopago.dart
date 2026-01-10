import 'package:flutter/material.dart';
import 'package:pov_suplementos/funciones/procesarventa.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';
import 'package:pov_suplementos/funciones/basededatos.dart';
import 'package:pov_suplementos/auth/gestorsesion.dart';

class VentanaMetodoPago extends StatelessWidget {
  final List<ItemCarrito> carrito;
  final VoidCallback limpiarCarrito;
  final VoidCallback? onVentaProcesada;

  const VentanaMetodoPago({
    super.key,
    required this.carrito,
    required this.limpiarCarrito,
    this.onVentaProcesada,
  });

  @override
  Widget build(BuildContext context) {
    final usuario = ProveedorDeInformacionDeSesion.usuarioDe(context);
    
    return AlertDialog(
        title: Text('Método de pago'),
        content: Text('¿Confirmar venta por \$${carrito.fold(0.0, (sum, item) => sum + item.subtotal).toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final resultado = await Basededatos.guardarVenta({
                  'usuario_id': usuario.id,
                  'metodo_pago': 'efectivo',
                  'fecha': DateTime.now().toIso8601String(),
                  'total': carrito.fold(0.0, (sum, item) => sum + item.subtotal),
                }, List.generate(carrito.length, (index) => {
                  'productoCodigo': carrito[index].producto.codigo,
                  'cantidad': carrito[index].cantidad,
                  'precio': carrito[index].producto.precio,
                }));
                
                if (!resultado['exito']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${resultado['mensaje']}'),
                      backgroundColor: Colors.red,
                    )
                  );
                  return;
                }
                
                // Procesar venta (ticket, etc.)
                await VentaControlador(carrito: carrito).procesarVenta(context);
                limpiarCarrito();
                
                // Ejecutar el callback para refrescar los productos
                onVentaProcesada?.call();
                
                Navigator.pop(context);
                
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al procesar venta: $e'),
                    backgroundColor: Colors.red,
                  )
                );
              }
            },
            child: Text('Confirmar Venta'),
          ),
        ],
      );
  }
  
  
  
  }