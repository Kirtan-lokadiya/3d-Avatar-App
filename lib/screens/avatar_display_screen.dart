import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
// import 'package:model_viewer_plus/model_viewer_plus.dart';


class AvatarDisplayScreen extends StatefulWidget {
  final String avatarGlbUrl;

  const AvatarDisplayScreen({super.key, required this.avatarGlbUrl});

  @override
  _AvatarDisplayScreenState createState() => _AvatarDisplayScreenState();
}

class _AvatarDisplayScreenState extends State<AvatarDisplayScreen> {
  Flutter3DController controller = Flutter3DController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Avatar Viewer'),
      ),
      body: Flutter3DViewer(
          //If you pass 'true' the flutter_3d_controller will add gesture interceptor layer
          //to prevent gesture recognizers from malfunctioning on iOS and some Android devices.
          // the default value is true
          activeGestureInterceptor: true,
          //If you don't pass progressBarColor, the color of defaultLoadingProgressBar will be grey.
          //You can set your custom color or use [Colors.transparent] for hiding loadingProgressBar.
          progressBarColor: Colors.orange,
          //You can disable viewer touch response by setting 'enableTouch' to 'false'
          enableTouch: true,
          //This callBack will return the loading progress value between 0 and 1.0
          onProgress: (double progressValue) {
            debugPrint('model loading progress : $progressValue');
          },
          //This callBack will call after model loaded successfully and will return model address
          onLoad: (String modelAddress) {
            debugPrint('model loaded : $modelAddress');
            controller.playAnimation();
          },
          //this callBack will call when model failed to load and will return failure error
          onError: (String error) {
            debugPrint('model failed to load : $error');
          },
          //You can have full control of 3d model animations, textures and camera
          controller: controller,
          // src:
          //     'assets/67763a6699f5420f427a5caa.glb', //3D model with different animations
          //src: 'assets/sheen_chair.glb', //3D model with different textures
           src: widget.avatarGlbUrl, // 3D model from URL
        ),
    );
  }
}
