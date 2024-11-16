
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

//class TotemReconhecimentoFacial extends StatelessWidget {
@override
Widget build(BuildContext context) {
  if (cameraController.value.isInitialized) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Visualização da câmera, restrita ao quadrado azul
          Align(
            alignment: Alignment.center,
            child: ClipRect(
              child: Container(
                height: 300,
                width: 300,
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: CameraPreview(cameraController),
                ),
              ),
            ),
          ),
          // Sobreposição de textos, quadrado azul e botão
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50), // Ajuste o espaçamento para alinhar os elementos
              _buildTextSection(),
              SizedBox(height: 25),
              _buildBlueSquare(),
              Spacer(),
              _buildHelpButton(context),
            ],
          ),
        ],
      ),
    );
  } else {
    return const Center(
      child: CircularProgressIndicator(), // Indicador de carregamento enquanto a câmera inicializa
    );
  }
}



  Widget _buildTextSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Totem Reconhecimento Facial',
          style: TextStyle(fontSize: 20,fontFamily: 'Helvetica', fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          'Acesso Gratuito',
          style: TextStyle(fontSize: 18, fontFamily: 'Helvetica'),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          'Centralize seu rosto no retângulo\n de borda azul',
          style: TextStyle(fontSize: 16, fontFamily: 'Helvetica'),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBlueSquare() {
    return Center(
      child: Container(
        width: 300, // Largura do quadrado azul
        height: 300, // Altura do quadrado azul
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF0059FF), // Cor azul
            width: 4.0,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20), // Espaçamento inferior
      child: ElevatedButton(
        onPressed: () {
          takePicture(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red, // Cor de fundo vermelho
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Bordas arredondadas
          ),
        ),
        child: const Text(
          'Preciso de ajuda',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Helvetica',
          ),
        ),
      ),
    );
  }
}





  /*@override
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
}*/