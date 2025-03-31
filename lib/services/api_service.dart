import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'path_provider_stub.dart'
    if (dart.library.io) 'path_provider_impl.dart';
import 'platform_stub.dart'
    if (dart.library.io) 'platform_impl.dart';

class ApiService {
  static const String baseUrl = "https://api.readyplayer.me";
  static const String apiKey = "sk_live_saHxsolaoRKE8uEKLsgo6NOwFoqlXkycNSRy";
  static const String applicationId = "6767fa278a474ff753c27a68";

  // Store userId and token in cache
  static Future<void> storeInCache(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getFromCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<String?> createAnonymousUser() async {
    final url = Uri.parse("$baseUrl/v1/users");
    final body = jsonEncode({
      "data": {"applicationId": applicationId}
    });

    final response = await http.post(
      url,
      headers: {"x-api-key": apiKey, "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final userId = data['data']['id'];
      await storeInCache('userId', userId);
      return userId;
    } else {
      print("Failed to create anonymous user: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  // Fetch token using userId
  static Future<String?> fetchToken(String userId) async {
    final url = Uri.parse("$baseUrl/v1/auth/token?userId=$userId&partner=3d-avatar-7jesrz");
    final response = await http.get(url, headers: {"x-api-key": apiKey});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['data']['token'];
      await storeInCache('token', token);
      return token;
    } else {
      print("Failed to fetch token: ${response.statusCode}");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchTemplates() async {
    final url = Uri.parse("$baseUrl/v2/avatars/templates");
    final response = await http.get(
      url,
      headers: {"x-api-key": apiKey}, // Only include x-api-key, no token
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      print("Failed to fetch templates: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  static Future<String?> assignTemplateToUser(String templateId, String userId) async {
    final url = Uri.parse("$baseUrl/v2/avatars/templates/$templateId");
    final response = await http.post(
      url,
      headers: {
        "x-api-key": apiKey,
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "data": {
          "partner": "3d-avatar-7jesrz",
          "bodyType": "fullbody",
          "userId": userId,
        }
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['id']; // Return the avatar ID
    } else {
      print("Failed to assign template: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  // Save avatar
  static Future<bool> saveAvatar(String avatarId) async {
    final url = Uri.parse("$baseUrl/v2/avatars/$avatarId");
    
    final response = await http.put(
      url,
      headers: {
        "x-api-key": apiKey,
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      print("Avatar not found: ${response.statusCode} - ${response.body}");
      return false;
    } else {
      print("Failed to save avatar: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  // Download avatar GLB file
  static Future<String?> downloadAvatarGlbFile(String avatarId) async {
    final url = Uri.parse("https://api.readyplayer.me/v2/avatars/$avatarId.glb");
    print("Downloading avatar from URL: $url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (isMobile) {
        final directoryPath = await getApplicationDocumentsDirectoryPath();
        final filePath = '$directoryPath/$avatarId.glb';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        // For web, return the URL directly
        return url.toString();
      }
    } else {
      print("Failed to download avatar: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  static Future<String?> createAvatarWithImage(String userId, String base64Image, String gender) async {
    final url = Uri.parse("https://api.readyplayer.me/v2/avatars");
    final body = jsonEncode({
      "data": {
        "userId": userId,
        "partner": "3d-avatar-7jesrz",
        "bodyType": "fullbody",
        "gender": gender,
        "assets": {"outfit": ""},
        "base64Image": base64Image,
      }
    });

    final response = await http.post(
      url,
      headers: {"x-api-key": apiKey, "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['id'];
    } else {
      print("Error creating avatar: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchAssets(String userId) async {
    final url = Uri.parse("$baseUrl/v1/assets?filter=usable-by-user-and-app&filterApplicationId=$applicationId&filterUserId=$userId");
    print("Fetching assets from URL: $url");

    final response = await http.get(
      url,
      headers: {
        "Accept": "*/*",
        "X-APP-ID": applicationId,
        "x-api-key": apiKey,
      },
    );

    print("Fetch assets response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      print("Failed to fetch assets: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  static Future<bool> equipAsset(String avatarId, String assetId) async {
    final url = Uri.parse("$baseUrl/v1/avatars/$avatarId/equip");
    final body = jsonEncode({
      "data": {
        "assetId": assetId,
      }
    });

    print("Equipping asset with URL: $url");
    print("Request body: $body");

    final response = await http.put(
      url,
      headers: {
        "x-api-key": apiKey,
        "Content-Type": "application/json",
      },
      body: body,
    );

    print("Equip asset response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      return true;
    } else {
      print("Failed to equip asset: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  static Future<String?> downloadAvatarGlb(String avatarId) async {
    final url = Uri.parse("https://api.readyplayer.me/v2/avatars/$avatarId.glb");
    print("Downloading avatar from URL: $url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (isMobile) {
        final directoryPath = await getApplicationDocumentsDirectoryPath();
        final filePath = '$directoryPath/$avatarId.glb';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        // For web, return the URL directly
        return url.toString();
      }
    } else {
      print("Failed to download avatar: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  static Future<String?> generateAvatar(String base64Image, String gender, String userId) async {
    try {
      // First, create a photo upload session
      final sessionUrl = Uri.parse("$baseUrl/v2/photos/upload-session");
      final sessionResponse = await http.post(
        sessionUrl,
        headers: {
          "x-api-key": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "data": {
            "partner": "3d-avatar-7jesrz",
            "userId": userId,
          }
        }),
      );

      if (sessionResponse.statusCode != 201) {
        throw Exception('Failed to create upload session: ${sessionResponse.statusCode}');
      }

      final sessionData = jsonDecode(sessionResponse.body);
      final String uploadUrl = sessionData['data']['uploadUrl'];
      final String photoId = sessionData['data']['id'];

      // Upload the photo
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          "Content-Type": "image/jpeg",
        },
        body: base64Decode(base64Image),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload photo: ${uploadResponse.statusCode}');
      }

      // Create avatar from the uploaded photo
      final createUrl = Uri.parse("$baseUrl/v2/avatars");
      final createResponse = await http.post(
        createUrl,
        headers: {
          "x-api-key": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "data": {
            "partner": "3d-avatar-7jesrz",
            "userId": userId,
            "photoId": photoId,
            "gender": gender,
            "bodyType": "fullbody",
            "renderOptions": {
              "background": "transparent",
              "pose": "A",
            }
          }
        }),
      );

      if (createResponse.statusCode != 201) {
        throw Exception('Failed to create avatar: ${createResponse.statusCode}');
      }

      final avatarData = jsonDecode(createResponse.body);
      return avatarData['data']['id'];
    } catch (e) {
      print('Error generating avatar: $e');
      return null;
    }
  }
}
