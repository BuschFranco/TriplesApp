import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('Crear pickup game', 'Organizá un partido en cualquier cancha', '🏀'),
      ('Agregar cancha', '¿Conocés una cancha que no está?', '📍'),
      ('Check-in', 'Avisá que estás jugando ahora', '✅'),
      ('Reservar cancha', 'Reservá un horario', '📅'),
    ];

    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 160),
        children: [
          Text(
            'Nuevo',
            style: AppText.archivo(
              size: 34,
              weight: FontWeight.w900,
              letterSpacing: -0.03,
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < options.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: i == 0
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.accent, AppColors.accentDark],
                      )
                    : null,
                color: i == 0 ? null : const Color(0x991A2430),
                border: i == 0
                    ? null
                    : Border.all(color: AppColors.white(0.06)),
                borderRadius: BorderRadius.circular(18),
                boxShadow: i == 0
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withAlpha(68),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(options[i].$3, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          options[i].$1,
                          style: AppText.archivo(
                            size: 16,
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          options[i].$2,
                          style: AppText.grotesk(
                            size: 12,
                            color: i == 0
                                ? AppColors.white(0.8)
                                : AppColors.white(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
