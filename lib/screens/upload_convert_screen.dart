import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'avatar_display_screen.dart';
import 'web_camera_screen.dart';

class UploadConvertScreen extends StatefulWidget {
  final bool isTemplate;

  const UploadConvertScreen({super.key, required this.isTemplate});

  @override
  _UploadConvertScreenState createState() => _UploadConvertScreenState();
}

class _UploadConvertScreenState extends State<UploadConvertScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>>? _templates;
  XFile? _imageFile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isTemplate) {
      _loadTemplates();
    }
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    final templates = await ApiService.fetchTemplates();
    if (templates != null) {
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load templates')),
      );
    }
  }

  Future<void> _assignTemplateToUser(String templateId) async {
    setState(() {
      _isLoading = true;
    });

    final userId = await ApiService.getFromCache('userId');
    if (userId != null) {
      final avatarId = await ApiService.assignTemplateToUser(templateId, userId);
      if (avatarId != null) {
        final saved = await ApiService.saveAvatar(avatarId);
        if (saved) {
          final filePathOrUrl = await ApiService.downloadAvatarGlb(avatarId);
          if (filePathOrUrl != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AvatarDisplayScreen(
                  avatarGlbUrl: filePathOrUrl,
                  avatarId: avatarId,
                  userId: userId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to download avatar')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save avatar')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign template')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
    }

    setState(() {
      _isLoading = false;
    });
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

  Future<String?> _getBase64Image() async {
    if (_imageFile == null) return null;
    final bytes = await _imageFile!.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        if (kIsWeb) {
          // For web, use the new camera screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebCameraScreen(),
            ),
          );
          return;
        } else {
          // For mobile, request camera permission
          final status = await Permission.camera.request();
          if (status.isDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera permission is required')),
              );
            }
            return;
          }
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
        
        // Automatically proceed with avatar generation
        final gender = await _selectGender(context);
        if (gender != null) {
          await _generateAvatar(gender);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _generateAvatar(String gender) async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final base64Image = await _getBase64Image();
      if (base64Image == null) {
        throw Exception('Failed to convert image to base64');
      }

      final userId = await ApiService.getFromCache('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Call your Ready Player Me API service here
      final avatarId = await ApiService.generateAvatar(base64Image, gender, userId);
      if (avatarId != null) {
        final saved = await ApiService.saveAvatar(avatarId);
        if (saved) {
          final filePathOrUrl = await ApiService.downloadAvatarGlb(avatarId);
          if (filePathOrUrl != null && mounted) {
            Navigator.push(
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
          SnackBar(content: Text('Error generating avatar: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTemplate ? 'Select Template' : 'Upload Photo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.isTemplate
              ? _buildTemplateList()
              : _buildUploadSection(),
    );
  }

  Widget _buildTemplateList() {
    if (_templates == null || _templates!.isEmpty) {
      return const Center(child: Text('No templates available.'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
      ),
      itemCount: _templates!.length,
      itemBuilder: (context, index) {
        final template = _templates![index];
        return GestureDetector(
          onTap: () {
            _assignTemplateToUser(template['id']);
          },
          child: Card(
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    template['imageUrl'],
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    template['gender'] ?? 'Unnamed Template',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadSection() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null) ...[
                kIsWeb
                    ? Image.network(_imageFile!.path, height: 200)
                    : FutureBuilder<Uint8List>(
                        future: _imageFile!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return Image.memory(snapshot.data!, height: 200);
                          } else if (snapshot.hasError) {
                            return const Text('Error loading image');
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ],
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final gender = await _selectGender(context);
                    if (gender != null) {
                      await _generateAvatar(gender);
                    }
                  },
                  child: const Text('Generate Avatar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
