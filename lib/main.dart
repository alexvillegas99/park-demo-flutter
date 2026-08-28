// Expo Feria Mushuc Runa — App demo (Flutter)
// Rediseño: sistema visual verde (Home/Agenda/Perfil), gastronomía dark,
// mapa Mapbox satelital con puck GPS. Cards con foto real, ratings,
// calendario timeline y bottom nav de 5 tabs.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MushucRunaApp());
}

// ═══════════════════════════════════════════════════════════════════════════
// TEMA — Verde principal + accents (base imagen 2)
// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  static const primary = Color(0xFF7A1315);
  static const primaryDk = Color(0xFF9A1B1E);
  static const primaryDeep = Color(0xFF56090B);
  static const primarySoft = Color(0xFFFBEED3);
  static const gold = Color(0xFFE2B563);
  static const goldDk = Color(0xFFC08A3E);
  static const coral = Color(0xFFB24A22);
  static const orange = Color(0xFFD97B2B);
  static const yellow = gold;
  static const ink = Color(0xFF33201A);
  static const inkSoft = Color(0xFF8A6F5E);
  static const line = Color(0xFFF0E4CC);
  static const surface = Color(0xFFFAF3E6);
  static const cardBg = Color(0xFFFFFFFF);
  static const mapGreen = Color(0xFF2F6B2B);
}

class MushucRunaApp extends StatelessWidget {
  const MushucRunaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expo Feria Mushuc Runa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        fontFamily: 'System',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: AppColors.ink,
          ),
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: AppColors.ink,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
          bodyMedium: TextStyle(color: AppColors.ink),
        ),
      ),
      home: const RootShell(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELO
// ═══════════════════════════════════════════════════════════════════════════
enum PoiCategory { event, livestock, autos, food, artisan, service }

extension PoiCategoryX on PoiCategory {
  String get label => switch (this) {
    PoiCategory.event => 'Eventos',
    PoiCategory.livestock => 'Ganadería',
    PoiCategory.autos => 'Expo Autos',
    PoiCategory.food => 'Gastronomía',
    PoiCategory.artisan => 'Artesanías',
    PoiCategory.service => 'Servicios',
  };
  IconData get icon => switch (this) {
    PoiCategory.event => Icons.music_note_rounded,
    PoiCategory.livestock => Icons.pets_rounded,
    PoiCategory.autos => Icons.directions_car_rounded,
    PoiCategory.food => Icons.restaurant_rounded,
    PoiCategory.artisan => Icons.palette_rounded,
    PoiCategory.service => Icons.info_outline_rounded,
  };
  Color get color => switch (this) {
    PoiCategory.event => AppColors.primary,
    PoiCategory.livestock => const Color(0xFF7C4A20),
    PoiCategory.autos => const Color(0xFF334155),
    PoiCategory.food => AppColors.orange,
    PoiCategory.artisan => const Color(0xFF9333EA),
    PoiCategory.service => const Color(0xFF0891B2),
  };
}

class Poi {
  final String id, name, description, zone, emoji, imageUrl;
  final PoiCategory category;
  final Offset position;
  final double rating;
  final String? schedule;
  final int? waitMins; // tiempo espera (comida)
  final double? price; // precio referencial (comida)
  final bool featured;
  const Poi({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.position,
    required this.emoji,
    required this.imageUrl,
    this.zone = 'Central',
    this.rating = 4.7,
    this.schedule,
    this.waitMins,
    this.price,
    this.featured = false,
  });
}

// Fotos Unsplash (permalinks estables, HTTPS)
const _imgConcert =
    'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=1200&q=80';
const _imgRodeo =
    'https://images.unsplash.com/photo-1553034545-32d4cd2168f1?w=1200&q=80';
const _imgFireworks =
    'https://images.unsplash.com/photo-1508997449629-303059a039c0?w=1200&q=80';
const _imgQueen =
    'https://images.unsplash.com/photo-1519741497674-611481863552?w=1200&q=80';
const _imgCow =
    'https://images.unsplash.com/photo-1546445317-29f4545e9d53?w=1200&q=80';
const _imgBull =
    'https://images.unsplash.com/photo-1500595046743-cd271d694d30?w=1200&q=80';
const _imgHorse =
    'https://images.unsplash.com/photo-1553284965-83fd3e82fa5a?w=1200&q=80';
const _imgSheep =
    'https://images.unsplash.com/photo-1484557985045-edf25e08da73?w=1200&q=80';
const _imgPig =
    'https://images.unsplash.com/photo-1516467508483-a7212febe31a?w=1200&q=80';
const _imgRabbit =
    'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=1200&q=80';
const _imgCar =
    'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=1200&q=80';
const _imgTractor =
    'https://images.unsplash.com/photo-1605338803155-8bb695b1b4d5?w=1200&q=80';
const _imgMoto =
    'https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=1200&q=80';
const _imgTruck =
    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=1200&q=80';
const _imgHornado =
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=1200&q=80';
const _imgCuy =
    'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=1200&q=80';
const _imgFritada =
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200&q=80';
const _imgColada =
    'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=1200&q=80';
const _imgBurger =
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=80';
const _imgTextile =
    'https://images.unsplash.com/photo-1596397249129-c7a8f8718873?w=1200&q=80';
const _imgPottery =
    'https://images.unsplash.com/photo-1493106641515-6b5631de4bb9?w=1200&q=80';
const _imgHat =
    'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=1200&q=80';
const _imgTicket =
    'https://images.unsplash.com/photo-1470549638415-0a0755be0619?w=1200&q=80';
const _imgParking =
    'https://images.unsplash.com/photo-1470224114660-3f6686c562eb?w=1200&q=80';
const _imgFirstAid =
    'https://images.unsplash.com/photo-1584515933487-779824d29309?w=1200&q=80';
const _imgAtm =
    'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?w=1200&q=80';
const _imgWc =
    'https://images.unsplash.com/photo-1520175480921-4edfa2983e0f?w=1200&q=80';

// ═══════════════════════════════════════════════════════════════════════════
// EVENTO DEL DÍA (para hero del Home)
// ═══════════════════════════════════════════════════════════════════════════
class LineupItem {
  final String time, artist, role, style;
  final int minutes;
  final bool headliner;
  const LineupItem({
    required this.time,
    required this.artist,
    required this.role,
    required this.style,
    required this.minutes,
    this.headliner = false,
  });
}

class TodayEvent {
  final String tag, artist, venue, time, dateLabel, description;
  final String imageUrl;
  final Poi poi;
  final int expectedAttendees;
  final bool live;
  final String priceLabel, ageLabel;
  final List<String> includes;
  final List<LineupItem> lineup;
  const TodayEvent({
    required this.tag,
    required this.artist,
    required this.venue,
    required this.time,
    required this.dateLabel,
    required this.description,
    required this.imageUrl,
    required this.poi,
    required this.expectedAttendees,
    this.live = false,
    required this.priceLabel,
    required this.ageLabel,
    required this.includes,
    required this.lineup,
  });
}

const kMockPois = <Poi>[
  // EVENTOS
  Poi(
    id: 'e1',
    name: 'Mega Escenario',
    description:
        'Concierto de artistas nacionales e internacionales. Aforo para 15.000 personas. Sonido L-Acoustics y pantalla LED 4K de 200m².',
    category: PoiCategory.event,
    position: Offset(0.50, 0.10),
    emoji: '🎤',
    imageUrl: _imgConcert,
    zone: 'Zona Norte',
    rating: 4.9,
    schedule: '20:00 · Hoy',
    featured: true,
  ),
  Poi(
    id: 'e2',
    name: 'Coliseo Mushuc Runa',
    description:
        'Espectáculo taurino, rodeo montubio y show de caballos criollos con jinetes de todo el país.',
    category: PoiCategory.event,
    position: Offset(0.28, 0.18),
    emoji: '🐂',
    imageUrl: _imgRodeo,
    zone: 'Coliseo',
    rating: 4.8,
    schedule: '16:00 · Hoy',
  ),
  Poi(
    id: 'e3',
    name: 'Ruedo Central',
    description:
        'Coleo criollo y montas de toros. Ambiente andino auténtico con música en vivo.',
    category: PoiCategory.event,
    position: Offset(0.55, 0.42),
    emoji: '🤠',
    imageUrl: _imgBull,
    zone: 'Central',
    rating: 4.7,
    schedule: '15:00 · Hoy',
  ),
  Poi(
    id: 'e4',
    name: 'Elección Reina 2026',
    description:
        'Coronación de la Reina de la Expo Feria Mushuc Runa. Desfile de trajes típicos.',
    category: PoiCategory.event,
    position: Offset(0.45, 0.30),
    emoji: '👑',
    imageUrl: _imgQueen,
    zone: 'Central',
    rating: 4.8,
    schedule: '21:00 · Sábado',
  ),
  Poi(
    id: 'e5',
    name: 'Show Pirotécnico',
    description:
        'Espectáculo de fuegos artificiales de cierre. 15 minutos de show sincronizado.',
    category: PoiCategory.event,
    position: Offset(0.52, 0.12),
    emoji: '🎆',
    imageUrl: _imgFireworks,
    zone: 'Zona Norte',
    rating: 4.9,
    schedule: '22:30 · Domingo',
  ),

  // GANADERÍA
  Poi(
    id: 'g1',
    name: 'Bovinos de Leche',
    description:
        'Holstein, Jersey y Brown Swiss. Concurso de mejor productora con jueces internacionales.',
    category: PoiCategory.livestock,
    position: Offset(0.15, 0.55),
    emoji: '🐄',
    imageUrl: _imgCow,
    zone: 'Corrales A',
    rating: 4.6,
  ),
  Poi(
    id: 'g2',
    name: 'Bovinos de Carne',
    description:
        'Angus, Brahman y cebú. Ejemplares premiados a nivel nacional.',
    category: PoiCategory.livestock,
    position: Offset(0.10, 0.65),
    emoji: '🐮',
    imageUrl: _imgCow,
    zone: 'Corrales A',
    rating: 4.5,
  ),
  Poi(
    id: 'g3',
    name: 'Caballos Criollos',
    description:
        'Caballos de paso y trote. Demostraciones de doma con jinetes profesionales.',
    category: PoiCategory.livestock,
    position: Offset(0.20, 0.72),
    emoji: '🐎',
    imageUrl: _imgHorse,
    zone: 'Corrales B',
    rating: 4.8,
  ),
  Poi(
    id: 'g4',
    name: 'Ovinos y Camélidos',
    description:
        'Ovejas, llamas y alpacas del páramo ecuatoriano. Fotos con los animales permitidas.',
    category: PoiCategory.livestock,
    position: Offset(0.12, 0.82),
    emoji: '🦙',
    imageUrl: _imgSheep,
    zone: 'Corrales B',
    rating: 4.7,
  ),
  Poi(
    id: 'g5',
    name: 'Porcinos',
    description:
        'Cerdos de raza York, Landrace y Duroc. Talleres de crianza técnica.',
    category: PoiCategory.livestock,
    position: Offset(0.25, 0.85),
    emoji: '🐷',
    imageUrl: _imgPig,
    zone: 'Corrales C',
    rating: 4.4,
  ),
  Poi(
    id: 'g6',
    name: 'Cuyes y Conejos',
    description:
        'Exposición de cuyes gigantes y conejos de raza. Concurso de mayor peso.',
    category: PoiCategory.livestock,
    position: Offset(0.30, 0.68),
    emoji: '🐇',
    imageUrl: _imgRabbit,
    zone: 'Pabellón Menor',
    rating: 4.5,
  ),

  // EXPO AUTOS
  Poi(
    id: 'a1',
    name: 'Autos 0 KM',
    description:
        'Concesionarias nacionales con planes de financiamiento exclusivos para socios.',
    category: PoiCategory.autos,
    position: Offset(0.80, 0.20),
    emoji: '🚗',
    imageUrl: _imgCar,
    zone: 'Expo Autos',
    rating: 4.6,
  ),
  Poi(
    id: 'a2',
    name: 'Maquinaria Agrícola',
    description:
        'Tractores, cosechadoras y equipos John Deere, Massey Ferguson, Kubota.',
    category: PoiCategory.autos,
    position: Offset(0.85, 0.32),
    emoji: '🚜',
    imageUrl: _imgTractor,
    zone: 'Expo Autos',
    rating: 4.7,
  ),
  Poi(
    id: 'a3',
    name: 'Motos y Cuatrimotos',
    description: 'Yamaha, Suzuki, Honda. Test drive disponible con instructor.',
    category: PoiCategory.autos,
    position: Offset(0.90, 0.45),
    emoji: '🏍️',
    imageUrl: _imgMoto,
    zone: 'Expo Autos',
    rating: 4.8,
  ),
  Poi(
    id: 'a4',
    name: 'Camiones y Buses',
    description:
        'Hino, Chevrolet, Mercedes-Benz. Vehículos para carga y pasajeros.',
    category: PoiCategory.autos,
    position: Offset(0.82, 0.55),
    emoji: '🚛',
    imageUrl: _imgTruck,
    zone: 'Expo Autos',
    rating: 4.5,
  ),

  // GASTRONOMÍA
  Poi(
    id: 'f1',
    name: 'Hornado Ambateño',
    description:
        'Cerdo hornado tradicional con llapingacho, mote, agrio y ensalada. Receta 100 años.',
    category: PoiCategory.food,
    position: Offset(0.60, 0.60),
    emoji: '🍖',
    imageUrl: _imgHornado,
    zone: 'Zona Food',
    rating: 4.9,
    waitMins: 15,
    price: 8.50,
    featured: true,
  ),
  Poi(
    id: 'f2',
    name: 'Cuy Asado',
    description:
        'Cuy típico con papas, ají y mote. Plato serrano por excelencia asado a leña.',
    category: PoiCategory.food,
    position: Offset(0.65, 0.68),
    emoji: '🍗',
    imageUrl: _imgCuy,
    zone: 'Zona Food',
    rating: 4.8,
    waitMins: 25,
    price: 15.00,
  ),
  Poi(
    id: 'f3',
    name: 'Fritada Chola',
    description:
        'Fritada tradicional con maíz tostado, mote, aguacate y curtido de cebolla.',
    category: PoiCategory.food,
    position: Offset(0.55, 0.72),
    emoji: '🥘',
    imageUrl: _imgFritada,
    zone: 'Zona Food',
    rating: 4.7,
    waitMins: 10,
    price: 7.00,
  ),
  Poi(
    id: 'f4',
    name: 'Colada Morada',
    description:
        'Bebida tradicional con guaguas de pan. 12 ingredientes andinos. Sabor a Ecuador.',
    category: PoiCategory.food,
    position: Offset(0.70, 0.62),
    emoji: '🥤',
    imageUrl: _imgColada,
    zone: 'Zona Food',
    rating: 4.9,
    waitMins: 5,
    price: 3.00,
  ),
  Poi(
    id: 'f5',
    name: 'Food Trucks Modernos',
    description:
        'Hamburguesas gourmet, tacos, pizza artesanal y postres. 8 food trucks juntos.',
    category: PoiCategory.food,
    position: Offset(0.62, 0.78),
    emoji: '🍔',
    imageUrl: _imgBurger,
    zone: 'Zona Food',
    rating: 4.6,
    waitMins: 20,
    price: 9.00,
  ),

  // ARTESANÍAS
  Poi(
    id: 'ar1',
    name: 'Textiles Andinos',
    description:
        'Ponchos, chalinas y tapices tejidos a mano en Salasaca. 100% lana de alpaca.',
    category: PoiCategory.artisan,
    position: Offset(0.40, 0.55),
    emoji: '🧣',
    imageUrl: _imgTextile,
    zone: 'Pabellón Artesanal',
    rating: 4.8,
  ),
  Poi(
    id: 'ar2',
    name: 'Cerámica de Pujilí',
    description:
        'Vasijas, ollas y piezas decorativas de barro cocido. Técnica ancestral.',
    category: PoiCategory.artisan,
    position: Offset(0.35, 0.48),
    emoji: '🏺',
    imageUrl: _imgPottery,
    zone: 'Pabellón Artesanal',
    rating: 4.7,
  ),
  Poi(
    id: 'ar3',
    name: 'Sombreros de Paja Toquilla',
    description:
        'El auténtico sombrero de Ecuador, tejido a mano en Montecristi. Patrimonio UNESCO.',
    category: PoiCategory.artisan,
    position: Offset(0.42, 0.62),
    emoji: '👒',
    imageUrl: _imgHat,
    zone: 'Pabellón Artesanal',
    rating: 4.9,
  ),

  // SERVICIOS
  Poi(
    id: 's1',
    name: 'Entrada Principal',
    description:
        'Boletería, información y control de acceso. Compra en línea disponible.',
    category: PoiCategory.service,
    position: Offset(0.50, 0.95),
    emoji: '🎫',
    imageUrl: _imgTicket,
    zone: 'Ingreso',
    rating: 4.5,
  ),
  Poi(
    id: 's2',
    name: 'Parking Principal',
    description:
        'Estacionamiento con capacidad para 2.000 vehículos. Vigilancia 24/7.',
    category: PoiCategory.service,
    position: Offset(0.50, 0.88),
    emoji: '🅿️',
    imageUrl: _imgParking,
    zone: 'Ingreso',
    rating: 4.3,
  ),
  Poi(
    id: 's3',
    name: 'Baños y Camerinos',
    description:
        'Servicios higiénicos y camerinos para expositores. Limpieza cada hora.',
    category: PoiCategory.service,
    position: Offset(0.72, 0.48),
    emoji: '🚻',
    imageUrl: _imgWc,
    zone: 'Central',
    rating: 4.2,
  ),
  Poi(
    id: 's4',
    name: 'Primeros Auxilios',
    description:
        'Punto de atención médica con paramédicos 24/7. Ambulancia en sitio.',
    category: PoiCategory.service,
    position: Offset(0.35, 0.35),
    emoji: '⚕️',
    imageUrl: _imgFirstAid,
    zone: 'Central',
    rating: 4.9,
  ),
  Poi(
    id: 's5',
    name: 'Cajero Cooperativa',
    description:
        'Cajero automático Mushuc Runa. Retiros sin costo para socios.',
    category: PoiCategory.service,
    position: Offset(0.55, 0.85),
    emoji: '🏧',
    imageUrl: _imgAtm,
    zone: 'Ingreso',
    rating: 4.6,
  ),
];

// Evento estelar del día — se muestra en el hero del Home
final _todayEvent = TodayEvent(
  tag: 'CONCIERTO ESTELAR',
  artist: 'Los Nietos & Delfín Quishpe',
  venue: 'Mega Escenario',
  time: '20:00',
  dateLabel: 'Hoy · Sáb 22 Ago',
  description:
      'La noche más esperada de la Feria Mushuc Runa. 4 horas de música en vivo con artistas nacionales e internacionales. Sonido L-Acoustics, pantalla LED 4K de 200m² y show de luces sincronizado.',
  imageUrl: _imgConcert,
  poi: kMockPois[0],
  expectedAttendees: 15000,
  live: true,
  priceLabel: 'Entrada libre',
  ageLabel: 'Todo público',
  includes: const [
    'Show de luces láser y pirotecnia fría',
    'Pantalla LED 4K de 200m²',
    'Sonido profesional L-Acoustics',
    'Zona VIP para socios Mushuc Runa',
    'Food trucks y bebidas hasta las 23:30',
  ],
  lineup: const [
    LineupItem(
      time: '20:00',
      artist: 'Grupo Sabor Kichwa',
      role: 'Apertura',
      style: 'Música andina · Salasaca',
      minutes: 30,
    ),
    LineupItem(
      time: '20:45',
      artist: 'Los Hermanos Núñez',
      role: 'Invitado especial',
      style: 'Sanjuanito · Pasillo ecuatoriano',
      minutes: 45,
    ),
    LineupItem(
      time: '21:45',
      artist: 'Los Nietos',
      role: 'Artista estelar',
      style: 'Cumbia andina · Éxitos',
      minutes: 75,
      headliner: true,
    ),
    LineupItem(
      time: '23:15',
      artist: 'Delfín Quishpe',
      role: 'Cierre estelar',
      style: 'Torres Gemelas · Éxitos virales',
      minutes: 60,
      headliner: true,
    ),
    LineupItem(
      time: '00:15',
      artist: 'Show pirotécnico',
      role: 'Cierre',
      style: 'Fuegos artificiales · 15 min',
      minutes: 15,
    ),
  ],
);

// ═══════════════════════════════════════════════════════════════════════════
// RESTAURANTES (con menú de platos)
// ═══════════════════════════════════════════════════════════════════════════
class Dish {
  final String name, description, imageUrl, emoji;
  final double price;
  final bool popular;
  const Dish({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.emoji = '🍽️',
    this.popular = false,
  });
}

class Restaurant {
  final String id,
      name,
      tagline,
      description,
      coverUrl,
      logoEmoji,
      zone,
      category;
  final double rating;
  final int reviews, waitMins;
  final String schedule;
  final bool featured;
  final List<Dish> dishes;
  const Restaurant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.coverUrl,
    required this.logoEmoji,
    required this.zone,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.waitMins,
    required this.schedule,
    this.featured = false,
    required this.dishes,
  });
}

// Imágenes de platos y covers (Unsplash)
const _dHornado =
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80';
const _dFritada =
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=80';
const _dLlapinga =
    'https://images.unsplash.com/photo-1541014741259-de529411b96a?w=800&q=80';
const _dYaguar =
    'https://images.unsplash.com/photo-1547592180-85f173990554?w=800&q=80';
const _dCuy =
    'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=800&q=80';
const _dPapas =
    'https://images.unsplash.com/photo-1585109649139-366815a0d713?w=800&q=80';
const _dAji =
    'https://images.unsplash.com/photo-1613844237701-8f3664fc2eff?w=800&q=80';
const _dColada =
    'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=800&q=80';
const _dMorocho =
    'https://images.unsplash.com/photo-1541704320-8b5be0bb0a5c?w=800&q=80';
const _dChicha =
    'https://images.unsplash.com/photo-1587049633312-d628ae50a8ae?w=800&q=80';
const _dCanelazo =
    'https://images.unsplash.com/photo-1608551246632-27f83b6c8b9d?w=800&q=80';
const _dChurrasco =
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80';
const _dChuleta =
    'https://images.unsplash.com/photo-1558030006-450675393462?w=800&q=80';
const _dAnticucho =
    'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=800&q=80';
const _dSalchipapa =
    'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800&q=80';
const _dBurger =
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80';
const _dPizza =
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80';
const _dTacos =
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&q=80';
const _dHotdog =
    'https://images.unsplash.com/photo-1612392062631-94dd858cba88?w=800&q=80';
const _dHigos =
    'https://images.unsplash.com/photo-1601979031925-9c1e4ea88a11?w=800&q=80';
const _dEspumilla =
    'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=800&q=80';
const _dBunuelos =
    'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=800&q=80';
const _dQuesadilla =
    'https://images.unsplash.com/photo-1600891964092-4316c288032e?w=800&q=80';

const _cvrTipica =
    'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=1200&q=80';
const _cvrCuy =
    'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=1200&q=80';
const _cvrColada =
    'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=1200&q=80';
const _cvrParrilla =
    'https://images.unsplash.com/photo-1558030006-450675393462?w=1200&q=80';
const _cvrFood =
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200&q=80';
const _cvrPostres =
    'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=1200&q=80';

const kRestaurants = <Restaurant>[
  Restaurant(
    id: 'r1',
    name: 'Hornado de María',
    tagline: '3 generaciones · Receta ancestral',
    description:
        'El hornado más famoso de Ambato. Cerdo horneado a leña 12 horas, con llapingacho crujiente, mote y agrio de cebolla. Un plato con más de 100 años de tradición familiar.',
    coverUrl: _cvrTipica,
    logoEmoji: '🍖',
    zone: 'Zona Food · Puesto 1',
    category: 'Típica',
    rating: 4.9,
    reviews: 214,
    waitMins: 15,
    schedule: '10:00 – 22:00',
    featured: true,
    dishes: [
      Dish(
        name: 'Hornado con llapingacho',
        description: 'Cerdo hornado + 2 llapingachos + mote + agrio',
        imageUrl: _dHornado,
        price: 8.50,
        emoji: '🍖',
        popular: true,
      ),
      Dish(
        name: 'Fritada con mote',
        description: 'Fritada tradicional con mote, maíz tostado y agrio',
        imageUrl: _dFritada,
        price: 7.00,
        emoji: '🥘',
        popular: true,
      ),
      Dish(
        name: 'Llapingachos solos (2u)',
        description: 'Tortillas de papa con queso, chorizo y salsa maní',
        imageUrl: _dLlapinga,
        price: 5.00,
        emoji: '🥔',
      ),
      Dish(
        name: 'Yaguarlocro',
        description: 'Locro de papa con sangre, aguacate y perejil',
        imageUrl: _dYaguar,
        price: 6.50,
        emoji: '🍲',
      ),
      Dish(
        name: 'Empanada de morocho',
        description: 'Empanada crocante rellena de carne y arroz',
        imageUrl: _dMorocho,
        price: 2.00,
        emoji: '🥟',
      ),
    ],
  ),
  Restaurant(
    id: 'r2',
    name: 'Cuy Asado Don Segundo',
    tagline: 'Asado a leña · Serrano de verdad',
    description:
        'Cuyes criados en Salcedo, asados en horno de leña durante 2 horas. Servidos con papas doradas, mote y ají de piedra picado en batán.',
    coverUrl: _cvrCuy,
    logoEmoji: '🍗',
    zone: 'Zona Food · Puesto 3',
    category: 'Típica',
    rating: 4.8,
    reviews: 156,
    waitMins: 25,
    schedule: '11:00 – 21:00',
    dishes: [
      Dish(
        name: 'Cuy asado entero',
        description: 'Cuy completo + papas + mote + ají de piedra',
        imageUrl: _dCuy,
        price: 15.00,
        emoji: '🍗',
        popular: true,
      ),
      Dish(
        name: 'Cuy medio',
        description: 'Media porción para 1 persona',
        imageUrl: _dCuy,
        price: 8.00,
        emoji: '🍗',
      ),
      Dish(
        name: 'Papas con maní',
        description: 'Papas doradas bañadas en salsa de maní',
        imageUrl: _dPapas,
        price: 4.00,
        emoji: '🥔',
      ),
      Dish(
        name: 'Ají de piedra',
        description: 'Ají tradicional molido en piedra volcánica',
        imageUrl: _dAji,
        price: 1.50,
        emoji: '🌶️',
      ),
    ],
  ),
  Restaurant(
    id: 'r3',
    name: 'Colada Morada la Abuela',
    tagline: 'Bebidas ancestrales del Ecuador',
    description:
        '12 ingredientes andinos naturales: mortiño, mora, ishpingo, hierba luisa, cedrón. Preparada como manda la tradición. Servida con guagua de pan artesanal.',
    coverUrl: _cvrColada,
    logoEmoji: '🥤',
    zone: 'Zona Food · Puesto 5',
    category: 'Bebidas',
    rating: 4.9,
    reviews: 288,
    waitMins: 5,
    schedule: '09:00 – 22:00',
    dishes: [
      Dish(
        name: 'Colada morada + guagua',
        description: 'Vaso 400ml + guagua de pan rellena',
        imageUrl: _dColada,
        price: 3.00,
        emoji: '🥤',
        popular: true,
      ),
      Dish(
        name: 'Morocho de dulce',
        description: 'Morocho caliente con canela y pasas',
        imageUrl: _dMorocho,
        price: 2.00,
        emoji: '☕',
      ),
      Dish(
        name: 'Chicha de jora',
        description: 'Chicha fermentada tradicional',
        imageUrl: _dChicha,
        price: 2.50,
        emoji: '🍺',
      ),
      Dish(
        name: 'Canelazo',
        description: 'Bebida caliente con canela, naranjilla y aguardiente',
        imageUrl: _dCanelazo,
        price: 2.50,
        emoji: '🥃',
        popular: true,
      ),
      Dish(
        name: 'Rosero quiteño',
        description: 'Bebida fría dulce con frutos secos',
        imageUrl: _dColada,
        price: 3.00,
        emoji: '🍹',
      ),
    ],
  ),
  Restaurant(
    id: 'r4',
    name: 'Parrillada Andina',
    tagline: 'Carbón de eucalipto · Corte fino',
    description:
        'Carnes maduras 21 días, asadas al carbón de eucalipto. Cortes premium de res ecuatoriana, chuletas ahumadas y anticuchos serranos.',
    coverUrl: _cvrParrilla,
    logoEmoji: '🥩',
    zone: 'Zona Food · Puesto 7',
    category: 'Parrilla',
    rating: 4.7,
    reviews: 189,
    waitMins: 20,
    schedule: '12:00 – 23:00',
    dishes: [
      Dish(
        name: 'Churrasco especial',
        description: 'Lomo fino + huevo + arroz + papas + aguacate',
        imageUrl: _dChurrasco,
        price: 12.00,
        emoji: '🥩',
        popular: true,
      ),
      Dish(
        name: 'Chuleta ahumada',
        description: 'Chuleta de cerdo ahumada 8h con ensalada',
        imageUrl: _dChuleta,
        price: 10.00,
        emoji: '🍖',
      ),
      Dish(
        name: 'Costillar BBQ',
        description: 'Costillas glaseadas + papas gajo + coleslaw',
        imageUrl: _dChuleta,
        price: 14.00,
        emoji: '🍖',
        popular: true,
      ),
      Dish(
        name: 'Anticucho serrano',
        description: 'Brochetas de corazón marinado con ají amarillo',
        imageUrl: _dAnticucho,
        price: 6.00,
        emoji: '🍢',
      ),
      Dish(
        name: 'Salchipapa gigante',
        description: 'Papas + salchicha + cheddar + salsas',
        imageUrl: _dSalchipapa,
        price: 5.00,
        emoji: '🍟',
      ),
    ],
  ),
  Restaurant(
    id: 'r5',
    name: 'Sabor Urbano Food Truck',
    tagline: 'Comida rápida gourmet',
    description:
        'Hamburguesas smash, pizza al horno de leña, tacos mexicanos y hotdogs premium. 5 food trucks en un mismo espacio con mesas comunales.',
    coverUrl: _cvrFood,
    logoEmoji: '🍔',
    zone: 'Zona Food · Food Trucks',
    category: 'Rápida',
    rating: 4.6,
    reviews: 342,
    waitMins: 20,
    schedule: '11:00 – 23:30',
    dishes: [
      Dish(
        name: 'Smash burger doble',
        description: 'Doble carne + cheddar + bacon + salsa secreta',
        imageUrl: _dBurger,
        price: 9.00,
        emoji: '🍔',
        popular: true,
      ),
      Dish(
        name: 'Pizza al horno de leña',
        description: 'Margherita, pepperoni o hawaiana · 30cm',
        imageUrl: _dPizza,
        price: 10.00,
        emoji: '🍕',
        popular: true,
      ),
      Dish(
        name: 'Tacos al pastor (3u)',
        description: 'Trío con piña, cilantro y salsa verde',
        imageUrl: _dTacos,
        price: 8.00,
        emoji: '🌮',
      ),
      Dish(
        name: 'Papas cheddar bacon',
        description: 'Papas fritas con cheddar derretido y bacon',
        imageUrl: _dSalchipapa,
        price: 6.00,
        emoji: '🍟',
      ),
      Dish(
        name: 'Hot dog premium',
        description: 'Salchicha alemana + queso brie + rúcula',
        imageUrl: _dHotdog,
        price: 5.00,
        emoji: '🌭',
      ),
    ],
  ),
  Restaurant(
    id: 'r6',
    name: 'Postres de la Sierra',
    tagline: 'Dulces tradicionales ecuatorianos',
    description:
        'Higos con queso, espumillas artesanales, buñuelos con miel de panela y las famosas quesadillas latacungueñas. Todo hecho al momento.',
    coverUrl: _cvrPostres,
    logoEmoji: '🍰',
    zone: 'Zona Food · Puesto 9',
    category: 'Postres',
    rating: 4.8,
    reviews: 176,
    waitMins: 10,
    schedule: '10:00 – 22:00',
    dishes: [
      Dish(
        name: 'Higos con queso',
        description: 'Higos en almíbar + queso fresco + arrope',
        imageUrl: _dHigos,
        price: 4.00,
        emoji: '🍯',
        popular: true,
      ),
      Dish(
        name: 'Espumilla artesanal',
        description: 'Espumilla de guayaba en cono de galleta',
        imageUrl: _dEspumilla,
        price: 3.00,
        emoji: '🍦',
      ),
      Dish(
        name: 'Buñuelos con miel',
        description: 'Buñuelos crocantes + miel de panela',
        imageUrl: _dBunuelos,
        price: 3.50,
        emoji: '🍩',
      ),
      Dish(
        name: 'Quesadilla latacungueña',
        description: 'Pan dulce con relleno de queso y azúcar',
        imageUrl: _dQuesadilla,
        price: 2.50,
        emoji: '🥮',
        popular: true,
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// ROOT SHELL — 5 tabs
// ═══════════════════════════════════════════════════════════════════════════
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;
  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget?>[_screenFor(0), null, null, null];
  }

  void _selectTab(int tab) {
    _screens[tab] ??= _screenFor(tab);
    setState(() => _tab = tab);
  }

  void _openRuni() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: .48),
      builder: (_) => const _RuniSheet(),
    );
  }

  Widget _screenFor(int tab) => switch (tab) {
    0 => HomeScreen(onOpenPackages: () => _selectTab(2), onOpenRuni: _openRuni),
    1 => const MapScreen(),
    2 => const PackagesScreen(),
    _ => const FoodScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _tab,
        children: _screens
            .map((screen) => screen ?? const SizedBox.shrink())
            .toList(growable: false),
      ),
      bottomNavigationBar: _BottomNav(
        index: _tab,
        onChange: _selectTab,
        onRuni: _openRuni,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  final VoidCallback onRuni;
  const _BottomNav({
    required this.index,
    required this.onChange,
    required this.onRuni,
  });
  @override
  Widget build(BuildContext context) {
    final items = const [
      (icon: Icons.home_rounded, label: 'Inicio'),
      (icon: Icons.map_rounded, label: 'Mapa'),
      (icon: Icons.confirmation_number_rounded, label: 'Paquetes'),
      (icon: Icons.restaurant_rounded, label: 'Comida'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .97),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.line, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: .18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(
              icon: items[0].icon,
              label: items[0].label,
              active: index == 0,
              onTap: () => onChange(0),
              inkOff: AppColors.inkSoft,
            ),
            _NavBtn(
              icon: items[1].icon,
              label: items[1].label,
              active: index == 1,
              onTap: () => onChange(1),
              inkOff: AppColors.inkSoft,
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Semantics(
                button: true,
                label: 'Abrir Runi',
                child: InkWell(
                  key: const Key('runi-nav-button'),
                  customBorder: const CircleBorder(),
                  onTap: onRuni,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.goldDk, AppColors.gold],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldDk.withValues(alpha: .45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryDeep,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
            _NavBtn(
              icon: items[2].icon,
              label: items[2].label,
              active: index == 2,
              onTap: () => onChange(2),
              inkOff: AppColors.inkSoft,
            ),
            _NavBtn(
              icon: items[3].icon,
              label: items[3].label,
              active: index == 3,
              onTap: () => onChange(3),
              inkOff: AppColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color inkOff;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.inkOff,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.primary : inkOff, size: 21),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: active ? AppColors.primary : inkOff,
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuniSheet extends StatelessWidget {
  const _RuniSheet();

  @override
  Widget build(BuildContext context) {
    const itinerary =
        <({String time, String title, String note, IconData icon})>[
          (
            time: '10:00',
            title: 'Parque de Dinosaurios',
            note: 'Empieza antes de que aumente la fila',
            icon: Icons.cruelty_free_rounded,
          ),
          (
            time: '11:30',
            title: 'Paseo en Tren',
            note: 'Recorre el complejo en familia',
            icon: Icons.train_rounded,
          ),
          (
            time: '13:00',
            title: 'Cocina Mushuc Runa',
            note: 'Almuerzo especial del paquete',
            icon: Icons.restaurant_rounded,
          ),
        ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DCC5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.coral],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Runi',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'TU GUÍA INTELIGENTE',
                        style: TextStyle(
                          color: AppColors.goldDk,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF5EDDC),
                    foregroundColor: AppColors.inkSoft,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text(
                'Armé un plan para tu familia según las filas de hoy y el clima soleado. ¡Aprovechen la mañana en las atracciones al aire libre!',
                style: TextStyle(
                  color: Color(0xFF4A362C),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tu recorrido recomendado',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (int index = 0; index < itinerary.length; index++)
              _RuniStep(
                step: itinerary[index],
                showLine: index != itinerary.length - 1,
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EDDC),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'Pregúntale algo a Runi…',
                      style: TextStyle(
                        color: Color(0xFFA08C74),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: AppColors.gold,
                    size: 19,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuniStep extends StatelessWidget {
  final ({String time, String title, String note, IconData icon}) step;
  final bool showLine;

  const _RuniStep({required this.step, required this.showLine});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Icon(step.icon, color: AppColors.primary, size: 18),
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.time,
                    style: const TextStyle(
                      color: AppColors.goldDk,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    step.note,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME — Discover style (imagen 1)
// ═══════════════════════════════════════════════════════════════════════════
class LegacyHomeScreen extends StatefulWidget {
  const LegacyHomeScreen({super.key});
  @override
  State<LegacyHomeScreen> createState() => _LegacyHomeScreenState();
}

class _LegacyHomeScreenState extends State<LegacyHomeScreen> {
  String _tab = 'Popular';
  final _tabs = const ['Popular', 'Hoy', 'Destacado', 'Cerca de ti'];
  @override
  Widget build(BuildContext context) {
    final popular = kMockPois.where((p) => p.rating >= 4.7).toList();
    final recommended = kMockPois
        .where((p) => p.category != PoiCategory.service)
        .take(6)
        .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Header con avatar + saludo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDk],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Mushuc Runa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -.5,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text('🧑‍🌾', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ],
            ),
          ),
          // Hero card = Evento principal del día (tap → detalle con lineup)
          Padding(
            padding: const EdgeInsets.all(20),
            child: _HeroDiscoverCard(
              event: _todayEvent,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EventDetailSheet(event: _todayEvent),
              ),
            ),
          ),
          // Tabs Popular/Featured
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 22),
              itemBuilder: (_, i) {
                final t = _tabs[i];
                final on = t == _tab;
                return GestureDetector(
                  onTap: () => setState(() => _tab = t),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: on ? FontWeight.w900 : FontWeight.w600,
                          color: on ? AppColors.ink : AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: on ? 30 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Cards horizontales grandes con foto
          SizedBox(
            height: 260,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _DiscoverPhotoCard(
                poi: popular[i],
                onTap: () => _openPoi(context, popular[i]),
              ),
            ),
          ),
          const SizedBox(height: 26),
          // Recomendados
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Recomendados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ver todos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .82,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: recommended
                .map(
                  (p) => _RecommendedCard(
                    poi: p,
                    onTap: () => _openPoi(context, p),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 26),
          // Banner Cooperativa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _CooperativaBanner(),
          ),
          const SizedBox(height: 24),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _StatsCard(),
          ),
        ],
      ),
    );
  }

  void _openPoi(BuildContext ctx, Poi p) => showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PoiDetailSheet(poi: p),
  );
}

class _HeroDiscoverCard extends StatelessWidget {
  final TodayEvent event;
  final VoidCallback onTap;
  const _HeroDiscoverCard({required this.event, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 360,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .28),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                event.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (c, w, p) =>
                    p == null ? w : Container(color: AppColors.primaryDeep),
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.primaryDeep),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.35, 1],
                    colors: [Colors.black54, Colors.transparent, Colors.black],
                  ),
                ),
              ),
              // Top-left badges
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    if (event.live)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coral,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.coral.withValues(alpha: .5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'EN VIVO HOY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.time,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: .8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              // Bottom info
              Positioned(
                left: 20,
                right: 20,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.tag,
                      style: const TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.artist,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Chips info
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _heroChip(Icons.location_on_rounded, event.venue),
                        _heroChip(
                          Icons.calendar_today_rounded,
                          event.dateLabel,
                        ),
                        _heroChip(
                          Icons.group_rounded,
                          '${(event.expectedAttendees / 1000).toStringAsFixed(0)}K asistentes',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // CTA row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .55),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Ver evento',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DiscoverPhotoCard extends StatelessWidget {
  final Poi poi;
  final VoidCallback onTap;
  const _DiscoverPhotoCard({required this.poi, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                poi.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (c, w, p) => p == null
                    ? w
                    : Container(
                        color: poi.category.color.withValues(alpha: .3),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  color: poi.category.color.withValues(alpha: .3),
                  child: Center(
                    child: Text(
                      poi.emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.yellow,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${poi.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            poi.zone,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final Poi poi;
  final VoidCallback onTap;
  const _RecommendedCard({required this.poi, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        poi.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, w, p) => p == null
                            ? w
                            : Container(
                                color: poi.category.color.withValues(
                                  alpha: .25,
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          color: poi.category.color.withValues(alpha: .3),
                          child: Center(
                            child: Text(
                              poi.emoji,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.yellow,
                        size: 13,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${poi.rating}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '· ${poi.zone}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CooperativaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDk],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cooperativa Mushuc Runa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cajero en la feria · Servicios financieros',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LA FERIA EN NÚMEROS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _s('+80K', 'Visitantes'),
              _s('400+', 'Expositores'),
              _s('5', 'Días'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _s(String n, String l) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          n,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          l,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenPackages;
  final VoidCallback? onOpenRuni;

  const HomeScreen({super.key, this.onOpenPackages, this.onOpenRuni});

  @override
  Widget build(BuildContext context) {
    final attractions =
        <({String name, String zone, String wait, String imageAsset})>[
          (
            name: 'Resbaladera Gigante',
            zone: 'Zona Norte',
            wait: '5 min',
            imageAsset: 'assets/attractions/resbaladera-gigante.png',
          ),
          (
            name: 'Bosque de Dinosaurios',
            zone: 'Zona Norte',
            wait: '10 min',
            imageAsset: 'assets/attractions/bosque-dinosaurios.png',
          ),
          (
            name: 'Paseo en Tren',
            zone: 'Recorrido',
            wait: '5 min',
            imageAsset: 'assets/attractions/paseo-tren.png',
          ),
          (
            name: 'Granja interactiva',
            zone: 'Zona Familiar',
            wait: 'Sin fila',
            imageAsset: 'assets/attractions/granja-interactiva.png',
          ),
        ];

    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 138),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MrHeader(),
              const SizedBox(height: 24),
              const Text(
                '¡Hola, familia!',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 29,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '¿Qué aventura vivimos hoy?',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onOpenRuni,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryDeep,
                        AppColors.primary,
                        AppColors.coral,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .28),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: .6),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RUNI · TU GUÍA CON IA',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hay poca fila en la Resbaladera Gigante. ¡Ve antes de las 11h!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Atracciones populares',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 196,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: attractions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) =>
                      _HomeAttractionCard(attraction: attractions[index]),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDeep,
                      AppColors.primary,
                      AppColors.primaryDk,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDeep.withValues(alpha: .3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -22,
                      top: -36,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withValues(alpha: .12),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SOLO SÁBADOS',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '2x1 en el paquete '),
                              TextSpan(
                                text: 'All Day',
                                style: TextStyle(color: AppColors.gold),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dinosaurios, piscinas, tren, cabalgata y más. Todo el día, toda la familia.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: onOpenPackages,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.primaryDeep,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 11,
                            ),
                          ),
                          child: const Text(
                            'Ver paquetes',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Expanded(
                    child: _HomeStat(value: '12', label: 'Atracciones'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _HomeStat(value: '09–18h', label: 'Abierto hoy'),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _HomeStat(value: 'Km 12', label: 'Vía Riobamba'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MrHeader extends StatelessWidget {
  const _MrHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [AppColors.primaryDk, AppColors.primaryDeep],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'MR',
            style: TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPLEJO INTERCULTURAL Y DEPORTIVO',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.goldDk,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.15,
                ),
              ),
              Text(
                'Mushuc Runa',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 21,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _HomeAttractionCard extends StatelessWidget {
  final ({String name, String zone, String wait, String imageAsset}) attraction;

  const _HomeAttractionCard({required this.attraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 166,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 108,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  attraction.imageAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: AppColors.primarySoft,
                    child: Icon(
                      Icons.attractions_rounded,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  top: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      attraction.wait,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attraction.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '★ 4.9 · ${attraction.zone}',
                  style: const TextStyle(
                    color: AppColors.goldDk,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeStat extends StatelessWidget {
  final String value;
  final String label;

  const _HomeStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MAP — Mapa ilustrado del recinto ferial
// ═══════════════════════════════════════════════════════════════════════════
class FairLocation {
  const FairLocation._();

  // Centro calculado con la misma georreferencia usada por el plano 1900×1018.
  static const double latitude = -1.3690877425784418;
  static const double longitude = -78.647792380582;
  static const double radiusMeters = 900;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _wc;
  bool _loading = true;
  bool _promptingMaps = false;
  StreamSubscription<Position>? _posSub;

  // Script inyectado que redirige navigator.geolocation.* al canal FlutterGeo
  // y resuelve las promesas cuando Flutter responde.
  static const String _geoBridge = r'''
    (function(){
      if (window.__geoBridgeInstalled) return;
      var callbacks = {}; var seq = 0;
      window.__flutterGeoResolve = function(id, lat, lng, accuracy){
        var cb = callbacks[id]; if (!cb) return;
        cb.success({
          coords:{ latitude:lat, longitude:lng, accuracy:accuracy,
                   altitude:null, altitudeAccuracy:null, heading:null, speed:null },
          timestamp: Date.now()
        });
      };
      window.__flutterGeoReject = function(id, code, msg){
        var cb = callbacks[id]; if (!cb) return;
        if (cb.error) cb.error({ code: code, message: msg,
          PERMISSION_DENIED:1, POSITION_UNAVAILABLE:2, TIMEOUT:3 });
      };
      function req(kind, success, error){
        var id = ++seq;
        callbacks[id] = { success: success, error: error, kind: kind };
        try { FlutterGeo.postMessage(JSON.stringify({id:id, kind:kind})); }
        catch(e){ if (error) error({code:2,message:'bridge unavailable'}); }
        return id;
      }
      var bridge = {
        getCurrentPosition: function(success, error){ req('once', success, error); },
        watchPosition: function(success, error){ return req('watch', success, error); },
        clearWatch: function(id){ delete callbacks[id]; }
      };
      try {
        Object.defineProperty(navigator, 'geolocation', {
          configurable: true,
          value: bridge
        });
      } catch (_) {
        try { navigator.geolocation = bridge; } catch (_) {}
      }
      window.__geoBridgeInstalled = navigator.geolocation === bridge;
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _wc = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('FlutterGeo', onMessageReceived: _handleGeoRequest)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => _wc.runJavaScript(_geoBridge),
          onPageFinished: (_) async {
            await _wc.runJavaScript(_geoBridge);
            await _wc.runJavaScript('startGPS();');
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadFlutterAsset('assets/map/index.html');
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _handleGeoRequest(JavaScriptMessage msg) async {
    Map<String, dynamic> req;
    try {
      req = jsonDecode(msg.message) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final id = req['id'] as int;
    final kind = req['kind'] as String;

    if (!await Geolocator.isLocationServiceEnabled()) {
      _reject(id, 2, 'Activa la ubicación en Ajustes');
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _reject(id, 1, 'Permiso de ubicación denegado');
      return;
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final distMeters = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        FairLocation.latitude,
        FairLocation.longitude,
      );
      if (distMeters > FairLocation.radiusMeters) {
        // Fuera del recinto → ofrecer abrir Maps para navegar hasta la feria
        _reject(id, 2, 'Estás fuera del recinto');
        if (!_promptingMaps && mounted) {
          _promptingMaps = true;
          await _promptOpenMaps(distMeters);
          _promptingMaps = false;
        }
        return;
      }
      // Dentro del recinto → devolver posición al mapa
      _resolve(id, p);
      if (kind == 'watch') {
        _posSub?.cancel();
        _posSub =
            Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 3,
              ),
            ).listen((p) {
              final d = Geolocator.distanceBetween(
                p.latitude,
                p.longitude,
                FairLocation.latitude,
                FairLocation.longitude,
              );
              if (d <= FairLocation.radiusMeters) _resolve(id, p);
            }, onError: (e) => _reject(id, 2, e.toString()));
      }
    } catch (e) {
      _reject(id, 2, e.toString());
    }
  }

  Future<void> _promptOpenMaps(double distMeters) async {
    final km = distMeters / 1000;
    final distLabel = km >= 1
        ? '${km.toStringAsFixed(1)} km'
        : '${distMeters.round()} m';
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.route_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Estás fuera del recinto'),
          ],
        ),
        content: Text(
          'Estás a $distLabel de la Expo Feria Mushuc Runa. ¿Te llevo con Google Maps hasta la entrada?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: const Text('Cómo llegar'),
          ),
        ],
      ),
    );
    if (open == true) _launchMapsToFair();
  }

  Future<void> _launchMapsToFair() async {
    // Google Maps (universal). En iOS abre la app de Google Maps si está instalada,
    // sino cae en Apple Maps por handoff, sino en Safari.
    final gmaps = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${FairLocation.latitude},${FairLocation.longitude}&travelmode=driving',
    );
    final appleMaps = Uri.parse(
      'http://maps.apple.com/?daddr=${FairLocation.latitude},${FairLocation.longitude}&dirflg=d',
    );
    if (await canLaunchUrl(gmaps)) {
      await launchUrl(gmaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMaps)) {
      await launchUrl(appleMaps, mode: LaunchMode.externalApplication);
    }
  }

  void _resolve(int id, Position p) {
    _wc.runJavaScript(
      'window.__flutterGeoResolve($id, ${p.latitude}, ${p.longitude}, ${p.accuracy});',
    );
  }

  void _reject(int id, int code, String msg) {
    final safe = msg.replaceAll("'", "\\'");
    _wc.runJavaScript("window.__flutterGeoReject($id, $code, '$safe');");
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    const bottomNavGap =
        96.0; // deja espacio a la bottom nav flotante de la app
    return ColoredBox(
      color: const Color(0xFF94BD78),
      child: Padding(
        padding: EdgeInsets.only(top: topPad, bottom: bottomNavGap),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/fair_map.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.low,
              ),
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _loading ? 0 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                child: WebViewWidget(controller: _wc),
              ),
            ),
            if (_loading)
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: .16),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Preparando mapa interactivo…',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  static const _packages =
      <
        ({
          String name,
          String tagline,
          String badge,
          String adult,
          String child,
          String normal,
          Color color,
          List<String> benefits,
        })
      >[
        (
          name: 'Tuki Tuki',
          tagline: 'LA EXPERIENCIA COMPLETA',
          badge: 'MÁS VENDIDO',
          adult: r'$25',
          child: r'$15',
          normal: r'$40',
          color: AppColors.primary,
          benefits: [
            'Parque de dinosaurios',
            'Resbaladera Gigante',
            'Piscinas y Paseo en Tren',
            'Mushuc Park y Cabalgata',
            'Asado de búfalo',
            'Parqueadero e ingreso',
          ],
        ),
        (
          name: 'Tuki Punlla',
          tagline: 'UN DÍA EN FAMILIA',
          badge: '',
          adult: r'$15',
          child: r'$8',
          normal: r'$25',
          color: AppColors.goldDk,
          benefits: [
            'Parque de dinosaurios',
            'Resbaladera Gigante',
            'Piscinas y Paseo en Tren',
            'Mushuc Park y Cabalgata',
            'Almuerzo especial',
            'Parqueadero e ingreso',
          ],
        ),
        (
          name: 'All Day 2x1',
          tagline: 'SOLO SÁBADOS',
          badge: 'PROMO',
          adult: r'2x$25',
          child: r'2x$15',
          normal: r'$50',
          color: AppColors.coral,
          benefits: [
            'Dos entradas por el precio de una',
            'Dinosaurios y Resbaladera',
            'Piscinas y Paseo en Tren',
            'Cabalgata y Mushuc Park',
            'Parqueadero e ingreso',
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 138),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageEyebrow(
                icon: Icons.confirmation_number_rounded,
                label: 'PLANEA TU VISITA',
              ),
              const SizedBox(height: 9),
              const Text(
                'Paquetes y entradas',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Un solo pago, diversión todo el día',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              for (final package in _packages) ...[
                _PackageCard(package: package),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF6E7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFEFD9A8),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.goldDk,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los precios corresponden al prototipo. La compra es demostrativa y no realiza cobros.',
                        style: TextStyle(
                          color: Color(0xFF8A5A12),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final ({
    String name,
    String tagline,
    String badge,
    String adult,
    String child,
    String normal,
    Color color,
    List<String> benefits,
  })
  package;

  const _PackageCard({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [package.color.withValues(alpha: .82), package.color],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: .7),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_activity_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.tagline,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (package.badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      package.badge,
                      style: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                for (final benefit in package.benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryDk,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: Color(0xFF4A362C),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(color: AppColors.line, height: 22),
                Row(
                  children: [
                    _PackagePrice(label: 'ADULTOS', value: package.adult),
                    const SizedBox(width: 20),
                    _PackagePrice(label: 'NIÑOS', value: package.child),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Normal ${package.normal}',
                          style: const TextStyle(
                            color: Color(0xFFB0A08C),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 5),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.primaryDeep,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text(
                            'Comprar',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackagePrice extends StatelessWidget {
  final String label;
  final String value;

  const _PackagePrice({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.goldDk,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _PageEyebrow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PageEyebrow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.goldDk, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.goldDk,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENTS — Agenda estilo calendario timeline (imagen 2)
// ═══════════════════════════════════════════════════════════════════════════
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedDay = 2; // índice del día seleccionado
  final List<({String d, String w, int day})> _days = const [
    (d: 'S', w: 'Sáb', day: 22),
    (d: 'D', w: 'Dom', day: 23),
    (d: 'L', w: 'Lun', day: 24),
    (d: 'M', w: 'Mar', day: 25),
    (d: 'M', w: 'Mié', day: 26),
    (d: 'J', w: 'Jue', day: 27),
    (d: 'V', w: 'Vie', day: 28),
  ];
  final List<
    ({String time, String duration, Poi poi, String presenter, bool ongoing})
  >
  _timeline = [
    (
      time: '11:35',
      duration: '13:05',
      poi: kMockPois[1],
      presenter: 'Coliseo · Rodeo Ecuador',
      ongoing: true,
    ),
    (
      time: '13:15',
      duration: '14:45',
      poi: kMockPois[2],
      presenter: 'Central · Toros de Casta',
      ongoing: false,
    ),
    (
      time: '15:10',
      duration: '16:40',
      poi: kMockPois[5],
      presenter: 'Corrales A · Holstein Cup',
      ongoing: false,
    ),
    (
      time: '17:00',
      duration: '19:00',
      poi: kMockPois[3],
      presenter: 'Central · 12 Candidatas',
      ongoing: false,
    ),
    (
      time: '20:00',
      duration: '23:30',
      poi: kMockPois[0],
      presenter: 'Mega Escenario · Los Nietos',
      ongoing: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Header: 24 Wed / Aug 2026
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                Text(
                  '${_days[_selectedDay].day}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    height: 1,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _days[_selectedDay].w,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Ago 2026',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Hoy',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Días de la semana pill selector
          SizedBox(
            height: 74,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final on = i == _selectedDay;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    decoration: BoxDecoration(
                      color: on ? AppColors.coral : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: on
                              ? AppColors.coral.withValues(alpha: .35)
                              : Colors.black.withValues(alpha: .04),
                          blurRadius: on ? 14 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _days[i].d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: on ? Colors.white : AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_days[i].day}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: on ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Header Time / Course
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Hora',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                Text(
                  'Evento',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                Spacer(),
                Icon(Icons.tune_rounded, size: 18, color: AppColors.inkSoft),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Timeline
          ..._timeline.map(
            (e) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: _TimelineRow(
                time: e.time,
                endTime: e.duration,
                poi: e.poi,
                presenter: e.presenter,
                ongoing: e.ongoing,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PoiDetailSheet(poi: e.poi),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String time, endTime, presenter;
  final Poi poi;
  final bool ongoing;
  final VoidCallback onTap;
  const _TimelineRow({
    required this.time,
    required this.endTime,
    required this.presenter,
    required this.poi,
    required this.ongoing,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  endTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ongoing ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ongoing
                        ? AppColors.primary.withValues(alpha: .35)
                        : Colors.black.withValues(alpha: .05),
                    blurRadius: ongoing ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          poi.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: ongoing ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: ongoing ? Colors.white70 : AppColors.inkSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    poi.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: ongoing ? Colors.white70 : AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: ongoing ? Colors.white70 : AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        poi.zone,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ongoing ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: ongoing
                              ? Colors.white24
                              : poi.category.color.withValues(alpha: .18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            poi.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          presenter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ongoing ? Colors.white : AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOOD — Restaurantes (light green theme, imagen 1 style)
// ═══════════════════════════════════════════════════════════════════════════
class LegacyFoodScreen extends StatefulWidget {
  const LegacyFoodScreen({super.key});
  @override
  State<LegacyFoodScreen> createState() => _LegacyFoodScreenState();
}

class _LegacyFoodScreenState extends State<LegacyFoodScreen> {
  String _category = 'Todo';
  final _cats = const [
    (name: 'Todo', emoji: '🍽️'),
    (name: 'Típica', emoji: '🍖'),
    (name: 'Parrilla', emoji: '🥩'),
    (name: 'Bebidas', emoji: '🥤'),
    (name: 'Postres', emoji: '🍰'),
    (name: 'Rápida', emoji: '🍔'),
  ];
  @override
  Widget build(BuildContext context) {
    final list = _category == 'Todo'
        ? kRestaurants
        : kRestaurants.where((r) => r.category == _category).toList();
    final featured = kRestaurants.firstWhere(
      (r) => r.featured,
      orElse: () => kRestaurants.first,
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDk],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Gastronomía',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    letterSpacing: -.5,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Título grande
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Sabores de\nla feria',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: -1,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${kRestaurants.length} restaurantes · Comida típica ecuatoriana',
              style: const TextStyle(
                color: AppColors.inkSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          // Categorías burbujas
          SizedBox(
            height: 96,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final c = _cats[i];
                final on = c.name == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = c.name),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: on ? AppColors.primary : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: on
                                  ? AppColors.primary.withValues(alpha: .35)
                                  : Colors.black.withValues(alpha: .05),
                              blurRadius: on ? 14 : 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            c.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.name,
                        style: TextStyle(
                          color: on ? AppColors.ink : AppColors.inkSoft,
                          fontSize: 12,
                          fontWeight: on ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Destacado
          if (_category == 'Todo')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _RestFeaturedCard(
                rest: featured,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantScreen(rest: featured),
                  ),
                ),
              ),
            ),
          if (_category == 'Todo') const SizedBox(height: 22),
          // Encabezado lista
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              children: [
                Text(
                  _category == 'Todo' ? 'Restaurantes abiertos' : _category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '${list.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Lista
          ...list.map(
            (r) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _RestListCard(
                rest: r,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RestaurantScreen(rest: r)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  static const _places =
      <
        ({
          String name,
          String description,
          String rating,
          String wait,
          String price,
          IconData icon,
          Color color,
        })
      >[
        (
          name: 'Sabores de la Sierra',
          description: 'Hornado, llapingachos y fritada tradicional',
          rating: '4.9',
          wait: '12 min',
          price: r'$6',
          icon: Icons.outdoor_grill_rounded,
          color: AppColors.coral,
        ),
        (
          name: 'Parrillada Andina',
          description: 'Carnes al carbón y asado de búfalo',
          rating: '4.8',
          wait: '18 min',
          price: r'$8',
          icon: Icons.local_fire_department_rounded,
          color: AppColors.primary,
        ),
        (
          name: 'Cocina Mushuc Runa',
          description: 'Menú familiar y almuerzos del día',
          rating: '4.8',
          wait: '10 min',
          price: r'$5',
          icon: Icons.ramen_dining_rounded,
          color: AppColors.goldDk,
        ),
        (
          name: 'Dulces de la Abuela',
          description: 'Morocho, buñuelos y postres de la Sierra',
          rating: '4.7',
          wait: '6 min',
          price: r'$2',
          icon: Icons.icecream_rounded,
          color: Color(0xFF8A5A8F),
        ),
        (
          name: 'Patio de Comidas La Luna',
          description: 'Opciones rápidas para toda la familia',
          rating: '4.6',
          wait: '15 min',
          price: r'$4',
          icon: Icons.lunch_dining_rounded,
          color: Color(0xFF2E86AB),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 138),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageEyebrow(
                icon: Icons.restaurant_rounded,
                label: 'GASTRONOMÍA',
              ),
              const SizedBox(height: 9),
              const Text(
                'Sabores del complejo',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Pide desde la app y recoge sin filas',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDeep, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.room_service_rounded,
                      color: AppColors.gold,
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECOMENDACIÓN DE RUNI',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Almuerza antes de las 13h para encontrar menos fila.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final place in _places) ...[
                _FoodPlaceCard(place: place),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodPlaceCard extends StatelessWidget {
  final ({
    String name,
    String description,
    String rating,
    String wait,
    String price,
    IconData icon,
    Color color,
  })
  place;

  const _FoodPlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: place.color.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(place.icon, color: place.color, size: 32),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '★ ${place.rating} · ${place.wait} · desde ${place.price}',
                  style: const TextStyle(
                    color: AppColors.goldDk,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
            child: const Text(
              'Pedir',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestFeaturedCard extends StatelessWidget {
  final Restaurant rest;
  final VoidCallback onTap;
  const _RestFeaturedCard({required this.rest, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .2),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: AspectRatio(
            aspectRatio: 1.35,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    rest.coverUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, w, p) => p == null
                        ? w
                        : Container(
                            color: AppColors.primary.withValues(alpha: .25),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary.withValues(alpha: .25),
                      child: Center(
                        child: Text(
                          rest.logoEmoji,
                          style: const TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ DESTACADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rest.category,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rest.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),
                          Text(
                            ' ${rest.waitMins} min',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.restaurant_menu,
                            color: Colors.white70,
                            size: 13,
                          ),
                          Text(
                            ' ${rest.dishes.length} platos',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestListCard extends StatelessWidget {
  final Restaurant rest;
  final VoidCallback onTap;
  const _RestListCard({required this.rest, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final waitColor = rest.waitMins <= 10
        ? AppColors.primary
        : rest.waitMins <= 20
        ? AppColors.yellow
        : AppColors.coral;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 96,
                height: 96,
                child: Image.network(
                  rest.coverUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, w, p) => p == null
                      ? w
                      : Container(
                          color: AppColors.primary.withValues(alpha: .2),
                        ),
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: .2),
                    child: Center(
                      child: Text(
                        rest.logoEmoji,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rest.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${rest.dishes.length} platos',
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    rest.name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rest.tagline,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: waitColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        ' ${rest.waitMins} min de espera',
                        style: TextStyle(
                          color: waitColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.inkSoft,
                      ),
                      Text(
                        rest.zone.split('·').last.trim(),
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESTAURANT DETAIL — Perfil del local + menú de platos
// ═══════════════════════════════════════════════════════════════════════════
class RestaurantScreen extends StatelessWidget {
  final Restaurant rest;
  const RestaurantScreen({super.key, required this.rest});

  @override
  Widget build(BuildContext context) {
    final r = rest;
    final waitColor = r.waitMins <= 10
        ? AppColors.primary
        : r.waitMins <= 20
        ? AppColors.yellow
        : AppColors.coral;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero cover
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                leading: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        r.coverUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (c, w, p) =>
                            p == null ? w : Container(color: AppColors.primary),
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.primary),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black87,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  r.logoEmoji,
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white38),
                                    ),
                                    child: Text(
                                      r.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tagline
                      Text(
                        r.tagline,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Info row (sin rating)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: waitColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${r.waitMins} min',
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'tiempo de espera',
                                    style: TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.line,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${r.dishes.length}',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const Text(
                                    'platos en carta',
                                    style: TextStyle(
                                      color: AppColors.inkSoft,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ubicación + horario
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Ubicación',
                                          style: TextStyle(
                                            color: AppColors.inkSoft,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          r.zone,
                                          style: const TextStyle(
                                            color: AppColors.ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Horario',
                                          style: TextStyle(
                                            color: AppColors.inkSoft,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          r.schedule,
                                          style: const TextStyle(
                                            color: AppColors.ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Sobre el local
                      const Text(
                        'Sobre el local',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.description,
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Menú
                      Row(
                        children: [
                          const Text(
                            'Nuestros platos',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${r.dishes.length} en carta',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Lista de platos (solo informativo)
                      ...r.dishes.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DishCard(dish: d),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Dish dish;
  const _DishCard({required this.dish});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(
                    dish.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, w, p) => p == null
                        ? w
                        : Container(
                            color: AppColors.primary.withValues(alpha: .15),
                          ),
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary.withValues(alpha: .15),
                      child: Center(
                        child: Text(
                          dish.emoji,
                          style: const TextStyle(fontSize: 38),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (dish.popular)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 Top',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dish.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  dish.description,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ref. \$${dish.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POI DETAIL SHEET — estilo travel app (imagen 1)
// ═══════════════════════════════════════════════════════════════════════════
class PoiDetailSheet extends StatefulWidget {
  final Poi poi;
  const PoiDetailSheet({super.key, required this.poi});
  @override
  State<PoiDetailSheet> createState() => _PoiDetailSheetState();
}

class _PoiDetailSheetState extends State<PoiDetailSheet> {
  int _qty = 2;
  @override
  Widget build(BuildContext context) {
    final p = widget.poi;
    const bg = Colors.white;
    const ink = AppColors.ink;
    const soft = AppColors.inkSoft;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            // Foto hero
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: Image.network(
                      p.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, w, prog) => prog == null
                          ? w
                          : Container(
                              color: p.category.color.withValues(alpha: .3),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: p.category.color.withValues(alpha: .3),
                        child: Center(
                          child: Text(
                            p.emoji,
                            style: const TextStyle(fontSize: 90),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría + zona pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: p.category.color.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.category.icon,
                              size: 12,
                              color: p.category.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.category.label,
                              style: TextStyle(
                                color: p.category.color,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_rounded, color: soft, size: 14),
                      Text(
                        ' ${p.zone}',
                        style: TextStyle(
                          color: soft,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Título
                  Text(
                    p.name,
                    style: TextStyle(
                      color: ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.yellow,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${p.rating}',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '  (${(p.rating * 30).round()} reseñas)',
                        style: TextStyle(
                          color: soft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (p.schedule != null) ...[
                        const SizedBox(width: 14),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: p.category.color,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          p.schedule!,
                          style: TextStyle(
                            color: p.category.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Selector cantidad (para comida u obras)
                  if (p.category == PoiCategory.food)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Cantidad',
                            style: TextStyle(
                              color: ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          _QtyBtn(
                            icon: Icons.remove_rounded,
                            onTap: () =>
                                setState(() => _qty = (_qty - 1).clamp(1, 20)),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '$_qty',
                            style: const TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: () =>
                                setState(() => _qty = (_qty + 1).clamp(1, 20)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '\$${((p.price ?? 0) * _qty).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (p.category == PoiCategory.food)
                    const SizedBox(height: 18),
                  // Descripción
                  Text(
                    'Descripción',
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.description,
                    style: TextStyle(
                      color: soft,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 26),
                  // CTA
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDk],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () {},
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p.category == PoiCategory.food
                                          ? 'Añadir al pedido'
                                          : 'Cómo llegar',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EVENT DETAIL SHEET — Evento del día con lineup completo
// ═══════════════════════════════════════════════════════════════════════════
class EventDetailSheet extends StatelessWidget {
  final TodayEvent event;
  const EventDetailSheet({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.zero,
          children: [
            // Hero
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, w, p) => p == null
                          ? w
                          : Container(color: AppColors.primaryDeep),
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.primaryDeep),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      shape: BoxShape.circle,
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (event.live)
                  Positioned(
                    top: 20,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coral.withValues(alpha: .5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 6),
                          Text(
                            'EN VIVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.tag,
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.artist,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards row
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          Icons.access_time_rounded,
                          event.time,
                          event.dateLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(
                          Icons.location_on_rounded,
                          event.venue,
                          '${(event.expectedAttendees / 1000).toStringAsFixed(0)}K asistentes',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          Icons.confirmation_number_outlined,
                          event.priceLabel,
                          event.ageLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _infoCard(
                          Icons.stadium_rounded,
                          'Aforo total',
                          '${event.expectedAttendees} pers.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Descripción
                  const Text(
                    'Sobre el evento',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ═══ LINEUP / PROGRAMACIÓN ═══
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDk],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Programación',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${event.lineup.length} artistas',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Timeline lineup
                  ...List.generate(event.lineup.length, (i) {
                    final l = event.lineup[i];
                    final last = i == event.lineup.length - 1;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time column
                          SizedBox(
                            width: 56,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  l.time,
                                  style: TextStyle(
                                    color: l.headliner
                                        ? AppColors.primary
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${l.minutes} min',
                                  style: const TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dot + line
                          Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: l.headliner
                                      ? AppColors.primary
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              if (!last)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: AppColors.primary.withValues(
                                      alpha: .25,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Card
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: last ? 0 : 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: l.headliner
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: l.headliner
                                          ? AppColors.primary.withValues(
                                              alpha: .3,
                                            )
                                          : Colors.black.withValues(alpha: .05),
                                      blurRadius: l.headliner ? 14 : 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: l.headliner
                                                ? Colors.white24
                                                : AppColors.primarySoft,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            l.role.toUpperCase(),
                                            style: TextStyle(
                                              color: l.headliner
                                                  ? Colors.white
                                                  : AppColors.primary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        if (l.headliner)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 6),
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: AppColors.yellow,
                                              size: 18,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      l.artist,
                                      style: TextStyle(
                                        color: l.headliner
                                            ? Colors.white
                                            : AppColors.ink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l.style,
                                      style: TextStyle(
                                        color: l.headliner
                                            ? Colors.white70
                                            : AppColors.inkSoft,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 22),
                  // ═══ INCLUYE ═══
                  const Text(
                    '¿Qué incluye?',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...event.includes.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              it,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  // CTA
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryDk],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: .45),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () {},
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_walk_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cómo llegar al escenario',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Activa el recordatorio para no perderte el show',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
