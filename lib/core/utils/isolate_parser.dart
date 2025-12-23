import 'dart:convert';
import 'package:flutter/foundation.dart';

class IsolateParser {
  static Future<dynamic> parseJson(String jsonString) async {
    return compute(_decodeJson, jsonString);
  }

  static dynamic _decodeJson(String jsonString) {
    return jsonDecode(jsonString);
  }
}
