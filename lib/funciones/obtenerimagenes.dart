import 'dart:io';
import 'package:path/path.dart' as path;

Future<List<File>> obtenerTodasLasImagenes(String directoryPath) async {

  String fullPath;
  if (path.isAbsolute(directoryPath)) {
    fullPath = directoryPath;
  } else {
    fullPath = path.join(Directory.current.path, directoryPath);
  }
  
  final dir = Directory(fullPath);
  if (!await dir.exists()) {
    print('Directory not found: $fullPath');
    return [];
  }
  
  final files = await dir
      .list()
      .where((entity) =>
          entity is File &&
          (entity.path.toLowerCase().endsWith('.jpg') ||
           entity.path.toLowerCase().endsWith('.jpeg') ||
           entity.path.toLowerCase().endsWith('.png') ||
           entity.path.toLowerCase().endsWith('.gif') ||
           entity.path.toLowerCase().endsWith('.webp')))
      .cast<File>()
      .toList();
      
  print('Found ${files.length} images in: $fullPath');
  return files;
}