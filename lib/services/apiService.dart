import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<Map<String, dynamic>> sendImage({
    required String url,
    required File file,
    required String fileFieldName,
    Map<String, String>? headers,
  }) async {
    Uri uri = Uri.parse('$baseUrl$url');
    headers ??= {};

    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath(fileFieldName, file.path));
  
    request.headers.addAll(headers);

    try {
      var response = await request.send();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        throw Exception('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }
}

String apiUrl = dotenv.env['BASE_API_URL'] ?? 'Default API URL';

ApiService apiService = ApiService(baseUrl: apiUrl);