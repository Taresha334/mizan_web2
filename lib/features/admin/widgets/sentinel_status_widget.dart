// File Path: lib/features/admin/widgets/sentinel_status_widget.dart

import 'package:flutter/material.dart';

class SentinelStatusWidget extends StatelessWidget {
  final bool isActive;

  const SentinelStatusWidget({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          _buildPulseIndicator(),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActive ? "SENTINEL ONLINE" : "SENTINEL OFFLINE",
                style: TextStyle(
                  color: isActive ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                isActive
                    ? "Live SMS Monitoring Active"
                    : "Sync Paused - Tap to Start",
                style: TextStyle(
                  color: isActive ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            isActive ? Icons.check_circle : Icons.warning_rounded,
            color: isActive ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.red,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
    );
  }
}
