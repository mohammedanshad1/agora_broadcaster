import 'package:flutter/material.dart';
import '../../models/index.dart';

class LiveStreamStatusWidget extends StatelessWidget {
  final LiveStreamSession session;

  const LiveStreamStatusWidget({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Stream Information',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Title', session.title),
          const SizedBox(height: 8),
          _buildInfoRow('Host', session.hostName),
          const SizedBox(height: 8),
          _buildInfoRow('Channel', session.agoraChannelName),
          const SizedBox(height: 8),
          _buildInfoRow('Started At', _formatTime(session.startTime)),
          const SizedBox(height: 8),
          _buildInfoRow('Active Platforms', '${session.rtmpConfigs.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
