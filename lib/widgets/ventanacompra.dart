import 'package:flutter/material.dart';
import 'package:pov_suplementos/estructuras/objeto.dart';

class WidgetVenta extends StatelessWidget {
  final void Function() callback;
  final Objeto objeto;
  const WidgetVenta({super.key, required this.objeto, required this.callback});



  @override
  Widget build(BuildContext context) {
    if (objeto.categoria?.toLowerCase() == 'snack') {
      return Card(
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      objeto.productoNombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${objeto.precio.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Quedan: ${objeto.existencias}',
                      style: TextStyle(
                        color: objeto.existencias > 0
                            ? Colors.blue
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Agregar al carrito',
                onPressed: objeto.existencias > 0 ? callback : null,
                icon: const Icon(Icons.add_shopping_cart),
                color: Colors.green,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  child: objeto.imagenWidget != null
                      ? Image(
                          image: objeto.imagenWidget!.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagenNoDisponible(),
                        )
                      : _imagenNoDisponible(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              objeto.marcaNombre,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              objeto.productoNombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quedan: ${objeto.existencias}',
                    style: TextStyle(
                      color: objeto.existencias > 0 ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: objeto.existencias > 0 ? callback : null,
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );


  }

  Widget _imagenNoDisponible() {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }
}
