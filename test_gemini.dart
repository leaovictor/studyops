import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyDaotOP7AJ7lfnz4S0DoLnN9xZUZ9-U5Rk';

  final url1 = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=\$apiKey');
  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": "Hello"}
        ]
      }
    ]
  });

  final response1 = await http.post(url1,
      headers: {'Content-Type': 'application/json'}, body: body);
  print('v1beta gemini-1.5-flash-latest: ${response1.statusCode}');
  print('${response1.body}');

  final url2 = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\$apiKey');
  final response2 = await http.post(url2,
      headers: {'Content-Type': 'application/json'}, body: body);
  print('v1beta gemini-1.5-flash: ${response2.statusCode}');
  print('${response2.body}');

  final url3 = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\$apiKey');
  final response3 = await http.post(url3,
      headers: {'Content-Type': 'application/json'}, body: body);
  print('v1beta gemini-2.0-flash: ${response3.statusCode}');
  print('${response3.body}');
}
