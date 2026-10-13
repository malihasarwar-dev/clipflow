import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../services/api_service.dart';

/// Holds the session. go_router listens to this to guard routes.
class AuthState extends ChangeNotifier {
  static const _tokenKey = 'clipflow_token';

  final ApiService api = ApiService();
  Map<String, dynamic>? user;

  bool get isAuthenticated => api.token != null && user != null;
  String get displayName => (user?['name'] as String?)?.trim().isNotEmpty == true
      ? user!['name'] as String
      : (user?['email'] as String? ?? '');

  /// Restore a saved session on app start (validates the token with /auth/me).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved == null) return;
    api.token = saved;
    try {
      user = await api.me();
    } catch (_) {
      await _clear();
    }
  }

  Future<void> _accept(Map<String, dynamic> res) async {
    api.token = res['access_token'] as String;
    user = Map<String, dynamic>.from(res['user'] as Map);
    (await SharedPreferences.getInstance()).setString(_tokenKey, api.token!);
    notifyListeners();
  }

  Future<void> _clear() async {
    api.token = null;
    user = null;
    (await SharedPreferences.getInstance()).remove(_tokenKey);
  }

  Future<void> login(String email, String password) async =>
      _accept(await api.login(email.trim(), password));

  Future<void> signup(String name, String email, String password) async =>
      _accept(await api.signup(email.trim(), password, name.trim()));

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn(
      clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
      scopes: const ['email', 'profile'],
    );
    final account = await google.signIn();
    if (account == null) throw ApiException('Google sign-in was cancelled.');
    final auth = await account.authentication;
    // The backend verifies whichever token it receives; never trust the profile sent by the client.
    await _accept(await api.google(idToken: auth.idToken, accessToken: auth.accessToken));
  }

  Future<void> logout() async {
    await _clear();
    notifyListeners();
  }
}
