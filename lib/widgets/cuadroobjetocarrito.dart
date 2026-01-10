import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:pov_suplementos/widgets/carritodecompras.dart';

class ElementoCompra extends StatefulWidget {
  final ItemCarrito item;
  final int index;
  final void Function(int index) disminuir;
  final void Function(int index) agregar;
  final void Function(int index) eliminarDelCarrito;
  const ElementoCompra({
    super.key,
    required this.item,
    required this.disminuir,
    required this.agregar,
    required this.eliminarDelCarrito,
    required this.index,
  });

  @override
  State<ElementoCompra> createState() => _ElementoCompraState();
}

class _ElementoCompraState extends State<ElementoCompra> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
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
                  child: widget.item.producto.imagenWidget ??
                    Icon(Icons.image, color: Colors.grey),
                ),
                
                SizedBox(width: 12),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.producto.productoNombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${widget.item.producto.precio.toStringAsFixed(2)}',
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
                      onPressed: () => widget.disminuir.call(widget.index),
                      icon: Icon(Icons.remove_circle_outline, size: 20),
                      constraints: BoxConstraints(minWidth: 30),
                      padding: EdgeInsets.zero,
                    ),
                    
                    Container(
                      width: 30,
                      child: Text(
                        '${widget.item.cantidad}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    IconButton(
                      onPressed: () => widget.agregar.call(widget.index),
                      icon: Icon(Icons.add_circle_outline, size: 20),
                      constraints: BoxConstraints(minWidth: 30),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                
                IconButton(
                  onPressed: () => widget.eliminarDelCarrito.call(widget.index),
                  icon: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  constraints: BoxConstraints(minWidth: 30),
                ),
              ],
            ),
          ),
        )
    );
  }
}