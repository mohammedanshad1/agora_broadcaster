import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../viewmodels/index.dart';

class AudienceLiveScreen extends StatefulWidget {
  final Function() onExit;

  const AudienceLiveScreen({super.key, required this.onExit});

  @override
  State<AudienceLiveScreen> createState() => _AudienceLiveScreenState();
}

class _AudienceLiveScreenState extends State<AudienceLiveScreen> {
  int? _remoteUid;
  bool _isVideoReady = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // ✅ Register callbacks FIRST, then join
        _setupRemoteUserListener();
        _joinStream();
      }
    });
  }

  void _setupRemoteUserListener() {
    final viewModel = context.read<LiveStreamViewModel>();

    viewModel.onRemoteUserJoined = (uid) async {
      print('✅ Screen: remote user joined $uid');
      if (mounted) {
        setState(() {
          _remoteUid = uid;
          _isVideoReady = true;
        });
        await _setupRemoteVideo(viewModel, uid);
      }
    };

    viewModel.onRemoteUserLeft = (uid) {
      print('❌ Screen: remote user left $uid');
      if (mounted) {
        setState(() {
          if (_remoteUid == uid) {
            _remoteUid = null;
            _isVideoReady = false;
          }
        });
      }
    };
  }

  Future<void> _joinStream() async {
    if (!mounted) return;
    setState(() => _isJoining = true);

    final viewModel = context.read<LiveStreamViewModel>();

    if (viewModel.currentSession != null) {
      await viewModel.joinAsAudience(
        viewModel.currentSession!.agoraChannelName,
      );
    } else {
      final channelName = await _showChannelDialog();
      if (channelName != null && channelName.isNotEmpty) {
        await viewModel.joinAsAudience(channelName);
      } else {
        if (mounted) widget.onExit();
        return;
      }
    }

    if (mounted) {
      // ✅ Host may already be in channel before we joined — check remoteUsers
      final existing = viewModel.remoteUsers;
      print('Remote users already in channel: $existing');
      if (existing.isNotEmpty) {
        final uid = existing.first;
        setState(() {
          _remoteUid = uid;
          _isVideoReady = true;
        });
        await _setupRemoteVideo(viewModel, uid);
      }

      setState(() => _isJoining = false);
    }
  }

  Future<String?> _showChannelDialog() async {
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChannelInputDialog(),
    );
  }

  Future<void> _setupRemoteVideo(LiveStreamViewModel viewModel, int uid) async {
    try {
      await viewModel.setupRemoteVideo(uid);
      print('✅ setupRemoteVideo called for uid: $uid');
    } catch (e) {
      print('🔴 Error setting up remote video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Live Stream',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () async {
            final viewModel = context.read<LiveStreamViewModel>();
            await viewModel.leaveAudience();
            if (mounted) widget.onExit();
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.volume_up), onPressed: () {}),
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
          child: Consumer<LiveStreamViewModel>(
            builder: (context, viewModel, _) {
              if (_isJoining) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Joining stream...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              // ✅ Only show empty state if we have no session AND no remote user
              if (viewModel.currentSession == null && _remoteUid == null) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  _buildVideoPreview(viewModel),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (viewModel.currentSession != null)
                            _buildStreamCard(viewModel.currentSession!),
                          const SizedBox(height: 24),
                          _buildStatusSection(viewModel.streamStatus.message),
                          const SizedBox(height: 20),
                          _buildAudioControls(),
                          const SizedBox(height: 20),
                          _buildLeaveButton(viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(LiveStreamViewModel viewModel) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.deepPurpleAccent.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // ✅ Remote video with correct connection object
            if (_remoteUid != null &&
                _isVideoReady &&
                viewModel.currentSession != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: viewModel.getRtcEngine(),
                  canvas: VideoCanvas(
                    uid: _remoteUid!,
                    renderMode: RenderModeType.renderModeFit,
                  ),
                  connection: RtcConnection(
                    channelId: viewModel.currentSession!.agoraChannelName,
                  ),
                ),
              )
            else
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _remoteUid != null
                            ? 'Loading video...'
                            : 'Waiting for host to start streaming...',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

            // LIVE Badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_remoteUid != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        'Host',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Audio Active',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.audiotrack, color: Colors.blueAccent),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Audio Stream',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Connected',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamCard(dynamic session) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.timer_outlined,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(session.duration),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                session.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      session.hostName.isNotEmpty
                          ? session.hostName[0].toUpperCase()
                          : 'H',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hosted by ${session.hostName}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection(String statusMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stream Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveButton(LiveStreamViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          await viewModel.leaveAudience();
          if (mounted) widget.onExit();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        child: const Text(
          'LEAVE STREAM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
            child: const Icon(
              Icons.videocam_off_outlined,
              size: 80,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No live stream available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Check back later or start a new stream',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: widget.onExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6200EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    final viewModel = context.read<LiveStreamViewModel>();
    viewModel.onRemoteUserJoined = null;
    viewModel.onRemoteUserLeft = null;
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog widget — controller lifecycle managed safely by Flutter
// ─────────────────────────────────────────────────────────────────────────────

class _ChannelInputDialog extends StatefulWidget {
  const _ChannelInputDialog();

  @override
  State<_ChannelInputDialog> createState() => _ChannelInputDialogState();
}

class _ChannelInputDialogState extends State<_ChannelInputDialog> {
  late final TextEditingController _channelController;

  @override
  void initState() {
    super.initState();
    _channelController = TextEditingController();
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _channelController.text.trim();
    if (value.isNotEmpty) {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Join Live Stream',
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _channelController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter host name (e.g. john)',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Join', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
