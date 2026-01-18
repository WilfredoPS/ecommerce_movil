import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  const SyncState({this.isSyncing = false, this.lastSyncTime});
}

class SyncNotifier extends Notifier<SyncState> {
  final SyncService _syncService = SyncService();

  @override
  SyncState build() => SyncState(isSyncing: _syncService.isSyncing, lastSyncTime: _syncService.lastSyncTime);

  bool get isSyncing => state.isSyncing;
  DateTime? get lastSyncTime => state.lastSyncTime;

  Future<void> syncAll() async {
    try {
      await _syncService.syncAll();
      state = SyncState(isSyncing: _syncService.isSyncing, lastSyncTime: _syncService.lastSyncTime);
    } catch (e) {
      print('Error en sincronización: $e');
      rethrow;
    }
  }

  Future<bool> checkConnectivity() async {
    return await _syncService.checkConnectivity();
  }
}






