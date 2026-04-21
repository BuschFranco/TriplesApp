# TRIPLES ∆

> **Encontrá tu próxima cancha** — Descubrí, reservá y jugá en las mejores canchas cerca tuyo. Conectá con ballers de tu zona.

App de Flutter para descubrir canchas de básquet en Argentina. Prototipo UI completo con diseño glassmorphism oscuro.

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.11+ / Dart 3.11+ |
| UI | Material 3 + Custom Painters |
| Tipografía | Google Fonts — Archivo (headlines) + Space Grotesk (body) |
| Tema | Dark navy `#0A0F14` + Accent naranja `#FF6B1A` |
| Estado actual | `setState` — sin backend ni persistencia |

---

## Estructura del proyecto

```
lib/
├── data/
│   └── courts.dart          # Modelos: Court, Player, PlayerBadge, RecentGame + datos mock
├── screens/
│   ├── main_shell.dart      # Contenedor de navegación (5 tabs)
│   ├── onboarding_screen.dart
│   ├── home_screen.dart     # Mapa + swipe cards
│   ├── list_screen.dart     # Lista rankeada de canchas
│   ├── detail_screen.dart   # Detalle de cancha
│   ├── filters_screen.dart  # Filtros avanzados
│   ├── create_screen.dart   # Crear partida / check-in / reserva
│   ├── crew_screen.dart     # Grupos de chat
│   └── profile_screen.dart  # Perfil de usuario
├── theme/
│   └── app_theme.dart       # AppColors + AppText
└── widgets/
    ├── app_tab_bar.dart
    ├── glass_card.dart
    ├── app_chip.dart
    ├── bball_glyph.dart
    ├── rating_badge.dart
    ├── status_dot.dart
    └── section_title.dart
```

---

## Pantallas implementadas

| Pantalla | Estado | Descripción |
|----------|--------|-------------|
| Onboarding | ✅ UI completa | Splash con stats, headline y CTA |
| Home (Mapa) | ✅ UI completa | Mapa decorativo con pins, cards deslizables, buscador |
| Lista | ✅ UI completa | Canchas rankeadas con sorting (cercanía, rating, actividad) |
| Detalle | ✅ UI completa | Hero image, amenities, gráfico de actividad, jugadores |
| Filtros | ✅ UI completa | Tipo, precio, superficie, comodidades, vibe, distancia |
| Crear | ✅ UI completa | 4 acciones: crear partida, agregar cancha, check-in, reservar |
| Crew (Chat) | ✅ UI completa | Lista de grupos activos con preview de mensajes |
| Perfil | ✅ UI completa | Stats, badges, historial de partidas |

---

## Pendientes de desarrollo

### Prioridad alta — Funcionalidad core

- [ ] **Autenticación de usuarios**
  - Registro/login con email + contraseña
  - OAuth con Google / Apple ID
  - Persistencia de sesión (token storage)
  - Pantalla de login separada del onboarding actual

- [ ] **Backend y API REST**
  - Definir API (Firebase / Supabase / propio)
  - Endpoints: canchas, usuarios, partidas, check-ins, reservas
  - Agregar `dio` o `http` al proyecto
  - Capa de repositorios (separar data de UI)

- [ ] **Mapa real con Google Maps / Mapbox**
  - Reemplazar el `CustomPainter` decorativo actual por mapa interactivo
  - Pins custom con el estilo de diseño actual (naranja sobre dark)
  - Geolocalización del usuario en tiempo real
  - Integración `geolocator` + `google_maps_flutter`

- [ ] **Sistema de canchas real**
  - CRUD completo: agregar, editar, reportar canchas
  - Geolocalización con coordenadas lat/lng en el modelo `Court`
  - Fotos reales (upload + CDN) — reemplazar URLs de Unsplash hardcodeadas
  - Validación y moderación de canchas nuevas

- [ ] **Gestión de estado**
  - Migrar de `setState` a Riverpod (recomendado) o Bloc
  - Estado global: usuario autenticado, filtros activos, cancha seleccionada
  - Caché de datos con invalidación

---

### Prioridad media — Features incompletos

- [ ] **Filtros funcionales**
  - Conectar la UI de `filters_screen.dart` con la lista real de canchas
  - Filtrado en tiempo real: tipo, precio, superficie, vibe, distancia
  - Persistir filtros activos entre navegaciones

- [ ] **Búsqueda funcional**
  - El campo de búsqueda en Home y List actualmente no filtra nada
  - Búsqueda por nombre de cancha, barrio, zona
  - Resultados en tiempo real con debounce

- [ ] **Sistema de partidas**
  - Crear partida con fecha, hora, cantidad de jugadores
  - Unirse a partida (botón "Unirse al juego" tiene `onPressed: () {}` vacío)
  - Estado en tiempo real: lugares disponibles, confirmados
  - Notificaciones push cuando una partida arranca

- [ ] **Reservas de cancha**
  - Calendario de disponibilidad por cancha
  - Flujo de reserva: seleccionar horario → confirmar → pago (si aplica)
  - Historial de reservas en el perfil

- [ ] **Check-in en canchas**
  - Registrar presencia en una cancha en tiempo real
  - Actualizar estado de la cancha (open → busy → closed) automáticamente
  - Contador de jugadores activos visible en el mapa

- [ ] **Sistema de chat (Crew)**
  - La pantalla `crew_screen.dart` es estática — necesita mensajería real
  - Grupos por partida / por cancha
  - Chat individual entre jugadores
  - WebSocket o Firebase Realtime Database

- [ ] **Perfil de usuario completo**
  - Editar perfil: nombre, posición, ciudad, foto
  - Sistema de badges reales (calculados por actividad)
  - Estadísticas reales desde backend
  - Historial de partidas jugadas

---

### Prioridad baja — Pulido y extra

- [ ] **Sistema de ratings y reseñas**
  - Calificar canchas después de jugar (1–5 estrellas)
  - Reseñas de texto con moderación
  - Actualmente el campo `rating` y `reviews` en `Court` son hardcodeados

- [ ] **Notificaciones push**
  - `firebase_messaging` o equivalente
  - Alertas: partida próxima, mensaje nuevo en crew, check-in confirmado
  - Configuración de preferencias en perfil

- [ ] **Modo offline / caché**
  - Guardar canchas visitadas recientemente (Hive o SQLite)
  - Indicador de conectividad
  - Sincronización cuando vuelve la conexión

- [ ] **Assets locales**
  - Mover fuentes a assets locales (actualmente Google Fonts descarga en runtime)
  - Ícono de app personalizado con el ∆ glyph
  - Splash screen nativo (no la pantalla de onboarding actual)

- [ ] **Testing**
  - La carpeta `test/` está vacía — agregar widget tests y unit tests
  - Tests de integración para flujos críticos (login, buscar cancha, unirse a partida)

- [ ] **Internacionalización**
  - La app está en español (Argentina) — evaluar soporte multilenguaje si escala
  - Formateo de fechas y distancias por locale

---

## Cómo correr el proyecto

```bash
flutter pub get
flutter run
```

Requiere Flutter 3.11+ y Dart 3.11+.

> **Nota:** La app usa datos completamente hardcodeados en `lib/data/courts.dart`. No requiere configuración de backend para correr el prototipo UI.
