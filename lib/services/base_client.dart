import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:lf_crystal/constants/storage_function.dart';
import 'package:lf_crystal/constants/storage_key.dart';
import 'package:lf_crystal/services/app_exception.dart';

class ApiServices {
  //get request without authentication
  static Future<dynamic> getRequestWithoutAuth(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: {"Accept": "application/json", "Content-Type": "application/json"})
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } on SocketException {
      throw const SocketException("No Internet connection. Please try again");
    } on TimeoutException {
      throw TimeoutException("Request time out. Please try again");
    } on FormatException {
      throw const FormatException("Invsalid response format.");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  //post request without authentication
  static Future<dynamic> postRequestWithoutAuth(String url, Map<String, dynamic> bodyData) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              // "Accept": "application/json",
              "Content-Type": "application/json",
            },

            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } on SocketException {
      throw const SocketException("No Internet connection. Please try again");
    } on TimeoutException {
      throw TimeoutException("Request time out. Please try again");
    } on FormatException {
      throw const FormatException("Invsalid response format.");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  //get request with authentication
  static Future<dynamic> getRequestWithAuth(String url) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        "Authorization": "Bearer ${await StorageFunction.readStringData(StorageKey.token)}",
      };
      debugPrint("Headers: $headers");
      debugPrint("Url: $url");
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${StorageFunction.readStringData(StorageKey.token)}",
            },
          )
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } on SocketException {
      throw const SocketException("No Internet connection. Please try again");
    } on TimeoutException {
      throw TimeoutException("Request time out. Please try again");
    } on FormatException {
      throw const FormatException("Invsalid response format.");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  // Then use:

  //post request with authentication
  static Future<dynamic> postRequestWithAuth(String url, Map<String, dynamic> bodyData) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer ${StorageFunction.readStringData(StorageKey.token)}",
            },

            body: jsonEncode(bodyData),
          )
          .timeout(const Duration(seconds: 35));
      return _handleResponse(response);
    } on SocketException {
      throw const SocketException("No Internet connection. Please try again");
    } on TimeoutException {
      throw TimeoutException("Request time out. Please try again");
    } on FormatException {
      throw const FormatException("Invsalid response format.");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  //post multipart request with authentication
  static Future<dynamic> postMultipartRequestWithAuth({
    required String url,
    required Map<String, String> fields,
    required List<File> images,
    required String imageFieldName,
  }) async {
    try {
      final token = StorageFunction.readStringData(StorageKey.token);
      final uri = Uri.parse(url);

      var request =
          http.MultipartRequest("POST", uri)
            ..headers.addAll({"Authorization": "Bearer $token"})
            ..fields.addAll(fields);

      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();

          final multipartFile = http.MultipartFile(
            imageFieldName,
            fileStream,
            fileLength,
            filename: file.path.split('/').last,
          );

          request.files.add(multipartFile);
        }
      }

      // Send request and convert streamed response to regular response
      final streamedResponse = await request.send().timeout(const Duration(seconds: 35));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw const SocketException("No Internet connection. Please try again");
    } on TimeoutException {
      throw TimeoutException("Request time out. Please try again");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  static Future<dynamic> postSingleMultipartRequestWithAuth({
    required String url,
    required Map<String, String> fields,
    required File imagesFile,
    required String imageFieldName,
  }) async {
    try {
      final token = StorageFunction.readStringData(StorageKey.token);
      final uri = Uri.parse(url);

      var request =
          http.MultipartRequest("POST", uri)
            ..headers.addAll({"Authorization": "Bearer $token"})
            ..fields.addAll(fields);

      if (imagesFile.existsSync()) {
        final fileStream = http.ByteStream(imagesFile.openRead());
        final fileLength = await imagesFile.length();

        final multipartFile = http.MultipartFile(
          imageFieldName,
          fileStream,
          fileLength,
          filename: imagesFile.path.split('/').last,
        );

        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 35));

      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw const SocketException("No Internet connection. Please try again");
    } on TimeoutException {
      throw TimeoutException("Request time out. Please try again");
    } catch (e) {
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  static dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return jsonDecode(response.body);
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorisedException(response.body);
      case 404:
        throw NotFoundException("Resource not found");
      case 500:
      case 501:
      case 503:
        throw ServerException("Server error. Please try again later.");
      default:
        throw FetchDataException("Unexpected error occured: ${response.statusCode}");
    }
  }
}
