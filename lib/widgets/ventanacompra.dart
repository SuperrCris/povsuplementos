import 'package:flutter/material.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';

class WidgetVenta extends StatelessWidget {
  final void Function() callback;
  final Objeto objeto;
  const WidgetVenta({super.key, required this.objeto, required this.callback});



  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                child: objeto.imagenWidget != null
                    ? Image(
                        image: objeto.imagenWidget!.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            _imagenNoDisponible('Error al cargar'),
                      )
                    : _imagenNoDisponible('Sin imagen'),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        objeto.marcaNombre,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        objeto.productoNombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '\$${objeto.precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quedan: ${objeto.existencias}',
                              style: TextStyle(
                                color: objeto.existencias > 0
                                    ? Colors.blue
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              callback();
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(10),
                                color: Colors.green
                              ),
                              child: Icon(
                                Icons.add_shopping_cart,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    
                        SizedBox(width: 8),
                    

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );


  }

  Widget _imagenNoDisponible(String mensaje) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 50, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            mensaje,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
