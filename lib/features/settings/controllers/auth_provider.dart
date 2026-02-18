import 'package:flutter/material.dart';
import '../controllers/auth_service.dart';

/// State per gestire l'autenticazione
class AuthProvider extends ChangeNotifier {
  // Stati privati
  String? _jwtToken;
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getter pubblici
  String? get jwtToken => _jwtToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Login con Facebook
  Future<bool> loginWithFacebook({
    required String accessToken,
    required String userID,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.loginWithFacebook(
        accessToken: accessToken,
        userID: userID,
      );

      if (result['success'] == true) {
        _jwtToken = result['token'];
        _currentUser = result['user'];
        _isAuthenticated = true;
        
        print('✅ Autenticato: ${_currentUser?['name']}');
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Errore di autenticazione';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Errore: $e';
      print('❌ Errore login: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  void logout() {
    _jwtToken = null;
    _currentUser = null;
    _isAuthenticated = false;
    _errorMessage = null;
    print('👋 Logout effettuato');
    notifyListeners();
  }

  /// Recupera pagine Facebook
  Future<List<dynamic>> getPages(String facebookToken) async {
    return await AuthService.getUserPages(facebookToken);
  }

  /// Pubblica un post
  Future<bool> publishPost({
    required String pageID,
    required String pageToken,
    required String message,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final postId = await AuthService.publishPost(
        pageID: pageID,
        pageToken: pageToken,
        message: message,
      );

      _isLoading = false;
      notifyListeners();
      
      return postId != null;
    } catch (e) {
      _errorMessage = 'Errore nella pubblicazione: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
