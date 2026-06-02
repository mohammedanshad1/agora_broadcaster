import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/index.dart';
import '../services/index.dart';
import '../viewmodels/index.dart';
import 'widgets/index.dart';

class HostLiveScreen extends StatefulWidget {
  final Function() onExit; // ← added just like AudienceLiveScreen

  const HostLiveScreen({super.key, required this.onExit});

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
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Setup Stream',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: widget.onExit, // ← goes back to HomeScreen safely
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Stream Details', Icons.info_outline),
                const SizedBox(height: 16),
                _buildGlassCard(
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _hostNameController,
                        label: 'Your Name',
                        icon: Icons.person_outline,
                        onChanged: viewModel.setHostName,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Stream Title',
                        icon: Icons.title,
                        onChanged: viewModel.setStreamTitle,
                      ),
                    ],
                  ),
                ),
                if (viewModel.lastError != null) ...[
                  const SizedBox(height: 24),
                  _buildErrorCard(viewModel),
                ],
                const SizedBox(height: 32),
                _buildSectionTitle('RTMP Configuration', Icons.router_outlined),
                const SizedBox(height: 16),
                Consumer<RTMPConfigViewModel>(
                  builder: (context, rtmpVM, _) {
                    return Column(
                      children: [
                        if (rtmpVM.configs.isEmpty)
                          _buildGlassCard(
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text(
                                  'No RTMP configurations added yet',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            ),
                          )
                        else
                          ...rtmpVM.configs.map((config) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildGlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    config.platformName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    config.rtmpUrl,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Checkbox(
                                    value: config.enabled,
                                    activeColor: Colors.deepPurpleAccent,
                                    onChanged:
                                        (value) =>
                                            rtmpVM.toggleConfig(config.id),
                                  ),
                                  onLongPress:
                                      () => rtmpVM.removeConfig(config.id),
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add RTMP Configuration',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _showRtmpConfigDialog(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed:
                        viewModel.isInitializing
                            ? null
                            : () =>
                                viewModel.startLiveStream(isBroadcaster: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: Colors.redAccent.withOpacity(0.5),
                    ),
                    child:
                        viewModel.isInitializing
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fiber_manual_record, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'START LIVE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveScreen(BuildContext context, LiveStreamViewModel viewModel) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Live Workspace',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.fiber_manual_record, size: 12, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.currentSession != null)
                  _buildGlassCard(
                    child: LiveStreamStatusWidget(
                      session: viewModel.currentSession!,
                    ),
                  ),
                const SizedBox(height: 32),
                _buildSectionTitle('Stream Status', Icons.analytics_outlined),
                const SizedBox(height: 16),
                _buildGlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          viewModel.streamStatus.message,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  'Platform Status',
                  Icons.cloud_done_outlined,
                ),
                const SizedBox(height: 16),
                Consumer<RTMPConfigViewModel>(
                  builder: (context, rtmpVM, _) {
                    final states = rtmpVM.streamStates;
                    if (states.isEmpty) {
                      return _buildGlassCard(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No platforms connected',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children:
                          states.map((state) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildGlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    state.config.platformName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    state.statusText,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  leading: _getStatusIcon(state.status),
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _showEndLiveDialog(context, viewModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'END LIVE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildErrorCard(LiveStreamViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.lastError!.message,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                if (viewModel.lastError!.details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    viewModel.lastError!.details!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.redAccent.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(RTMPStreamStatus status) {
    switch (status) {
      case RTMPStreamStatus.connecting:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        );
      case RTMPStreamStatus.connected:
        return const Icon(Icons.check_circle, color: Colors.greenAccent);
      case RTMPStreamStatus.failed:
        return const Icon(Icons.error, color: Colors.redAccent);
      default:
        return const Icon(Icons.radio_button_off, color: Colors.white54);
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
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add RTMP Config',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPlatform,
                      dropdownColor: const Color(0xFF333333),
                      style: const TextStyle(color: Colors.white),
                      items:
                          ['YouTube', 'Facebook', 'Instagram', 'Twitch']
                              .map(
                                (platform) => DropdownMenuItem(
                                  value: platform,
                                  child: Text(platform),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(
                            () => selectedPlatform = value ?? 'YouTube',
                          ),
                      decoration: InputDecoration(
                        labelText: 'Platform',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller:
                          urlController = TextEditingController(
                            text: 'rtmp://live.example.com/live',
                          ),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'RTMP URL',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: keyController = TextEditingController(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Stream Key',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
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
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'End Live?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to end the live stream?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  viewModel.stopLiveStream();
                  Navigator.pop(context);
                  widget
                      .onExit(); // ← go back to HomeScreen after ending stream
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'End Stream',
                  style: TextStyle(color: Colors.white),
                ),
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
