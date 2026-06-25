import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../notion/notion_config.dart';
import 'notion_service.dart';

/// Estado de sesión del usuario. Maneja signup/login/logout contra Notion
/// (auth prototipo: email + contraseña hasheada SHA-256) y persiste la
/// sesión en SharedPreferences para restaurarla al reabrir la app.
class Session extends ChangeNotifier {
  Session({NotionService? notion}) : _notion = notion ?? NotionService();

  final NotionService _notion;

  static const _kEmail = 'session_email';
  static const _kProfile = 'session_profile';

  Profile? _profile;
  String? _email;
  bool _restoring = true;

  Profile? get profile => _profile;
  String? get email => _email;
  bool get restoring => _restoring;
  bool get isLoggedIn => _profile != null;
  bool get notionReady => _notion.isConfigured;

  /// Hash prototipo (con el email como sal liviana). No es auth de producción.
  static String _hash(String email, String password) =>
      sha256.convert(utf8.encode('${email.toLowerCase()}:$password')).toString();

  /// Restaura la sesión desde el cache local (sin red).
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final em = prefs.getString(_kEmail);
    final cached = prefs.getString(_kProfile);
    if (em != null && cached != null) {
      try {
        _profile = Profile.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        _email = em;
      } catch (_) {/* cache corrupto: ignorar */}
    }
    _restoring = false;
    notifyListeners();
  }

  /// Devuelve null si OK, o un mensaje de error.
  Future<String?> login(String emailRaw, String password) async {
    if (!_notion.isConfigured) {
      return 'Notion no está configurado (falta el token).';
    }
    final email = emailRaw.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty) return 'Completá email y contraseña.';
    try {
      final rows = await _notion.queryDatabase(
        NotionConfig.dbUsers,
        filter: NotionService.filterTitle('Email', email),
      );
      if (rows.isEmpty) return 'No existe una cuenta con ese email.';
      final user = AppUser.fromNotion(rows.first);
      if (user.passwordHash != _hash(email, password)) {
        return 'Contraseña incorrecta.';
      }
      final profilePage = await _notion.retrievePage(user.profileId);
      await _persist(email, Profile.fromNotion(profilePage));
      return null;
    } on NotionException catch (e) {
      return 'Error conectando con Notion (${e.statusCode}).';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<String?> signup({
    required String emailRaw,
    required String password,
    required String name,
    String city = '',
    String phone = '',
  }) async {
    if (!_notion.isConfigured) {
      return 'Notion no está configurado (falta el token).';
    }
    final email = emailRaw.trim().toLowerCase();
    if (email.isEmpty || password.isEmpty || name.trim().isEmpty) {
      return 'Completá nombre, email y contraseña.';
    }
    if (password.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
    try {
      final existing = await _notion.queryDatabase(
        NotionConfig.dbUsers,
        filter: NotionService.filterTitle('Email', email),
      );
      if (existing.isNotEmpty) return 'Ya existe una cuenta con ese email.';

      final handle = '@${name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '.')}';
      final newProfile = Profile(
        name: name.trim(),
        handle: handle,
        city: city.trim(),
        phone: phone.trim(),
        userEmail: email,
      );
      final profilePage = await _notion.createPage(
        NotionConfig.dbProfiles,
        newProfile.toNotionProperties(),
      );
      final profileId = profilePage['id']?.toString() ?? '';

      await _notion.createPage(NotionConfig.dbUsers, {
        'Email': NotionService.title(email),
        'PasswordHash': NotionService.richText(_hash(email, password)),
        'ProfileId': NotionService.richText(profileId),
        'CreatedAt': NotionService.date(DateTime.now().toIso8601String()),
      });

      await _persist(email, Profile.fromNotion(profilePage));
      return null;
    } on NotionException catch (e) {
      return 'Error conectando con Notion (${e.statusCode}).';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmail);
    await prefs.remove(_kProfile);
    _profile = null;
    _email = null;
    notifyListeners();
  }

  Future<void> _persist(String email, Profile prof) async {
    _email = email;
    _profile = prof;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kProfile, jsonEncode(prof.toJson()));
    notifyListeners();
  }
}
