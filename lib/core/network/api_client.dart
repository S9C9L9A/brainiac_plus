import 'package:http/http.dart' as http;
import 'dart:convert';

/// Cliente HTTP per comunicare con il backend Go
class ApiClient {
  static const String baseUrl = 'http://localhost:8080'; // Cambia in prod

  /// Esegue una richiesta GET
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Errore nella richiesta GET: $e');
    }
  }

  /// Esegue una richiesta POST
  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final mergedHeaders = {'Content-Type': 'application/json', ...?headers};

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: mergedHeaders,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Errore nella richiesta POST: $e');
    }
  }

  /// Maneggia la risposta HTTP
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final errorBody = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : {};
      throw Exception(
        'Errore ${response.statusCode}: ${errorBody['error'] ?? 'Sconosciuto'}',
      );
    }
  }
}

/// ===================================
/// SERVIZIO FACEBOOK
/// ===================================

class FacebookAuthService {
  /// Autentica l'utente con il token di Facebook
  static Future<Map<String, dynamic>> authenticateWithFacebook(
    String accessToken,
    String userID,
  ) async {
    try {
      final response = await ApiClient.post('/api/facebook/auth', {
        'access_token': accessToken,
        'user_id': userID,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Autenticazione Facebook fallita: $e');
    }
  }

  /// Recupera le pagine Facebook dell'utente
  static Future<List<dynamic>> getUserPages() async {
    try {
      final response = await ApiClient.get('/api/facebook/pages');

      if (response is Map && response.containsKey('pages')) {
        return response['pages'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      throw Exception('Errore nel recupero pagine: $e');
    }
  }

  /// Pubblica un post su una pagina Facebook
  static Future<String> postToPage(
    String pageID,
    String pageToken,
    String message,
  ) async {
    try {
      final response = await ApiClient.post('/api/facebook/post', {
        'page_id': pageID,
        'page_token': pageToken,
        'message': message,
      });

      return response['post_id'] as String;
    } catch (e) {
      throw Exception('Errore nella pubblicazione: $e');
    }
  }
}
