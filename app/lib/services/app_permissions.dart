import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'notifications_service.dart';

/// Permisos que la app necesita para funcionar bien.
enum AppPerm { location, notifications, alarm }

/// Canal nativo para consultar/abrir el permiso de alarmas exactas (Android 12+).
const MethodChannel _alarmChannel = MethodChannel('oneofone/alarm_perm');

/// Estado de los permisos clave.
class PermState {
  final bool location; // permiso concedido Y servicio de ubicación encendido
  final bool notifications;
  final bool alarm; // puede programar alarmas exactas

  const PermState({
    required this.location,
    required this.notifications,
    required this.alarm,
  });

  bool get allGranted => location && notifications && alarm;

  List<AppPerm> get missing => [
        if (!location) AppPerm.location,
        if (!notifications) AppPerm.notifications,
        if (!alarm) AppPerm.alarm,
      ];
}

Future<bool> _canScheduleExact() async {
  try {
    return (await _alarmChannel.invokeMethod<bool>('canScheduleExact')) ?? true;
  } catch (_) {
    return true; // sin canal (iOS/otros): no bloqueamos por esto
  }
}

/// Revisa el estado actual de los permisos.
Future<PermState> checkPermissions() async {
  var loc = false;
  try {
    final perm = await Geolocator.checkPermission();
    final service = await Geolocator.isLocationServiceEnabled();
    loc = service &&
        (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse);
  } catch (_) {}
  final notif = await NotificationsService.instance.isEnabled();
  final alarm = await _canScheduleExact();
  return PermState(location: loc, notifications: notif, alarm: alarm);
}

/// Pide (o guía a activar) la ubicación. Si el servicio está apagado abre sus
/// ajustes; si el permiso quedó denegado permanentemente, abre los ajustes de
/// la app.
Future<void> requestLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  } catch (_) {}
}

/// Pide las notificaciones; si ya estaban denegadas, abre los ajustes de la app.
Future<void> requestNotifications() async {
  await NotificationsService.instance.requestPermission();
  if (!await NotificationsService.instance.isEnabled()) {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }
}

/// Abre la pantalla del sistema para conceder alarmas exactas.
Future<void> requestAlarm() async {
  try {
    await _alarmChannel.invokeMethod('openExactSettings');
  } catch (_) {}
}

/// Dispara la acción de activación del permiso dado.
Future<void> requestPerm(AppPerm p) async {
  switch (p) {
    case AppPerm.location:
      await requestLocation();
      break;
    case AppPerm.notifications:
      await requestNotifications();
      break;
    case AppPerm.alarm:
      await requestAlarm();
      break;
  }
}
