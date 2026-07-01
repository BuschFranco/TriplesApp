import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notion/notion_config.dart';
import 'notion_service.dart';
import 'notifications_service.dart';

/// Arranque/cierre AUTOMÁTICO del partido en segundo plano con alarmas exactas
/// del sistema (android_alarm_manager_plus). Android dispara los callbacks en un
/// ISOLATE DE BACKGROUND a la hora exacta aunque la app esté minimizada o
/// cerrada. El callback verifica ubicación, escribe el estado persistido (las
/// mismas claves que usa PlaySessionService), actualiza la notificación y la
/// presencia en Notion, y le avisa al isolate principal (si está vivo) para que
/// reconcilie. El isolate principal también reconcilia al volver al frente.

/// IDs de las alarmas (fijos: solo hay una permanencia / una salida a la vez).
const int kAlarmStartId = 100011;
const int kAlarmEndId = 100012;
// Alarma PERIÓDICA que vigila la batería mientras hay un partido en curso:
// despierta aunque la app esté cerrada y cierra el partido si la carga quedó
// muy baja (red de seguridad además del polling con la app viva).
const int kAlarmBatteryId = 100013;

/// Puerto para avisarle al isolate principal que reconcilie desde prefs.
const String kPlayPortName = 'oneofone_play_port';

/// userKey activo, para que el callback arme las claves namespaced igual que
/// PlaySessionService (`base::$userKey`).
const String kBgUserKey = 'play_bg_userkey';

// Claves fijas (no namespaced) con el "objetivo" de cada alarma.
const String _kAlarmStart = 'play_alarm_start';
const String _kAlarmEnd = 'play_alarm_end';

// Claves base de PlaySessionService (deben coincidir EXACTO).
const String _kActiveBase = 'play_active_session';
const String _kPendingBase = 'play_pending_result';

// Constantes espejo de PlaySessionService (mantener en sync).
const double _kRadiusMeters = 110;
const int _kMinMatchSeconds = 13 * 60;
const int _kBatteryEndPercent = 5;
const Duration _kBatteryWatchEvery = Duration(minutes: 15);

String _nsKey(String base, String uk) => uk.isEmpty ? base : '$base::$uk';

bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

// ── Programar / cancelar ────────────────────────────────────────────────────

/// Programa el arranque automático del partido para [at] en la cancha dada.
Future<void> scheduleStartAlarm({
  required String userKey,
  required String courtId,
  required String courtName,
  required double lat,
  required double lng,
  required DateTime at,
}) async {
  if (!_isAndroid) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kAlarmStart,
    jsonEncode({
      'userKey': userKey,
      'courtId': courtId,
      'courtName': courtName,
      'lat': lat,
      'lng': lng,
      'atMillis': at.millisecondsSinceEpoch,
    }),
  );
  await AndroidAlarmManager.cancel(kAlarmStartId);
  await AndroidAlarmManager.oneShotAt(
    at,
    kAlarmStartId,
    alarmStartCallback,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
    rescheduleOnReboot: true,
  );
}

Future<void> cancelStartAlarm() async {
  if (!_isAndroid) return;
  await AndroidAlarmManager.cancel(kAlarmStartId);
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kAlarmStart);
}

/// Programa el cierre automático del partido para [at] (gracia de salida).
Future<void> scheduleEndAlarm({
  required String userKey,
  required String courtId,
  required String courtName,
  required double lat,
  required double lng,
  required int startMillis,
  required DateTime at,
}) async {
  if (!_isAndroid) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kAlarmEnd,
    jsonEncode({
      'userKey': userKey,
      'courtId': courtId,
      'courtName': courtName,
      'lat': lat,
      'lng': lng,
      'startMillis': startMillis,
      'atMillis': at.millisecondsSinceEpoch,
    }),
  );
  await AndroidAlarmManager.cancel(kAlarmEndId);
  await AndroidAlarmManager.oneShotAt(
    at,
    kAlarmEndId,
    alarmEndCallback,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
    rescheduleOnReboot: true,
  );
}

Future<void> cancelEndAlarm() async {
  if (!_isAndroid) return;
  await AndroidAlarmManager.cancel(kAlarmEndId);
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kAlarmEnd);
}

/// Arranca la vigilancia periódica de batería mientras dure el partido.
Future<void> scheduleBatteryWatch() async {
  if (!_isAndroid) return;
  await AndroidAlarmManager.cancel(kAlarmBatteryId);
  await AndroidAlarmManager.periodic(
    _kBatteryWatchEvery,
    kAlarmBatteryId,
    alarmBatteryCallback,
    wakeup: true,
    allowWhileIdle: true,
    rescheduleOnReboot: false,
  );
}

Future<void> cancelBatteryWatch() async {
  if (!_isAndroid) return;
  await AndroidAlarmManager.cancel(kAlarmBatteryId);
}

// ── Callbacks (isolate de background) ────────────────────────────────────────

/// Arranca el partido si al cumplirse la permanencia seguís en la cancha.
@pragma('vm:entry-point')
Future<void> alarmStartCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getString(_kAlarmStart);
  if (raw == null) return;
  await prefs.remove(_kAlarmStart);

  Map<String, dynamic> t;
  try {
    t = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  final uk = (t['userKey'] ?? '') as String;
  final courtId = (t['courtId'] ?? '') as String;
  final courtName = (t['courtName'] ?? '') as String;
  final lat = (t['lat'] as num?)?.toDouble() ?? 0;
  final lng = (t['lng'] as num?)?.toDouble() ?? 0;
  final atMillis =
      (t['atMillis'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

  // ¿Seguís en la cancha? Best-effort: si no hay fix, arrancamos igual.
  if (await _leftArea(lat, lng)) return;

  final startIso = DateTime.fromMillisecondsSinceEpoch(atMillis).toIso8601String();
  await prefs.setString(
    _nsKey(_kActiveBase, uk),
    jsonEncode({
      'courtId': courtId,
      'courtName': courtName,
      'startMillis': atMillis,
    }),
  );

  await NotificationsService.instance.init();
  await NotificationsService.instance
      .showPlaying(courtName, DateTime.fromMillisecondsSinceEpoch(atMillis));

  await _setNotionPresence(prefs,
      playing: true, courtId: courtId, sinceIso: startIso);

  // Arrancó un partido en background → vigilamos la batería.
  await scheduleBatteryWatch();

  _pingMain();
}

/// Cierra el partido si al cumplirse la gracia seguís fuera del radio.
@pragma('vm:entry-point')
Future<void> alarmEndCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getString(_kAlarmEnd);
  if (raw == null) return;
  await prefs.remove(_kAlarmEnd);

  Map<String, dynamic> t;
  try {
    t = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  final uk = (t['userKey'] ?? '') as String;
  // La cancha/duración las toma _closeActiveToPending desde la sesión activa.
  final lat = (t['lat'] as num?)?.toDouble() ?? 0;
  final lng = (t['lng'] as num?)?.toDouble() ?? 0;

  final activeKey = _nsKey(_kActiveBase, uk);
  if (prefs.getString(activeKey) == null) return; // ya no hay partido en curso

  // ¿Volviste a la cancha? Si estás dentro, NO cerramos. Sin fix: cerramos.
  if (!await _leftArea(lat, lng)) return;

  await _closeActiveToPending(prefs, uk, lowBattery: false);
  _pingMain();
}

/// Vigilancia de batería (alarma periódica): si hay un partido en curso y la
/// carga quedó muy baja (y no está cargando), lo cierra para proteger la info.
@pragma('vm:entry-point')
Future<void> alarmBatteryCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final uk = prefs.getString(kBgUserKey) ?? '';
  if (prefs.getString(_nsKey(_kActiveBase, uk)) == null) {
    // No hay partido en curso: la vigilancia ya no hace falta.
    await cancelBatteryWatch();
    return;
  }
  try {
    final battery = Battery();
    final state = await battery.batteryState;
    if (state == BatteryState.charging || state == BatteryState.full) return;
    if (await battery.batteryLevel > _kBatteryEndPercent) return;
  } catch (_) {
    return; // sin lectura de batería: no hacemos nada
  }
  await _closeActiveToPending(prefs, uk, lowBattery: true);
  _pingMain();
}

/// Cierra el partido en curso (sesión activa → pendiente de resultado) desde el
/// isolate de background. Descarta si duró menos de [_kMinMatchSeconds].
Future<void> _closeActiveToPending(
  SharedPreferences prefs,
  String uk, {
  required bool lowBattery,
}) async {
  final activeKey = _nsKey(_kActiveBase, uk);
  final activeRaw = prefs.getString(activeKey);
  if (activeRaw == null) return;
  Map<String, dynamic> a;
  try {
    a = jsonDecode(activeRaw) as Map<String, dynamic>;
  } catch (_) {
    return;
  }
  final startMillis = (a['startMillis'] as num?)?.toInt();
  if (startMillis == null) return;
  final courtId = (a['courtId'] ?? '') as String;
  final courtName = (a['courtName'] ?? '') as String;

  final now = DateTime.now();
  final seconds = ((now.millisecondsSinceEpoch - startMillis) / 1000).round();

  await prefs.remove(activeKey);
  await cancelBatteryWatch(); // el partido cerró: no seguimos vigilando
  await _setNotionPresence(prefs, playing: false, courtId: '', sinceIso: '');
  await NotificationsService.instance.init();

  if (seconds >= _kMinMatchSeconds) {
    // Partido válido → pendiente de resultado (mismo formato que PlaySession).
    await prefs.setString(
      _nsKey(_kPendingBase, uk),
      jsonEncode({
        'courtId': courtId,
        'courtName': courtName,
        'seconds': seconds,
        'endedAt': now.millisecondsSinceEpoch,
        'result': null,
        'points': 0,
      }),
    );
    await NotificationsService.instance.show(
      lowBattery ? 'Partido terminado por batería baja' : 'Terminó tu partido',
      lowBattery
          ? 'Cerramos tu partido para proteger tu información. Abrí 1of1 para '
              'registrar el resultado.'
          : 'Abrí 1of1 para registrar el resultado.',
    );
  }
  await NotificationsService.instance.cancelSession();
}

// ── Helpers del callback ─────────────────────────────────────────────────────

/// True si hay fix GPS y estás a más de [_kRadiusMeters] del punto. Si no hay
/// fix (o no hay coords), devuelve false (asumimos que seguís ahí: best-effort).
Future<bool> _leftArea(double lat, double lng) async {
  if (lat == 0 && lng == 0) return false;
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
    final d =
        Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
    return d > _kRadiusMeters;
  } catch (_) {
    return false;
  }
}

Future<void> _setNotionPresence(
  SharedPreferences prefs, {
  required bool playing,
  required String courtId,
  required String sinceIso,
}) async {
  try {
    if (!NotionConfig.isConfigured) return;
    final profRaw = prefs.getString('session_profile');
    if (profRaw == null) return;
    final prof = jsonDecode(profRaw) as Map<String, dynamic>;
    final pageId = (prof['pageId'] ?? '') as String;
    if (pageId.isEmpty) return;
    await NotionService().updatePage(pageId, {
      'Playing': NotionService.checkbox(playing),
      'PlayingCourtId': NotionService.richText(playing ? courtId : ''),
      'PlayingSince': NotionService.date(sinceIso.isEmpty ? null : sinceIso),
    });
    // Reflejamos en el caché local para que quede consistente.
    prof['playing'] = playing;
    prof['playingCourtId'] = playing ? courtId : '';
    prof['playingSince'] = sinceIso;
    await prefs.setString('session_profile', jsonEncode(prof));
  } catch (_) {/* best-effort */}
}

void _pingMain() {
  try {
    IsolateNameServer.lookupPortByName(kPlayPortName)
        ?.send(<String, dynamic>{'action': 'reconcile'});
  } catch (_) {}
}
