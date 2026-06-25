# TriplesApp

App mobile (Flutter) para descubrir canchas de básquet en un mapa, ver
detalles, dejar reseñas, organizar pickups y conectar con otros jugadores.

> Estado: prototipo funcional con backend de datos sobre **Notion**.

---

## Funcionalidades

- **Mapa de canchas** con marcadores, búsqueda de barrios (Google Places) y
  tarjeta deslizable por cancha.
- **Listado** de canchas con orden por cercanía, rating o actividad.
- **Detalle de cancha**: fotos, amenities, horarios, reseñas y "jugando ahora".
- **Agregar cancha** (con ubicación en mapa e imagen por URL) → entra a
  **moderación** (estados: Sin definir / Aprobado / Desaprobado). Solo las
  aprobadas se muestran.
- **Reseñas** por cancha (rating + comentario).
- **Pickups**: organizar partidos (cancha, fecha, jugadores, notas).
- **Favoritos** (guardados localmente en el dispositivo).
- **Perfil** con datos del usuario + pestaña **Amigos** (buscar por handle y
  agregar sin necesidad de aceptación).
- **Login / registro** en la primera pantalla, con sesión persistente.

---

## Stack y arquitectura

- **Flutter** (Dart) — Android (mobile). iOS preparado pero no compilado.
- **Estado**: `provider` (`Session`, `CourtsProvider`, `FavoritesProvider`).
- **Base de datos**: **Notion** vía su API REST (`http`). Cada tabla es una
  database de Notion. La app degrada a datos mock locales si no hay token.
- **Mapas**: `google_maps_flutter` + `geolocator`.
- **Persistencia local**: `shared_preferences` (sesión, favoritos, onboarding).
- **Hashing de contraseñas**: `crypto` (SHA-256). *Auth de tipo prototipo, no
  apta para producción.*

### Bases de datos en Notion

| Base | Para qué |
|------|----------|
| **Usuarios** | Credenciales (email + hash) |
| **Perfiles** | Info pública del jugador (nombre, handle, ciudad, etc.) |
| **Canchas** | Canchas + estado de moderación (`Aprobacion`) y coordenadas |
| **Reseñas** | Reseñas por cancha |
| **Partidos** | Pickups / partidos |
| **Amistades** | Relaciones de amistad (unidireccionales) |

La ubicación de cada cancha se guarda **por coordenadas** (`Lat` / `Lng`) y se
renderiza como marcador en el mapa.

### Estructura del proyecto

```
lib/
├── main.dart                 # Arranque: onboarding → auth → app
├── data/
│   ├── courts.dart           # Modelo Court + mock + mapeo Notion
│   └── models.dart           # AppUser, Profile, Review, Pickup, Friend
├── notion/
│   └── notion_config.dart    # Token + IDs de las databases
├── services/
│   ├── notion_service.dart   # Cliente REST de Notion
│   ├── session.dart          # Auth + sesión (ChangeNotifier)
│   ├── courts_provider.dart  # Carga de canchas (Notion / fallback)
│   ├── favorites_provider.dart
│   └── friends_service.dart
├── screens/                  # Pantallas (home, list, detail, auth, profile, …)
├── widgets/                  # Componentes reutilizables
└── theme/app_theme.dart      # Colores y tipografías
```

---

## Cómo correrlo

### Requisitos
- Flutter SDK
- Android SDK + un dispositivo Android (físico o emulador)
- Una API key de **Google Maps** y un **token de integración de Notion**

> Importante: usar una ruta **sin acentos ni espacios** (ej. `F:\dev\TriplesApp`).
> Las herramientas nativas de Android en Windows fallan con caracteres no-ASCII.

### 1. Configurar secretos

Crear `dart_defines.json` en la raíz (está en `.gitignore`):

```json
{
  "MAPS_API_KEY": "tu_google_maps_key",
  "NOTION_TOKEN": "tu_notion_internal_integration_secret"
}
```

Los IDs de las databases de Notion tienen default en
[`lib/notion/notion_config.dart`](lib/notion/notion_config.dart) y se pueden
sobreescribir por `--dart-define` si hace falta.

> Para Notion: crear una *internal integration* en
> https://www.notion.so/my-integrations y compartir la página que contiene las
> databases con esa integración.

### 2. Instalar dependencias y correr

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

---

## Notas de seguridad

- `dart_defines.json`, `.env` y `ios/Flutter/APIKeys.xcconfig` están en
  `.gitignore` — **nunca** se versionan.
- El login es prototipo (contraseñas hasheadas pero sin servidor). Para
  producción se migraría a un proveedor real (Firebase Auth / Supabase).

---

## En construcción

Secciones maquetadas pero todavía sin backend: **Check-in**, **Reservar cancha**
y el **chat de Crew** (aparecen marcadas dentro de la app).
