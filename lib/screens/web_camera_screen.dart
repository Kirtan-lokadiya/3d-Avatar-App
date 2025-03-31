import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/api_service.dart';
import 'avatar_display_screen.dart';

class WebCameraScreen extends StatefulWidget {
  const WebCameraScreen({super.key});

  @override
  State<WebCameraScreen> createState() => _WebCameraScreenState();
}

class _WebCameraScreenState extends State<WebCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras found');
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing camera: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userId = await ApiService.getFromCache('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final gender = await _selectGender(context);
      if (gender == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final avatarId = await ApiService.generateAvatar(base64Image, gender, userId);
      if (avatarId != null) {
        final saved = await ApiService.saveAvatar(avatarId);
        if (saved) {
          final filePathOrUrl = await ApiService.downloadAvatarGlb(avatarId);
          if (filePathOrUrl != null && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AvatarDisplayScreen(
                  avatarGlbUrl: filePathOrUrl,
                  avatarId: avatarId,
                  userId: userId,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _selectGender(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'male'),
              child: const Text('Male'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'female'),
              child: const Text('Female'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_controller!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _takePicture,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera),
                label: Text(_isLoading ? 'Processing...' : 'Take Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 