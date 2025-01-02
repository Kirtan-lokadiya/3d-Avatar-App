import 'package:flutter/material.dart';
import 'upload_convert_screen.dart';

class AvatarSelectionScreen extends StatelessWidget {
  const AvatarSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Avatar Template'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose an option:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadConvertScreen(isTemplate: true)),
                );
              },
              child: const Text('Select from Ready Templates'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadConvertScreen(isTemplate: false)),
                );
              },
              child: const Text('Upload Your Photo'),
            ),
          ],
        ),
      ),
    );
  }
}
