import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:face_camera/face_camera.dart';
import './services/apiService.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  await FaceCamera.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _capturedImage;

  late FaceCameraController controller;
  
  Future<void> _verifyInAi(File? image) async {
    try {
      print(_capturedImage);
      final faceData = await apiService.sendImage(
          url: '/ai', fileFieldName: 'file', file: image!);
      if (faceData["recognized"]) {
        // Do something with the face data
        print('Face verified successfully');
      } else {
        print('Failed to verify face');
      }
    } catch (e) {
      print('Error verifying face: $e');
    }
  }

  @override
  void initState() {
    controller = FaceCameraController(
      autoCapture: true,
      defaultCameraLens: CameraLens.front,
      onCapture: (File? image) async {
        print(image);
        setState(() => _capturedImage = image);
        print(_capturedImage);
        await _verifyInAi(image);
      },
      onFaceDetected: (Face? face) {
        
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Totem de Reconhecimento Facial \nAcesso Gratuito', textAlign: TextAlign.center,),
            centerTitle: true,
          ),
          body: Builder(builder: (context) {
            if (_capturedImage != null) {
              return Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.file(
                      _capturedImage!,
                      width: double.maxFinite,
                      fit: BoxFit.fitWidth,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          await controller.startImageStream();
                          setState(() => _capturedImage = null);
                        },
                        child: const Text(
                          'Capture Again',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ))
                  ],
                ),
              );
            }
            return SmartFaceCamera(
                controller: controller,
                messageBuilder: (context, face) {
                  if (face == null) {
                    return _message('Posicione seu rosto na câmera');
                  }
                  if (!face.wellPositioned) {
                    return _message('Centralize seu rosto no quadrado');
                  }
                  return const SizedBox.shrink();
                });
          })),
    );
  }

  Widget _message(String msg, {Color color = Colors.white}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color,fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
