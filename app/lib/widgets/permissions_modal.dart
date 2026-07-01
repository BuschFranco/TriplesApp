import 'package:flutter/material.dart';
import '../services/app_permissions.dart';
import '../theme/app_theme.dart';

/// Modal que aparece sobre el mapa cuando faltan permisos clave (ubicación,
/// notificaciones, alarmas exactas). Explica para qué sirve cada uno y ofrece
/// un botón para activarlo. Se auto-refresca al volver de los ajustes y se
/// cierra solo cuando están todos concedidos.
class PermissionsModal extends StatefulWidget {
  const PermissionsModal({super.key});

  /// Muestra el modal si falta algún permiso. Devuelve cuando se cierra.
  static Future<void> showIfNeeded(BuildContext context) async {
    final state = await checkPermissions();
    if (state.allGranted || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PermissionsModal(),
    );
  }

  @override
  State<PermissionsModal> createState() => _PermissionsModalState();
}

class _PermissionsModalState extends State<PermissionsModal>
    with WidgetsBindingObserver {
  PermState? _state;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // Al volver de los ajustes del sistema, re-chequeamos.
    if (s == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final st = await checkPermissions();
    if (!mounted) return;
    setState(() => _state = st);
    // Si ya están todos, cerramos el modal.
    if (st.allGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  Future<void> _activate(AppPerm p) async {
    if (_busy) return;
    setState(() => _busy = true);
    await requestPerm(p);
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  static const _meta = {
    AppPerm.location: (
      Icons.location_on_outlined,
      'Ubicación',
      'Detecta las canchas cercanas, te ubica en el mapa y cuenta tu partido.',
    ),
    AppPerm.notifications: (
      Icons.notifications_active_outlined,
      'Notificaciones',
      'Te avisa cuándo arranca y cuándo termina tu partido.',
    ),
    AppPerm.alarm: (
      Icons.alarm,
      'Alarmas exactas',
      'Arranca y cierra tu partido solo, aunque tengas la app cerrada.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final st = _state;
    return AlertDialog(
      backgroundColor: AppColors.bgElev,
      scrollable: true,
      title: Text('Permisos necesarios',
          style: AppText.archivo(size: 18, weight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para que 1of1 detecte y registre tus partidos correctamente, '
            'necesita estos permisos:',
            style: AppText.grotesk(size: 12, color: AppColors.white(0.6)),
          ),
          const SizedBox(height: 12),
          if (st == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                ),
              ),
            )
          else
            for (final p in AppPerm.values) _row(p, !st.missing.contains(p)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text('Ahora no',
              style: AppText.grotesk(size: 13, color: AppColors.white(0.6))),
        ),
      ],
    );
  }

  Widget _row(AppPerm p, bool granted) {
    final (icon, title, why) = _meta[p]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 22,
              color: granted ? AppColors.open : AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        AppText.grotesk(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(why,
                    style: AppText.grotesk(
                        size: 11, color: AppColors.white(0.5))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ON solo si el permiso está concedido. Si está OFF, activarlo dispara
          // la solicitud del permiso; ya concedido, queda fijo en ON.
          Switch(
            value: granted,
            onChanged: (granted || _busy) ? null : (_) => _activate(p),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
