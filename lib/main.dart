import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const PocketDashcamApp());
}

class PocketDashcamApp extends StatelessWidget {
  const PocketDashcamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Dashcam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Color(0xFF00E676),
        ),
      ),
      home: const DashcamScreen(),
    );
  }
}

class DashcamScreen extends StatefulWidget {
  const DashcamScreen({super.key});

  @override
  State<DashcamScreen> createState() => _DashcamScreenState();
}

class _DashcamScreenState extends State<DashcamScreen> with WidgetsBindingObserver {
  late final ApiVideoLiveStreamController _controller;
  final TextEditingController _rollNoController = TextEditingController(text: 'BTECH2505523');
  
  static const String _rtmpBaseUrl = 'rtmp://15.207.177.194:1936/hackathon/';
  
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isConnecting = false;
  bool _isFrontCamera = false;
  bool _isMuted = false;
  String _errorMessage = '';
  
  Timer? _timer;
  int _secondsStreamed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDashcam();
  }

  Future<void> _initDashcam() async {
    // Request Camera & Audio permissions
    final permissions = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (permissions[Permission.camera]?.isGranted != true ||
        permissions[Permission.microphone]?.isGranted != true) {
      setState(() {
        _errorMessage = 'Camera and Microphone permissions are required.';
      });
      return;
    }

    _controller = ApiVideoLiveStreamController(
      initialAudioConfig: AudioConfig(),
      initialVideoConfig: VideoConfig.withDefaultBitrate(),
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_isStreaming) {
        _stopStreaming();
      }
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.startPreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    if (_isInitialized) {
      if (_isStreaming) {
        _controller.stopStreaming();
      }
      _controller.dispose();
    }
    _rollNoController.dispose();
    super.dispose();
  }

  String get _currentStreamKey {
    final roll = _rollNoController.text.trim().toUpperCase().replaceAll(' ', '');
    final camTag = _isFrontCamera ? 'front' : 'back';
    return '${roll}_$camTag';
  }

  Future<void> _startStreaming() async {
    final rollNo = _rollNoController.text.trim();
    if (rollNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Roll Number first!')),
      );
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = '';
    });

    try {
      final key = _currentStreamKey;
      await _controller.startStreaming(
        streamKey: key,
        url: _rtmpBaseUrl,
      );

      if (mounted) {
        setState(() {
          _isStreaming = true;
          _isConnecting = false;
          _secondsStreamed = 0;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _secondsStreamed++;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _isConnecting = false;
          _errorMessage = 'Streaming error: $e';
        });
      }
    }
  }

  Future<void> _stopStreaming() async {
    _timer?.cancel();
    try {
      await _controller.stopStreaming();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isStreaming = false;
        _isConnecting = false;
      });
    }
  }

  Future<void> _toggleCamera() async {
    if (!_isInitialized) return;
    try {
      await _controller.switchCamera();
      setState(() {
        _isFrontCamera = !_isFrontCamera;
      });
      // If actively streaming, inform the user about key change
      if (_isStreaming && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${_isFrontCamera ? "FRONT" : "BACK"} camera (Key: $_currentStreamKey)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch camera: $e')),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    if (!_isInitialized) return;
    final newMute = !_isMuted;
    try {
      await _controller.setIsMuted(newMute);
      setState(() {
        _isMuted = newMute;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle audio: $e')),
        );
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Camera Viewfinder / Preview
            Positioned.fill(
              child: _isInitialized
                  ? ApiVideoCameraPreview(
                      controller: _controller,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.redAccent),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage.isNotEmpty ? _errorMessage : 'Initializing Dashcam Viewfinder...',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),

            // 2. Top HUD Bar (Status & Roll Number)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isStreaming ? Colors.redAccent : Colors.white24,
                    width: _isStreaming ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status row
                    Row(
                      children: [
                        // Live Dot
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isStreaming
                                ? Colors.red
                                : _isConnecting
                                    ? Colors.amber
                                    : Colors.grey,
                            boxShadow: _isStreaming
                                ? [const BoxShadow(color: Colors.red, blurRadius: 8, spreadRadius: 2)]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isStreaming
                              ? 'LIVE RTMP • ${_formatDuration(_secondsStreamed)}'
                              : _isConnecting
                                  ? 'CONNECTING...'
                                  : 'STANDBY',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isStreaming ? Colors.redAccent : Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // Camera Indicator Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isFrontCamera ? 'FRONT CAM' : 'BACK CAM',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.cyanAccent),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    // Roll number field & stream key
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 18, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rollNoController,
                            enabled: !_isStreaming,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: 'Enter Roll No (e.g. BTECH2505523)',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stream Key: $_currentStreamKey',
                      style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Error Banner (if any)
            if (_errorMessage.isNotEmpty)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Bottom Controls
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Switch Camera Button
                  _buildCircleButton(
                    icon: Icons.flip_camera_ios,
                    tooltip: 'Switch Camera',
                    onPressed: _toggleCamera,
                  ),

                  // Big Stream START / STOP Button
                  GestureDetector(
                    onTap: _isConnecting
                        ? null
                        : _isStreaming
                            ? _stopStreaming
                            : _startStreaming,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isStreaming ? Colors.red : Colors.greenAccent.shade700,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: _isStreaming ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isConnecting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Icon(
                                _isStreaming ? Icons.stop : Icons.videocam,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                  ),

                  // Mute Button
                  _buildCircleButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    tooltip: _isMuted ? 'Unmute' : 'Mute',
                    color: _isMuted ? Colors.redAccent : Colors.white24,
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = Colors.white24,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white30),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 26),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
