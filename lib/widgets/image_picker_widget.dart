import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';
import '../utils/logger.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? currentImagePath;
  final String categoria;
  final Function(String?) onImageSelected;
  final double? width;
  final double? height;

  const ImagePickerWidget({
    super.key,
    this.currentImagePath,
    required this.categoria,
    required this.onImageSelected,
    this.width,
    this.height,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageService _imageService = ImageService();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.currentImagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen del Producto',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Mostrar imagen actual
        Center(
          child: Container(
            width: widget.width ?? 200,
            height: widget.height ?? 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                    ),
                  )
                : _buildPlaceholder(),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Botones de acción
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.photo_library,
              label: 'Galería',
              onPressed: _pickFromGallery,
            ),
            _buildActionButton(
              icon: Icons.camera_alt,
              label: 'Cámara',
              onPressed: _pickFromCamera,
            ),
            if (_selectedImagePath != null)
              _buildActionButton(
                icon: Icons.delete,
                label: 'Eliminar',
                onPressed: _removeImage,
                isDestructive: true,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toca para agregar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red.shade600 : null,
        foregroundColor: isDestructive ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      AppLog.d('Iniciando selección de imagen desde galería...');
      final String? imagePath = await _imageService.pickImageFromGallery();
      AppLog.d('Imagen seleccionada: $imagePath');
      
      if (imagePath != null) {
        setState(() {
          _selectedImagePath = imagePath;
        });
        AppLog.d('Llamando callback con imagen: $imagePath');
        widget.onImageSelected(imagePath);
        AppLog.d('Callback ejecutado exitosamente');
      } else {
        AppLog.d('No se seleccionó ninguna imagen');
      }
    } catch (e) {
      AppLog.e('Error seleccionando imagen', e);
      _showError('Error seleccionando imagen: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      AppLog.d('Iniciando captura de imagen desde cámara...');
      final String? imagePath = await _imageService.pickImageFromCamera();
      AppLog.d('Imagen capturada: $imagePath');
      
      if (imagePath != null) {
        setState(() {
          _selectedImagePath = imagePath;
        });
        AppLog.d('Llamando callback con imagen: $imagePath');
        widget.onImageSelected(imagePath);
        AppLog.d('Callback ejecutado exitosamente');
      } else {
        AppLog.d('No se capturó ninguna imagen');
      }
    } catch (e) {
      AppLog.e('Error capturando imagen', e);
      _showError('Error capturando imagen: $e');
    }
  }

  void _removeImage() {
    AppLog.d('Eliminando imagen seleccionada');
    setState(() {
      _selectedImagePath = null;
    });
    AppLog.d('Llamando callback con imagen null');
    widget.onImageSelected(null);
    AppLog.d('Callback ejecutado exitosamente');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.categoria.toLowerCase()) {
      case 'ropa deportiva':
        return Colors.blue.shade600;
      case 'calzado deportivo':
        return Colors.orange.shade600;
      case 'equipamiento':
        return Colors.green.shade600;
      case 'suplementos':
        return Colors.purple.shade600;
      case 'accesorios':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.categoria.toLowerCase()) {
      case 'ropa deportiva':
        return Icons.checkroom;
      case 'calzado deportivo':
        return Icons.sports_soccer;
      case 'equipamiento':
        return Icons.sports_basketball;
      case 'suplementos':
        return Icons.local_drink;
      case 'accesorios':
        return Icons.sports;
      default:
        return Icons.inventory_2;
    }
  }
}
