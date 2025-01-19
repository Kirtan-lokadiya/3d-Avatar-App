import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../services/api_service.dart';

class AvatarDisplayScreen extends StatefulWidget {
  final String avatarGlbUrl;
  final String avatarId;
  final String userId;

  const AvatarDisplayScreen(
      {super.key,
      required this.avatarGlbUrl,
      required this.avatarId,
      required this.userId});

  @override
  _AvatarDisplayScreenState createState() => _AvatarDisplayScreenState();
}

class _AvatarDisplayScreenState extends State<AvatarDisplayScreen> {
  Flutter3DController controller = Flutter3DController();
  List<Map<String, dynamic>>? _assets;
  bool _isLoading = true;
  late String _avatarGlbUrl;

  @override
  void initState() {
    super.initState();
    _avatarGlbUrl = widget.avatarGlbUrl;
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    final assets = await ApiService.fetchAssets(widget.userId);
    setState(() {
      _assets = assets;
      _isLoading = false;
    });
  }

  Future<void> _equipAsset(String assetId) async {
  setState(() {
    _isLoading = true;
  });

  final response = await ApiService.equipAsset(widget.avatarId, assetId);
  if (response) {
    await Future.delayed(const Duration(seconds: 2)); // Delay for API processing
    final updatedAvatarUrl =
        "https://api.readyplayer.me/v2/avatars/${widget.avatarId}.glb?t=${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      controller = Flutter3DController();
      _avatarGlbUrl = updatedAvatarUrl;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to equip asset')),
    );
  }

  setState(() {
    _isLoading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Avatar Viewer'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Flutter3DViewer(
              key: ValueKey(_avatarGlbUrl), // Use ValueKey to force rebuild
              activeGestureInterceptor: true,
              progressBarColor: Colors.orange,
              enableTouch: true,
              onProgress: (double progressValue) {
                debugPrint('Model loading progress: $progressValue');
              },
              onLoad: (String modelAddress) {
                debugPrint('Model loaded: $modelAddress');
                controller.playAnimation();
              },
              onError: (String error) {
                debugPrint('Model failed to load: $error');
              },
              controller: controller,
              src: _avatarGlbUrl, // Dynamically updated URL
            ),
          ),
          _isLoading
              ? const CircularProgressIndicator()
              : _assets == null
                  ? const Text('Failed to load assets')
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _assets!.length,
                        itemBuilder: (context, index) {
                          final asset = _assets![index];
                          return ListTile(
                            leading: asset['iconUrl'] != null
                                ? Image.network(asset['iconUrl'])
                                : const Icon(Icons.image_not_supported),
                            onTap: () async {
                              await _equipAsset(asset['id']);
                            },
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}
