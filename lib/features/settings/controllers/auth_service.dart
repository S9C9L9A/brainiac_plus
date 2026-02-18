import '../../../core/network/api_client.dart';

/// Servizio di autenticazione con Facebook via backend Go
class AuthService {
  /// Autentica l'utente con Facebook
  static Future<Map<String, dynamic>> loginWithFacebook({
    required String accessToken,
    required String userID,
  }) async {
    try {
      print('🔐 Autenticazione con backend...');
      
      final response = await FacebookAuthService.authenticateWithFacebook(
        accessToken,
        userID,
      );

      if (response['valid'] == true) {
        print('✅ Autenticazione riuscita!');
        print('📦 Utente: ${response['user']['name']}');
        
        // Salva i dati localmente (TODO: implementare con secure_storage)
        // await _storage.write(
        //   key: _jwtTokenKey,
        //   value: response['token'],
        // );
        
        return {
          'success': true,
          'user': response['user'],
          'token': response['token'],
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Autenticazione fallita',
        };
      }
    } catch (e) {
      print('❌ Errore: $e');
      return {
        'success': false,
        'message': 'Errore durante l\'autenticazione: $e',
      };
    }
  }

  /// Recupera le pagine Facebook dell'utente
  static Future<List<dynamic>> getUserPages(String facebookToken) async {
    try {
      return await FacebookAuthService.getUserPages(facebookToken);
    } catch (e) {
      print('❌ Errore nel recupero pagine: $e');
      return [];
    }
  }

  /// Pubblica un post su una pagina
  static Future<String?> publishPost({
    required String pageID,
    required String pageToken,
    required String message,
  }) async {
    try {
      return await FacebookAuthService.postToPage(
        pageID,
        pageToken,
        message,
      );
    } catch (e) {
      print('❌ Errore nella pubblicazione: $e');
      return null;
    }
  }
}
