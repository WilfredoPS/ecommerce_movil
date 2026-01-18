import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../utils/logger.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Seleccionar imagen desde galería
  Future<String?> pickImageFromGallery() async {
    try {
      AppLog.d('Abriendo selector de galería...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      AppLog.d('Imagen seleccionada de galería: ${image?.path}');
      
      if (image != null) {
        AppLog.d('Guardando imagen en directorio local...');
        final String savedPath = await _saveImageToLocal(image.path);
        AppLog.i('Imagen guardada en: $savedPath');
        return savedPath;
      }
      AppLog.d('No se seleccionó imagen de galería');
      return null;
    } catch (e) {
      AppLog.e('Error seleccionando imagen de galería', e);
      return null;
    }
  }

  /// Capturar imagen desde cámara
  Future<String?> pickImageFromCamera() async {
    try {
      AppLog.d('Abriendo cámara...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      AppLog.d('Imagen capturada: ${image?.path}');
      
      if (image != null) {
        AppLog.d('Guardando imagen en directorio local...');
        final String savedPath = await _saveImageToLocal(image.path);
        AppLog.i('Imagen guardada en: $savedPath');
        return savedPath;
      }
      AppLog.d('No se capturó imagen');
      return null;
    } catch (e) {
      AppLog.e('Error capturando imagen', e);
      return null;
    }
  }

  /// Mostrar opciones para seleccionar imagen
  Future<String?> pickImage() async {
    // En una implementación real, aquí mostrarías un modal con opciones
    // Por ahora, usaremos galería por defecto
    return await pickImageFromGallery();
  }

  /// Guardar imagen en el directorio local de la app
  Future<String> _saveImageToLocal(String imagePath) async {
    try {
      AppLog.d('Iniciando guardado de imagen: $imagePath');
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'product_images');
      
      AppLog.d('Directorio de imágenes: $imagesDir');
      
      // Crear directorio si no existe
      final Directory dir = Directory(imagesDir);
      if (!await dir.exists()) {
        AppLog.d('Creando directorio de imágenes...');
        await dir.create(recursive: true);
        AppLog.i('Directorio creado exitosamente');
      }

      // Generar nombre único para la imagen
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = path.join(imagesDir, fileName);
      
      AppLog.d('Ruta de destino: $newPath');

      // Verificar que el archivo fuente existe
      final File sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        throw Exception('El archivo fuente no existe: $imagePath');
      }
      
      AppLog.d('Archivo fuente existe, copiando...');
      
      // Copiar imagen al directorio de la app
      final File newFile = await sourceFile.copy(newPath);
      
      AppLog.i('Imagen copiada exitosamente a: ${newFile.path}');
      
      // Verificar que el archivo se copió correctamente
      if (await newFile.exists()) {
        AppLog.i('Verificación exitosa: archivo existe en destino');
        return newFile.path;
      } else {
        throw Exception('Error: el archivo no se copió correctamente');
      }
    } catch (e) {
      AppLog.e('Error guardando imagen', e);
      rethrow;
    }
  }

  /// Eliminar imagen local
  Future<bool> deleteImage(String imagePath) async {
    try {
      if (imagePath.isNotEmpty) {
        final File file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      AppLog.e('Error eliminando imagen', e);
      return false;
    }
  }

  /// Verificar si la imagen existe
  Future<bool> imageExists(String imagePath) async {
    if (imagePath.isEmpty) return false;
    
    try {
      final File file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtener imagen por defecto según la categoría
  String getDefaultImageForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'ropa deportiva':
        return 'assets/images/ropa_deportiva_default.png';
      case 'calzado deportivo':
        return 'assets/images/calzado_deportivo_default.png';
      case 'equipamiento':
        return 'assets/images/equipamiento_default.png';
      case 'suplementos':
        return 'assets/images/suplementos_default.png';
      case 'accesorios':
        return 'assets/images/accesorios_default.png';
      default:
        return 'assets/images/producto_default.png';
    }
  }
}
