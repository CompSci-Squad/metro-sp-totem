import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HttpUtility {
  const HttpUtility();

  Future<String> httpPOST({
    required Map<String, String> headers,
    required List<int> payload,
  }) async {
    final baseUrl = dotenv.get("BACKEND_URL");
    var url = Uri.parse(baseUrl);
    return http
        .post(url,
            body: base64Encode(payload), // Base64 encoding the payload
            headers: headers)
        .then((value) {
      if (value.statusCode != 200) {
        print("Error: ${value.statusCode}, body: ${value.body}");
        throw Exception("POST request failed with status: ${value.statusCode}");
      }
      return value.body;
    }).onError((error, stackTrace) {
      print("HTTP POST exception: $error");
      return "";
    });
  }
}
