import 'dart:async';
enum Estado { sininiciar,espera, inicio, fallo }

class SimuladorInicio {
Estado estado = Estado.sininiciar;

  Estado get estadoActual => estado;

  void iniciar() async {
    estado = Estado.espera;
    await Future.delayed(const Duration(seconds: 3));
    estado = Estado.fallo;
  }

}