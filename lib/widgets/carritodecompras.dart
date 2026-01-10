import 'package:flutter/material.dart';
import 'package:pov_suplementos/auth/gestorsesion.dart';
import 'package:pov_suplementos/auth/modelo_usuario.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';
import 'package:pov_suplementos/widgets/cuadroobjetocarrito.dart';
import 'package:pov_suplementos/widgets/ventanametodopago.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ItemCarrito {
  final Objeto producto;
  int cantidad; 
  ItemCarrito({required this.producto, this.cantidad = 1,});

  double get subtotal => producto.precio * cantidad;
  int get existencias => producto.existencias;
}

class CarritoControlador {
  _EstadoWidgetCarritoCompra? _estado;
  VoidCallback? _refreshCallback;

  
  void _atarEstado(_EstadoWidgetCarritoCompra state) {
    _estado = state;
  }
  
  void _quitarEstado() {
    _estado = null;
  }
  
  void setRefreshCallback(VoidCallback callback) {
    _refreshCallback = callback;
  }
  
  void agregarAlCarrito(Objeto producto) {
    _estado?.agregarAlCarrito(producto);
  }
  
  void limpiarCarrito() {
    _estado?._limpiarCarrito();
  }
  
  void _onVentaProcesada() {
    _refreshCallback?.call();
  }
  
  List<ItemCarrito>? get items => _estado?.carrito;

  double get total {
    if (_estado?.carrito == null) return 0.0;
    return _estado!.carrito.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}

class WidgetCarritoCompra extends StatefulWidget {
  final CarritoControlador? controller;
  
  const WidgetCarritoCompra({super.key, this.controller});

  @override
  State<WidgetCarritoCompra> createState() => _EstadoWidgetCarritoCompra();
}

class _EstadoWidgetCarritoCompra extends State<WidgetCarritoCompra>  with RolRequerido{
  List<ItemCarrito> carrito = [];

  @override
  RolUsuario get rolRequerido => RolUsuario.cajero;

  @override
  void initState() {
    super.initState();
    widget.controller?._atarEstado(this);
  }

  @override
  void dispose() {
    widget.controller?._quitarEstado();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double total = carrito.fold(0.0, (sum, item) => sum + item.subtotal);
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), 
          ),
        ],
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart header
          Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Carrito de Compras',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Spacer(),
              if (carrito.isNotEmpty)
                TextButton(
                  onPressed: _limpiarCarrito,
                  child: Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          
          Divider(),
          
          // Cart content
          Expanded(
            child: carrito.isEmpty 
              ? _listaSinProductos()
              : _listaConProductos(),
          ),
          
          if (carrito.isNotEmpty) ...[
            Divider(),
            _widgetTotal(total),
          ],
        ],
      ),
    );
  }

  Widget _listaSinProductos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Carrito vacio 🫣',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega productos para comenzar',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaConProductos() {
    return ListView.builder(
      itemCount: carrito.length,
      itemBuilder: (context, index) {
        final item = carrito[index];
        return ElementoCompra(
          item: item,
          index: index,
          agregar: _incrementarCantidad,
          eliminarDelCarrito: _eliminarDelCarrito,
          disminuir: _decrementarCantidad,
        );

         /**Card(
          margin: EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: item.producto.imagenWidget ?? 
                    Icon(Icons.image, color: Colors.grey),
                ),
                
                SizedBox(width: 12),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.producto.productoNombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${item.producto.precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _decrementarCantidad(index),
                      icon: Icon(Icons.remove_circle_outline, size: 20),
                      constraints: BoxConstraints(minWidth: 30),
                      padding: EdgeInsets.zero,
                    ),
                    
                    Container(
                      width: 30,
                      child: Text(
                        '${item.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    IconButton(
                      onPressed: () => _incrementarCantidad(index),
                      icon: Icon(Icons.add_circle_outline, size: 20),
                      constraints: BoxConstraints(minWidth: 30),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                
                IconButton(
                  onPressed: () => _eliminarDelCarrito(index),
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  constraints: BoxConstraints(minWidth: 30),
                ),
              ],
            ),
          ),
        );*/
      },
    );
  }

  Widget _widgetTotal(double total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${carrito.fold(0, (sum, item) => sum + item.cantidad)} ${carrito.fold(0, (sum, item) => sum + item.cantidad) == 1 ? 'Producto' : 'Productos'}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _procesarVenta,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Procesar Venta (\$${total.toStringAsFixed(2)})',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void agregarAlCarrito(Objeto producto) {
    setState(() {
            int existingIndex = carrito.indexWhere(
        (item) => item.producto.codigo == producto.codigo
      );
      
      if (existingIndex >= 0) {

        carrito[existingIndex].cantidad++;
      } else {

        carrito.add(ItemCarrito(producto: producto));
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto.productoNombre} agregado al carrito'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _eliminarDelCarrito(int index) {
    setState(() {
      carrito.removeAt(index);
    });
  }

  void _incrementarCantidad(int index) {
    setState(() {
      if (carrito[index].cantidad >= carrito[index].existencias) return;
        carrito[index].cantidad++;
    });
  }

  void _decrementarCantidad(int index) {
    setState(() {
      if (carrito[index].cantidad > 1) {
        carrito[index].cantidad--;
      } else {
        carrito.removeAt(index);
      }
    });
  }

  void _limpiarCarrito() {
    setState(() {
      carrito.clear();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carrito limpiado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _procesarVenta() {
    if (carrito.isEmpty) return;
    

    final infoSesion = ProveedorDeInformacionDeSesion.of(context);
    if (infoSesion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe iniciar sesión para procesar ventas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => ProveedorDeInformacionDeSesion(
        usuario: infoSesion.usuario,
        child: VentanaMetodoPago(
          carrito: carrito,
          limpiarCarrito: _limpiarCarrito,
          onVentaProcesada: () {
            widget.controller?._onVentaProcesada();
          },
        ),
      ),
    );
  }
  

}
