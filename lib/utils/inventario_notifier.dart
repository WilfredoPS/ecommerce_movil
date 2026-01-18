import 'package:flutter/material.dart';
import 'logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventario_provider.dart';

class InventarioNotifier {
  static void notifyChange(BuildContext context) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(inventarioProvider.notifier).refreshInventario();
  } catch (e) {
    AppLog.e('InventarioNotifier.notifyChange: Error notificando cambio', e);
    }
  }
}
