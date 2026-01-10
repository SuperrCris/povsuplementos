import 'package:flutter/material.dart';

class Objeto {
  final String codigo;
  final String productoNombre;
  final String marcaNombre;
  final String descripcion;
  final double precio;
  final String imagen;
  final int existencias;
  final String? categoria;
  late Image? imagenWidget;

  Objeto(
    {
    required this.codigo,
    required this.productoNombre,
    required this.marcaNombre,
    required this.descripcion,
    required this.precio,
    required this.imagen,
    required this.existencias,
    this.categoria,
    this.imagenWidget,
  });


}