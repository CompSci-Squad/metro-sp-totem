
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:totem/utility/http_utility.dart';
import 'package:image/image.dart' as img;


class TotemScreen1 extends StatefulWidget{
  const TotemScreen1({super.key});

  @override
  State<TotemScreen1> createState() => _TotemScreen1State();
}

class _TotemScreen1State extends State<TotemScreen1> {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  final String backendServer = dotenv.get("BACKEND_URL");
  final String backendReceiver = dotenv.get("SLA", fallback: "SLA");

  @override
  void initState() {
    startCamera();
    super.initState();
  }

  void startCamera() async{
    cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);
    await cameraController.initialize().then((value){
      if (!mounted){
        return;
      }
      setState(() {
        
      });
    }).catchError((e){
      print(e);
    });
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void showSnackBar(BuildContext context, String message, bool isSuccess) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: isSuccess ? Colors.green : Colors.red,
    duration: const Duration(seconds: 3),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

Future<XFile?> transformPicture(XFile jpeg) async {
  try {
    Uint8List value = await jpeg.readAsBytes();
    img.Image? i = img.decodeImage(value); // Use the correct decode method
    if (i != null) {
      img.Image sqr = img.copyResizeCropSquare(i, size: 512);
      Uint8List png = Uint8List.fromList(img.encodePng(sqr));
      return XFile.fromData(png, mimeType: 'image/png');
    } else {
      print("Failed to decode the image.");
      return null;
    }
  } catch (error) {
    print("Não foi possível transformar a imagem: $error");
    return null;
  }
}


  void takePicture(BuildContext context) {
  showSnackBar(context, "Enviando foto", false);
  cameraController.pausePreview();

  Future.delayed(const Duration(milliseconds: 400), () {
    cameraController.resumePreview();
  });

  cameraController.takePicture().then((raw) {
    transformPicture(raw).then((xfile) {
      if (xfile != null) {
        xfile.readAsBytes().then((bytes) async {
          HttpUtility hu = const HttpUtility();
          hu
              .httpPOST(
                //queryParams: {}, // You can add query parameters here
                payload: bytes,
                headers: {'Content-Type': 'image/png'},
              )
              .then((value) {
                showSnackBar(context, "Imagem enviada", true);
              }).onError((error, stackTrace) {
            showSnackBar(context, "Upload falhou", false);
          });
        });
      } else {
        showSnackBar(context, "Falha ao transformar a imagem", false);
      }
    });
  });
}

  @override
  Widget build(BuildContext context){
    if (cameraController.value.isInitialized){
      return Scaffold(
        body: Stack(
          children: [
            CameraPreview(cameraController),
            Align(
              alignment: Alignment.center,
              child: Container(
                height: 300,
                width: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Color(0xFF0059FF),
                ),
              ),
            ),
            const Align(
              alignment: AlignmentDirectional.topCenter,
              child: Text(
                "Totem de Reconhecimento Facial",
                style: TextStyle(
                  fontSize: 30,
                  fontFamily: 'Helvetica',
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SizedBox(
          height: 100,
          width: 100,
          child: FittedBox(
            child: FloatingActionButton(
              child: const Icon(Icons.camera_alt_outlined, size: 34),
              onPressed: (){
                takePicture(context);
              },
            ),
          ),
        ),
      );
    } else{
      return const SizedBox();
    }
  }
}