import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'dart:io';

class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final String categoria;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImageWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    required this.categoria,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    AppLog.d('ProductImageWidget - imagePath: $imagePath');
    AppLog.d('ProductImageWidget - imageUrl: $imageUrl');
    AppLog.d('ProductImageWidget - categoria: $categoria');
    
    // Prioridad: imagen local > imagen URL > imagen por defecto
    if (imagePath != null && imagePath!.isNotEmpty) {
      AppLog.d('Usando imagen local: $imagePath');
      return _buildLocalImage();
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      AppLog.d('Usando imagen URL: $imageUrl');
      return _buildNetworkImage();
    } else {
      AppLog.d('Usando imagen por defecto');
      return _buildDefaultImage();
    }
  }

  Widget _buildLocalImage() {
    AppLog.d('Intentando cargar imagen local: $imagePath');
    final file = File(imagePath!);
    
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        AppLog.e('Error cargando imagen local', error);
        return _buildDefaultImage();
      },
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imageUrl!,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultImage();
      },
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(),
              size: ((height ?? 100) * 0.4).clamp(16.0, 40.0),
              color: Colors.white,
            ),
            if ((height ?? 100) > 50) ...[
              const SizedBox(height: 2),
              Text(
                _getCategoryName(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ((height ?? 100) * 0.12).clamp(8.0, 12.0),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (categoria.toLowerCase()) {
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
    switch (categoria.toLowerCase()) {
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

  String _getCategoryName() {
    switch (categoria.toLowerCase()) {
      case 'ropa deportiva':
        return 'ROPA';
      case 'calzado deportivo':
        return 'CALZADO';
      case 'equipamiento':
        return 'EQUIPO';
      case 'suplementos':
        return 'SUPLEM';
      case 'accesorios':
        return 'ACCES';
      default:
        return 'PRODUCTO';
    }
  }
}
