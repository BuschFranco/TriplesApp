import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'add_court_screen.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  static const _options = [
    ('Crear pickup game', 'Organizá un partido en cualquier cancha', '🏀'),
    ('Agregar cancha', '¿Conocés una cancha que no está?', '📍'),
    ('Check-in', 'Avisá que estás jugando ahora', '✅'),
    ('Reservar cancha', 'Reservá un horario', '📅'),
  ];

  void _onTap(BuildContext context, int i) {
    if (i == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddCourtScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          for (var i = 0; i < _options.length; i++)
            GestureDetector(
              onTap: () => _onTap(context, i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0x991A2430),
                  border: Border.all(color: AppColors.white(0.06)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Text(_options[i].$3, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _options[i].$1,
                            style: AppText.archivo(size: 16, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _options[i].$2,
                            style: AppText.grotesk(size: 12, color: AppColors.white(0.55)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
