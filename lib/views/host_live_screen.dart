import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../viewmodels/index.dart';
import 'widgets/index.dart';

class HostLiveScreen extends StatefulWidget {
  const HostLiveScreen({super.key});

  @override
  State<HostLiveScreen> createState() => _HostLiveScreenState();
}

class _HostLiveScreenState extends State<HostLiveScreen> {
  late TextEditingController _hostNameController;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _hostNameController = TextEditingController();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _hostNameController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LiveStreamViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLive) {
          return _buildLiveScreen(context, viewModel);
        }
        return _buildPreLiveScreen(context, viewModel);
      },
    );
  }

  Widget _buildPreLiveScreen(
    BuildContext context,
    LiveStreamViewModel viewModel,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Live'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stream Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _hostNameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: viewModel.setHostName,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Stream Title',
                hintText: 'Enter stream title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: viewModel.setStreamTitle,
            ),
            const SizedBox(height: 32),
            if (viewModel.lastError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      viewModel.lastError!.message,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    if (viewModel.lastError!.details != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        viewModel.lastError!.details!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 32),
            const Text(
              'RTMP Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<RTMPConfigViewModel>(
              builder: (context, rtmpVM, _) {
                return Column(
                  children: [
                    if (rtmpVM.configs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No RTMP configurations added yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rtmpVM.configs.length,
                        itemBuilder: (context, index) {
                          final config = rtmpVM.configs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(config.platformName),
                              subtitle: Text(config.rtmpUrl),
                              trailing: Checkbox(
                                value: config.enabled,
                                onChanged: (value) {
                                  rtmpVM.toggleConfig(config.id);
                                },
                              ),
                              onLongPress: () {
                                rtmpVM.removeConfig(config.id);
                              },
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add RTMP Configuration'),
                onPressed: () => _showRtmpConfigDialog(context),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: viewModel.isInitializing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.fiber_manual_record),
                label: Text(
                  viewModel.isInitializing ? 'Starting...' : 'Start Live',
                ),
                onPressed: viewModel.isInitializing
                    ? null
                    : () => viewModel.startLiveStream(isBroadcaster: true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveScreen(
    BuildContext context,
    LiveStreamViewModel viewModel,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveStreamStatusWidget(session: viewModel.currentSession!),
            const SizedBox(height: 32),
            const Text(
              'Stream Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(viewModel.streamStatus.message),
            const SizedBox(height: 32),
            const Text(
              'Platform Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<RTMPConfigViewModel>(
              builder: (context, rtmpVM, _) {
                final states = rtmpVM.streamStates;
                if (states.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No platforms connected',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: states.length,
                  itemBuilder: (context, index) {
                    final state = states[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(state.config.platformName),
                        subtitle: Text(state.statusText),
                        leading: _getStatusIcon(state.status),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('End Live'),
                onPressed: () => _showEndLiveDialog(context, viewModel),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(RTMPStreamStatus status) {
    switch (status) {
      case RTMPStreamStatus.connecting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case RTMPStreamStatus.connected:
        return const Icon(Icons.check_circle, color: Colors.green);
      case RTMPStreamStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.radio_button_off);
    }
  }

  void _showRtmpConfigDialog(BuildContext context) {
    final rtmpVM = context.read<RTMPConfigViewModel>();
    late TextEditingController urlController;
    late TextEditingController keyController;
    String selectedPlatform = 'YouTube';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add RTMP Configuration'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPlatform,
                      items: ['YouTube', 'Facebook', 'Instagram', 'Twitch']
                          .map(
                            (platform) => DropdownMenuItem(
                              value: platform,
                              child: Text(platform),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPlatform = value ?? 'YouTube';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Platform',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlController =
                          TextEditingController(text: 'rtmp://live.example.com/live'),
                      decoration: InputDecoration(
                        labelText: 'RTMP URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keyController = TextEditingController(),
                      decoration: InputDecoration(
                        labelText: 'Stream Key',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    rtmpVM.addConfig(
                      platform: _getPlatform(selectedPlatform),
                      platformName: selectedPlatform,
                      rtmpUrl: urlController.text,
                      streamKey: keyController.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEndLiveDialog(BuildContext context, LiveStreamViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Live?'),
        content: const Text('Are you sure you want to end the live stream?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.stopLiveStream();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('End Stream'),
          ),
        ],
      ),
    );
  }

  StreamPlatform _getPlatform(String name) {
    switch (name) {
      case 'YouTube':
        return StreamPlatform.youtube;
      case 'Facebook':
        return StreamPlatform.facebook;
      case 'Instagram':
        return StreamPlatform.instagram;
      case 'Twitch':
        return StreamPlatform.twitch;
      default:
        return StreamPlatform.custom;
    }
  }
}
