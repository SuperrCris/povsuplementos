import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class GestorImagenes {
  static final formatosSoportados = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];
  static Future<Directory> _obtenerDirImagenes() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagenesDir = Directory(path.join(appDir.path, 'pov_suplementos', 'imagenes'));
    
    if (!await imagenesDir.exists()) {
      await imagenesDir.create(recursive: true);
    }
    return imagenesDir;
  }


  static Future<void> listarImagenes() async {
    print("Buscando imaganes:");
    final imagenesDir = await _obtenerDirImagenes();
    final archivos = imagenesDir.listSync();
    
    for (var archivo in archivos) {
      print('Imagen encontrada: ${path.basename(archivo.path)}');
    }
  }
  

  static Future<String> guardarImagen(String rutaOriginal, String nombreArchivo) async {

    print('Guardando imagen: $rutaOriginal como $nombreArchivo');
    try {
      final File archivoOriginal = File(rutaOriginal);
      if (!await archivoOriginal.exists()) {
        throw Exception('El archivo no existe: $rutaOriginal');
      }
      
      final extension = path.extension(rutaOriginal).toLowerCase();
      
      if (!formatosSoportados.contains(extension)) {
        throw Exception('Formato de imagen no soportado: $extension');
      }

        for (var ext in formatosSoportados){
          if (nombreArchivo.endsWith(ext)){
            nombreArchivo = nombreArchivo.replaceAll(ext, '');
          }
        }

       String nombreArchivoConExtension = '$nombreArchivo$extension';

      if (await existeImagen(nombreArchivoConExtension)) {
        int contador = 1;
        String nuevoNombre;
        do {
          nuevoNombre = '${nombreArchivo}_$contador$extension';
          contador++;
        } while (await existeImagen(nuevoNombre));
        nombreArchivoConExtension = nuevoNombre;
      }
      
      final imagenesDir = await _obtenerDirImagenes();
      final archivoDestino = File(path.join(imagenesDir.path, nombreArchivoConExtension));
      
      await archivoOriginal.copy(archivoDestino.path);
      
      print('Imagen guardada como: $nombreArchivoConExtension');
      return nombreArchivoConExtension;
      
    } catch (e) {
      print('Error al guardar imagen: $e');
      rethrow;
    }
  }
  
  static Future<String> obtenerRutaImagen(String nombreArchivo) async {
    final imagenesDir = await _obtenerDirImagenes();
    return path.join(imagenesDir.path, nombreArchivo);
  }
  
  static Future<bool> existeImagen(String nombreArchivo) async {
    try {
      final rutaCompleta = await obtenerRutaImagen(nombreArchivo);
      return await File(rutaCompleta).exists();
    } catch (e) {
      return false;
    }
  }
  
  static Future<ImageProvider?> obtenerImageProvider(String nombreArchivo) async {
    try {
      if (await existeImagen(nombreArchivo)) {
        final rutaCompleta = await obtenerRutaImagen(nombreArchivo);
        return FileImage(File(rutaCompleta));
      }
      return null;
    } catch (e) {
      print('Error al cargar imagen: $e');
      return null;
    }
  }



}