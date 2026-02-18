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
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    try {
      final mergedHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

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
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          'Errore ${response.statusCode}: ${error['error'] ?? 'Sconosciuto'}');
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
      final response = await ApiClient.post(
        '/api/facebook/auth',
        {
          'access_token': accessToken,
          'user_id': userID,
        },
      );

      // Salva il JWT token in memoria o SharedPreferences
      if (response['token'] != null) {
        // TODO: Salva il token
        // await _storage.write(key: 'jwt_token', value: response['token']);
      }

      return response;
    } catch (e) {
      throw Exception('Autenticazione Facebook fallita: $e');
    }
  }

  /// Recupera le pagine Facebook dell'utente
  static Future<List<dynamic>> getUserPages(String facebookToken) async {
    try {
      final response = await ApiClient.get(
        '/api/facebook/pages',
        /* headers: {
          'X-Facebook-Token': facebookToken,
        }, */
      );

      return response['pages'] ?? [];
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
      final response = await ApiClient.post(
        '/api/facebook/post',
        {
          'page_id': pageID,
          'page_token': pageToken,
          'message': message,
        },
      );

      return response['post_id'];
    } catch (e) {
      throw Exception('Errore nella pubblicazione: $e');
    }
  }
}

/// ===================================
/// UTILIZZO NEL WIDGET
/// ===================================

/*
// Esempio: Nel widget di settings
class FacebookLoginButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // 1. Ottieni il token da Facebook SDK (flutter_facebook_sdk)
          final LoginResult result = await FacebookAuth.instance.login();
          
          if (result.status == LoginStatus.success) {
            final accessToken = result.accessToken!.token;
            
            // 2. Invia il token al backend
            final response = await FacebookAuthService.authenticateWithFacebook(
              accessToken,
              result.accessToken!.userId!,
            );
            
            if (response['valid']) {
              // 3. Utente autenticato!
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Accesso riuscito: ${response['user']['name']}')),
              );
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e')),
          );
        }
      },
      child: Text('Login con Facebook'),
    );
  }
}

// Esempio: Pubblicare un post
class PublishPostWidget extends StatefulWidget {
  @override
  State<PublishPostWidget> createState() => _PublishPostWidgetState();
}

class _PublishPostWidgetState extends State<PublishPostWidget> {
  final messageController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: messageController,
          decoration: InputDecoration(hintText: 'Scrivi il messaggio...'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _publishPost,
          child: isLoading ? CircularProgressIndicator() : Text('Pubblica'),
        ),
      ],
    );
  }

  Future<void> _publishPost() async {
    setState(() => isLoading = true);

    try {
      // TODO: Recupera pageID e pageToken dalla memoria/database
      final postId = await FacebookAuthService.postToPage(
        'PAGE_ID',
        'PAGE_TOKEN',
        messageController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post pubblicato! ID: $postId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
*/
