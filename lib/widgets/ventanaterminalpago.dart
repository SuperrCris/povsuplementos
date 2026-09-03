import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PagoTerminal extends StatefulWidget {
  final double total;
 

  PagoTerminal({required this.total});

  @override
  _PagoTerminalState createState() => _PagoTerminalState();
}



class _PagoTerminalState extends State<PagoTerminal> {
  bool _cancelado = false;
  http.Client? _sseClient;

  @override
  void initState() {
    super.initState();
    _procesarPago();
  }


  @override
  Widget build(BuildContext context) {
    double alto = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Pago con Terminal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 10,
          alignment: WrapAlignment.center,
          children: [
            Center(
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                constraints: BoxConstraints(maxWidth: 1000),
                height: alto * 0.5,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 21, 180, 21),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total a pagar:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                        AutoSizeText(
                        '${widget.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
        
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Conectando con terminal...'),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _cancelado = true;
          _sseClient?.close();
          Navigator.pop(context, false);
        },
        child: Icon(Icons.cancel),
      ),

    );
  }
  
  String URL = "https://REMOVED";
    Future<Map<String, dynamic>> _procesarPago() async {

      double monto = widget.total;
      http.Response solicitud;
      try{
      solicitud = await http.post(Uri.parse('$URL/crearorden?monto=$monto&descripcion="1 x Proteina"'),
      headers: {'Authorization': 'REMOVED'},
      );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al conectar con la terminal: $e'), duration: Duration(seconds: 2),  ),
          );
          Navigator.pop(context, false);
        }
        return {'exito': false, 'mensaje': 'Error al conectar con la terminal: $e'};
      }
     switch (solicitud.statusCode) {
     case 409:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('La terminal está ocupada, intenta nuevamente'), duration: Duration(seconds: 2),  ),
          );
          Navigator.pop(context, false);
        }
        return {'exito': false, 'mensaje': 'Terminal ocupada, intenta nuevamente'};
      }

      if (solicitud.statusCode != 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al crear la orden de pago ${solicitud.body}'), duration: Duration(seconds: 5),  ),
          );
          Navigator.pop(context, false);
        }
        return {'exito': false, 'mensaje': 'Error al crear la orden de pago'};
      }
    
     var solicitudJson = jsonDecode(utf8.decode(solicitud.bodyBytes)) as Map;
      var ordenId = solicitudJson['reference'] as String;
      print('Orden ID: $ordenId');

      return await _escucharSSE(ordenId);
    }


  Future<Map<String, dynamic>> _escucharSSE(String ordenId) async {
    _sseClient = http.Client();
    try {
      final request = http.Request(
        'GET',
        Uri.parse('$URL/stream/$ordenId'),
      );
      request.headers['Authorization'] = 'REMOVED';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final streamedResponse = await _sseClient!.send(request);

      if (streamedResponse.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al conectar con el stream de pago'), duration: Duration(seconds: 2)),
          );
          Navigator.pop(context, false);
        }
        return {'exito': false, 'mensaje': 'Error al conectar con el stream'};
      }

      final buffer = StringBuffer();
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        if (_cancelado) break;
        buffer.write(chunk);

        // Los mensajes SSE están separados por \n\n
        final partes = buffer.toString().split('\n\n');
        buffer.clear();
        buffer.write(partes.last); // el último puede estar incompleto

        for (int i = 0; i < partes.length - 1; i++) {
          for (final linea in partes[i].split('\n')) {
            if (!linea.startsWith('data:')) continue;
            final datos = linea.substring(5).trim();
            try {
              final json = jsonDecode(datos) as Map;
              final estado = json['status'] as String?;
              switch (estado) {
                case 'processed':
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pago procesado exitosamente'), duration: Duration(seconds: 2)),
                    );
                    Navigator.pop(context, true);
                  }
                  return {'exito': true, 'mensaje': 'Pago procesado exitosamente'};
                case 'error':
                case 'failed':
                case 'canceled':
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(json['mensaje'] as String? ?? 'Pago fallido o cancelado'), duration: Duration(seconds: 2)),
                    );
                    Navigator.pop(context, false);
                  }
                  return {'exito': false, 'mensaje': json['mensaje'] as String? ?? 'Pago fallido o cancelado'};
              }
            } catch (_) {
              // línea no es JSON (ej. comentarios keepalive)
            }
          }
        }
      }
    } catch (e) {
      if (!_cancelado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el stream de pago: $e'), duration: Duration(seconds: 2)),
        );
        Navigator.pop(context, false);
      }
      return {'exito': false, 'mensaje': 'Error en el stream: $e'};
    } finally {
      _sseClient?.close();
      _sseClient = null;
    }
    return {'exito': false, 'mensaje': 'Conexión cerrada inesperadamente'};
  }


  }



