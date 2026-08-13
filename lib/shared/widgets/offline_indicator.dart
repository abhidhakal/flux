import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/services/sync_status_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SyncStatusService(),
      builder: (context, child) {
        final syncStatus = SyncStatusService().status;
        if (syncStatus == SyncStatus.synced) {
          return const SizedBox.shrink();
        }

        final isOffline = syncStatus == SyncStatus.offline;
        final pendingWrites = SyncStatusService().pendingWrites;
        return Semantics(
          liveRegion: true,
          label: isOffline
              ? 'Offline. Changes will sync when you are back online.'
              : 'Syncing $pendingWrites change${pendingWrites == 1 ? '' : 's'}',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: isOffline ? AppColors.error : AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOffline ? LucideIcons.wifiOff : LucideIcons.refreshCw,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isOffline
                      ? 'You\'re offline. Changes will sync when you\'re back online.'
                      : 'Syncing $pendingWrites change${pendingWrites == 1 ? '' : 's'}…',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
