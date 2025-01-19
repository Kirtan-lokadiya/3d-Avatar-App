import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'avatar_display_screen.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile == null
                ? const Text('No image selected.')
                : kIsWeb
                    ? Image.network(_imageFile!.path, height: 200)
                    : FutureBuilder<Uint8List>(
                        future: _imageFile!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return Image.memory(snapshot.data!, height: 200);
                          } else if (snapshot.hasError) {
                            return const Text('Error loading image');
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                      ),
            ElevatedButton(
              onPressed: () async {
                print('Select Image button pressed');
                final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = pickedFile;
                  });
                  print('Image selected: ${pickedFile.path}');
                } else {
                  print('No image selected');
                }
              },
              child: const Text('Select Image'),
            ),
            ElevatedButton(
              onPressed: () async {
                print('Upload and Generate Avatar button pressed');
                final gender = await _selectGender(context);
                print('Gender selected: $gender');
                if (gender != null) {
                  final base64Image = await _getBase64Image();
                  print('Image converted to base64');
                  if (base64Image != null) {
                    final userId = await ApiService.getFromCache('userId');
                    print('User ID fetched: $userId');
                    if (userId != null) {
                      final avatarId = await ApiService.createAvatarWithImage(userId, base64Image, gender);
                      print('Avatar created with ID: $avatarId');
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
                      }
                    }
                  }
                }
              },
              child: const Text('Upload and Generate Avatar'),
            ),
          ],
        ),
      ),
    );
  }
}
