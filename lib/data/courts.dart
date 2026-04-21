enum CourtStatus { open, busy, closed }

class Court {
  final String id;
  final String name;
  final String area;
  final String dist;
  final String img;
  final double rating;
  final int reviews;
  final String type;
  final bool free;
  final bool lit;
  final int hoops;
  final String surface;
  final CourtStatus status;
  final int players;
  final String vibe;
  final String hours;
  final List<String> badges;
  final String desc;
  final double lat;
  final double lng;

  const Court({
    required this.id,
    required this.name,
    required this.area,
    required this.dist,
    required this.img,
    required this.rating,
    required this.reviews,
    required this.type,
    required this.free,
    required this.lit,
    required this.hoops,
    required this.surface,
    required this.status,
    required this.players,
    required this.vibe,
    required this.hours,
    required this.badges,
    required this.desc,
    required this.lat,
    required this.lng,
  });
}

const List<Court> kCourts = [
  Court(
    id: 'parq-lez',
    name: 'Parque Lezama',
    area: 'San Telmo',
    dist: '0.4 km',
    img: 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&q=80',
    rating: 4.8,
    reviews: 142,
    type: 'Exterior',
    free: true,
    lit: true,
    hoops: 4,
    surface: 'Asfalto',
    status: CourtStatus.open,
    players: 8,
    vibe: 'Competitivo',
    hours: '06:00 — 23:00',
    badges: ['Iluminada', 'Gratis', 'Popular'],
    desc: 'Cancha clásica del barrio con buena iluminación nocturna. Se arman pickups todos los martes y jueves.',
    lat: -34.6278,
    lng: -58.3694,
  ),
  Court(
    id: 'poly-nort',
    name: 'Polideportivo Norte',
    area: 'Belgrano',
    dist: '1.2 km',
    img: 'https://images.unsplash.com/photo-1504450758481-7338eba7524a?w=800&q=80',
    rating: 4.9,
    reviews: 389,
    type: 'Interior',
    free: false,
    lit: true,
    hoops: 2,
    surface: 'Parquet',
    status: CourtStatus.open,
    players: 12,
    vibe: 'Entrenamiento',
    hours: '07:00 — 22:00',
    badges: ['Parquet', 'Reserva', 'Vestuarios'],
    desc: 'Cancha reglamentaria FIBA con parquet profesional. Se alquila por hora con reserva previa.',
    lat: -34.5668,
    lng: -58.4593,
  ),
  Court(
    id: 'plaza-arm',
    name: 'Plaza Armenia',
    area: 'Palermo',
    dist: '2.1 km',
    img: 'https://images.unsplash.com/photo-1577416412292-747c6607f055?w=800&q=80',
    rating: 4.5,
    reviews: 87,
    type: 'Exterior',
    free: true,
    lit: false,
    hoops: 2,
    surface: 'Cemento',
    status: CourtStatus.open,
    players: 5,
    vibe: 'Casual',
    hours: 'Abierto 24h',
    badges: ['Gratis', 'Casual'],
    desc: 'Ambiente relajado, ideal para tirar un rato. Sin luces, se juega hasta el atardecer.',
    lat: -34.5888,
    lng: -58.4325,
  ),
  Court(
    id: 'club-river',
    name: 'Club Atletico River',
    area: 'Núñez',
    dist: '3.8 km',
    img: 'https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?w=800&q=80',
    rating: 4.7,
    reviews: 231,
    type: 'Interior',
    free: false,
    lit: true,
    hoops: 6,
    surface: 'Parquet',
    status: CourtStatus.busy,
    players: 24,
    vibe: 'Profesional',
    hours: '08:00 — 23:00',
    badges: ['Profesional', 'Parquet', 'Torneos'],
    desc: 'Complejo con 3 canchas. Liga interna los fines de semana.',
    lat: -34.5453,
    lng: -58.4512,
  ),
  Court(
    id: 'patio-bom',
    name: 'Patio Bombonera',
    area: 'La Boca',
    dist: '4.5 km',
    img: 'https://images.unsplash.com/photo-1520975916090-3105956dac38?w=800&q=80',
    rating: 4.3,
    reviews: 54,
    type: 'Exterior',
    free: true,
    lit: true,
    hoops: 2,
    surface: 'Asfalto',
    status: CourtStatus.open,
    players: 3,
    vibe: 'Callejero',
    hours: '06:00 — 00:00',
    badges: ['Street', 'Gratis', 'Iluminada'],
    desc: 'Streetball puro. Asfalto gastado con historia.',
    lat: -34.6353,
    lng: -58.3706,
  ),
];

class PlayerBadge {
  final String name;
  final String icon;
  const PlayerBadge(this.name, this.icon);
}

class RecentGame {
  final String court;
  final String date;
  final int points;
  const RecentGame(this.court, this.date, this.points);
}

class Player {
  final String name;
  final String handle;
  final String pos;
  final String city;
  final String avatar;
  final int games;
  final int courts;
  final int streak;
  final double rating;
  final List<PlayerBadge> badges;
  final List<RecentGame> recent;

  const Player({
    required this.name,
    required this.handle,
    required this.pos,
    required this.city,
    required this.avatar,
    required this.games,
    required this.courts,
    required this.streak,
    required this.rating,
    required this.badges,
    required this.recent,
  });
}

const Player kPlayer = Player(
  name: 'Mateo Rivera',
  handle: '@mateo.r',
  pos: 'Base · 1.82m',
  city: 'Buenos Aires',
  avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80',
  games: 47,
  courts: 12,
  streak: 8,
  rating: 4.6,
  badges: [
    PlayerBadge('Triples x100', '🎯'),
    PlayerBadge('Early Bird', '🌅'),
    PlayerBadge('Regular', '🔥'),
  ],
  recent: [
    RecentGame('Parque Lezama', 'Hoy', 22),
    RecentGame('Polideportivo Norte', 'Ayer', 18),
    RecentGame('Plaza Armenia', 'Sáb', 15),
  ],
);
