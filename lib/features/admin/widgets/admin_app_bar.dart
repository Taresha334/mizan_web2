import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/mizan_sentinel_service.dart';

class MizanAdminAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MizanAdminAppBar({super.key});
  @override
  State<MizanAdminAppBar> createState() => _MizanAdminAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MizanAdminAppBarState extends State<MizanAdminAppBar> {
  bool _isSyncing = false;
  final Color mizanGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final service = FlutterBackgroundService();
    final bool isRunning = await service.isRunning();
    if (mounted) setState(() => _isSyncing = isRunning);
  }

  Future<void> _toggleSync() async {
    final service = FlutterBackgroundService();
    final bool isRunning = await service.isRunning();

    if (isRunning) {
      service.invoke("stopService");
      await _updateStatus(false);
    } else {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
        Permission.notification,
      ].request();
      if (statuses[Permission.sms]!.isGranted) {
        await MizanSmsObserver.initializeService();
        await _updateStatus(true);
      }
    }
  }

  Future<void> _updateStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mizan_sentinel_active', status);
    if (mounted) setState(() => _isSyncing = status);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: mizanGreen,
      title: Row(
        children: [
          const Text(
            "MIZAN",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _isSyncing ? Colors.green.shade900 : Colors.red.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isSyncing ? "ACTIVE" : "OFFLINE",
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSyncing ? Icons.sensors : Icons.sensors_off,
            color: _isSyncing ? Colors.greenAccent : Colors.white54,
          ),
          onPressed: _toggleSync,
        ),
      ],
    );
  }
}
