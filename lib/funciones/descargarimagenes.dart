import 'dart:io';
import 'package:path/path.dart' as path;

Future<void> descargarImagenes() async {
  final currentDir = Directory.current.path;
  final direccion = path.join(
    currentDir,
    'cositasdego',
    'descargadeimagenes.exe',
  );

  if (!await File(direccion).exists()) {
    print('Error: No se encontró el ejecutable en $direccion');
    return;
  }

  final result = await Process.run(direccion, []);
  print('Terminado con: ${result.exitCode}');
  print('stdout: ${result.stdout}');
  print('stderr: ${result.stderr}');
}
