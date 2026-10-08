(function (root) {
  'use strict';

  const legacyPlaces = [
  {
    "id": 0,
    "cat": "bano",
    "name": "Baños 1",
    "x": 1131.1,
    "y": 21.8
  },
  {
    "id": 1,
    "cat": "bano",
    "name": "Baños 2",
    "x": 1392.4,
    "y": 84.2
  },
  {
    "id": 2,
    "cat": "bano",
    "name": "Baños 3",
    "x": 1293.3,
    "y": 130.2
  },
  {
    "id": 3,
    "cat": "bano",
    "name": "Baños 4",
    "x": 1564.6,
    "y": 43.2
  },
  {
    "id": 4,
    "cat": "bano",
    "name": "Baños 5",
    "x": 840.8,
    "y": 294.5
  },
  {
    "id": 5,
    "cat": "bano",
    "name": "Baños 6",
    "x": 1115.2,
    "y": 249.2
  },
  {
    "id": 6,
    "cat": "bano",
    "name": "Baños 7",
    "x": 1541.3,
    "y": 111.4
  },
  {
    "id": 7,
    "cat": "bano",
    "name": "Baños 8",
    "x": 500.1,
    "y": 489.6
  },
  {
    "id": 8,
    "cat": "bano",
    "name": "Baños 9",
    "x": 1206.9,
    "y": 371.3
  },
  {
    "id": 9,
    "cat": "bano",
    "name": "Baños 10",
    "x": 1293.9,
    "y": 346.7
  },
  {
    "id": 10,
    "cat": "bano",
    "name": "Baños 11",
    "x": 823.9,
    "y": 542.5
  },
  {
    "id": 11,
    "cat": "acceso",
    "name": "Acceso 1 · Turistas",
    "x": 333.3,
    "y": 352.7
  },
  {
    "id": 12,
    "cat": "acceso",
    "name": "Acceso 2 · Expositores/Auspiciantes/Patio Luna",
    "x": 279.8,
    "y": 662.9
  },
  {
    "id": 13,
    "cat": "acceso",
    "name": "Acceso 3 · Expositores/Auspiciantes/Turistas",
    "x": 420.8,
    "y": 977.3
  },
  {
    "id": 14,
    "cat": "acceso",
    "name": "Acceso 4 · Auspiciantes/Negocios/Patio Mega",
    "x": 1635.9,
    "y": 423.5
  },
  {
    "id": 15,
    "cat": "acceso",
    "name": "Acceso 5 · Expositores/Turistas",
    "x": 1610.9,
    "y": 6.7
  },
  {
    "id": 16,
    "cat": "acceso",
    "name": "Acceso 6 · Ingreso vehicular",
    "x": 1629.2,
    "y": 6.7
  },
  {
    "id": 17,
    "cat": "salida",
    "name": "Salida 1",
    "x": 1625,
    "y": 549.2
  },
  {
    "id": 18,
    "cat": "salida",
    "name": "Salida 2",
    "x": 486.6,
    "y": 6.7
  },
  {
    "id": 19,
    "cat": "salida",
    "name": "Salida 3",
    "x": 1619.4,
    "y": 6.7
  },
  {
    "id": 20,
    "cat": "evento",
    "name": "Mega Escenario",
    "x": 1181.6,
    "y": 319.8,
    "venue": "mega",
    "icon": "🎤",
    "events": [
      {
        "time": "15:00",
        "title": "Festival de danza intercultural",
        "status": "Disponible"
      },
      {
        "time": "18:30",
        "title": "Concierto nacional",
        "status": "Principal"
      },
      {
        "time": "21:00",
        "title": "Show de cierre",
        "status": "Hoy"
      }
    ]
  },
  {
    "id": 21,
    "cat": "show",
    "name": "Mushuc Park",
    "x": 1199.6,
    "y": 118
  },
  {
    "id": 22,
    "cat": "show",
    "name": "Resbaladera Gigante",
    "x": 868.6,
    "y": 160.1
  },
  {
    "id": 23,
    "cat": "show",
    "name": "Parque de Dinosaurios",
    "x": 941.1,
    "y": 184.8
  },
  {
    "id": 24,
    "cat": "show",
    "name": "Juegos mecánicos",
    "x": 1274.3,
    "y": 422.7
  },
  {
    "id": 25,
    "cat": "show",
    "name": "Show Militar",
    "x": 1018.5,
    "y": 384
  },
  {
    "id": 26,
    "cat": "show",
    "name": "Shows cómicos",
    "x": 754.3,
    "y": 369.3
  },
  {
    "id": 27,
    "cat": "show",
    "name": "Plaza de toros",
    "x": 445.8,
    "y": 812.9
  },
  {
    "id": 28,
    "cat": "evento",
    "name": "Plaza de la Luna",
    "x": 814.2,
    "y": 392.4,
    "venue": "luna",
    "icon": "🌙",
    "events": [
      {
        "time": "11:00",
        "title": "Cuentacuentos andinos",
        "status": "Familiar"
      },
      {
        "time": "14:30",
        "title": "Taller de artesanías",
        "status": "Cupos"
      },
      {
        "time": "17:00",
        "title": "Danza Salasaka",
        "status": "Hoy"
      }
    ]
  },
  {
    "id": 29,
    "cat": "servicio",
    "name": "Granja",
    "x": 1460.4,
    "y": 233.9
  },
  {
    "id": 30,
    "cat": "comida",
    "name": "Patio de comidas La Luna",
    "x": 883.3,
    "y": 455.9
  },
  {
    "id": 31,
    "cat": "comida",
    "name": "Patio de comidas Megaescenario",
    "x": 1326.4,
    "y": 288.9
  },
  {
    "id": 32,
    "cat": "comida",
    "name": "Cocina",
    "x": 724.3,
    "y": 341.9
  },
  {
    "id": 33,
    "cat": "comida",
    "name": "Cerveza artesanal (zona 9)",
    "x": 1385.5,
    "y": 352.1
  },
  {
    "id": 34,
    "cat": "servicio",
    "name": "Boletería 1",
    "x": 707.1,
    "y": 156.7
  },
  {
    "id": 35,
    "cat": "servicio",
    "name": "Boletería 2",
    "x": 1078.2,
    "y": 91.8
  },
  {
    "id": 36,
    "cat": "servicio",
    "name": "Boletería 3",
    "x": 1426.3,
    "y": 6.7
  },
  {
    "id": 37,
    "cat": "servicio",
    "name": "Boletería 4",
    "x": 1558.6,
    "y": 426
  },
  {
    "id": 38,
    "cat": "servicio",
    "name": "Boletería 5",
    "x": 408.7,
    "y": 465.3
  },
  {
    "id": 39,
    "cat": "servicio",
    "name": "Oficina de ventas",
    "x": 1254.6,
    "y": 134.5
  },
  {
    "id": 40,
    "cat": "servicio",
    "name": "Dispensario médico",
    "x": 1256.4,
    "y": 177.4
  },
  {
    "id": 41,
    "cat": "servicio",
    "name": "Punto de hidratación",
    "x": 1339.5,
    "y": 246.8
  },
  {
    "id": 42,
    "cat": "parqueo",
    "name": "Estacionamiento E1 · auspiciantes/corporativos",
    "x": 714.6,
    "y": 405.4
  },
  {
    "id": 43,
    "cat": "parqueo",
    "name": "Estacionamiento E2 · expositores",
    "x": 717.6,
    "y": 514.3
  },
  {
    "id": 44,
    "cat": "parqueo",
    "name": "Estacionamiento V · expositores",
    "x": 1278.4,
    "y": 6.7
  },
  {
    "id": 45,
    "cat": "parqueo",
    "name": "Estacionamiento R · negocios y patio luna",
    "x": 1451.4,
    "y": 401
  },
  {
    "id": 46,
    "cat": "parqueo",
    "name": "Est. logística I",
    "x": 404,
    "y": 435.3
  },
  {
    "id": 47,
    "cat": "parqueo",
    "name": "Est. logística II",
    "x": 798.7,
    "y": 542.1
  },
  {
    "id": 48,
    "cat": "parqueo",
    "name": "Est. logística III",
    "x": 1494.3,
    "y": 494.7
  },
  {
    "id": 49,
    "cat": "parqueo",
    "name": "Est. logística IV",
    "x": 1161.7,
    "y": 158.8
  },
  {
    "id": 50,
    "cat": "parqueo",
    "name": "Est. logística V",
    "x": 1165.8,
    "y": 6.7
  },
  {
    "id": 51,
    "cat": "parqueo",
    "name": "Est. logística VI",
    "x": 1137.7,
    "y": 6.7
  },
  {
    "id": 52,
    "cat": "trans",
    "name": "Estación de trasbordo",
    "x": 376,
    "y": 396.7
  },
  {
    "id": 53,
    "cat": "trans",
    "name": "Estación de trasbordo",
    "x": 958.7,
    "y": 254
  },
  {
    "id": 54,
    "cat": "trans",
    "name": "Parada T1",
    "x": 681.1,
    "y": 314.6
  },
  {
    "id": 55,
    "cat": "trans",
    "name": "Parada T2",
    "x": 874,
    "y": 526.8
  },
  {
    "id": 56,
    "cat": "trans",
    "name": "Parada T3",
    "x": 1077.3,
    "y": 475.2
  },
  {
    "id": 57,
    "cat": "trans",
    "name": "Parada T4",
    "x": 1200.4,
    "y": 469.1
  },
  {
    "id": 58,
    "cat": "trans",
    "name": "Parada T5",
    "x": 1424.9,
    "y": 337.9
  },
  {
    "id": 59,
    "cat": "trans",
    "name": "Parada T6",
    "x": 1316.4,
    "y": 45.5
  },
  {
    "id": 60,
    "cat": "trans",
    "name": "Parada T7",
    "x": 1184.7,
    "y": 21.5
  },
  {
    "id": 61,
    "cat": "trans",
    "name": "Parada T8",
    "x": 1025.1,
    "y": 88.3
  },
  {
    "id": 62,
    "cat": "trans",
    "name": "Parada T9",
    "x": 697.2,
    "y": 223.3
  },
  {
    "id": 63,
    "cat": "trans",
    "name": "Parada T10",
    "x": 727.6,
    "y": 184.3
  },
  {
    "id": 64,
    "cat": "trans",
    "name": "Parada T11",
    "x": 1183.2,
    "y": 98.8
  },
  {
    "id": 65,
    "cat": "trans",
    "name": "Parada T12",
    "x": 881.7,
    "y": 245.8
  },
  {
    "id": 66,
    "cat": "servicio",
    "name": "Escáner 1",
    "x": 1203.2,
    "y": 50.6
  },
  {
    "id": 67,
    "cat": "servicio",
    "name": "Escáner 2",
    "x": 1340.7,
    "y": 76.3
  },
  {
    "id": 68,
    "cat": "servicio",
    "name": "Escáner 3",
    "x": 711.5,
    "y": 298.2
  },
  {
    "id": 69,
    "cat": "servicio",
    "name": "Escáner 4",
    "x": 1416.1,
    "y": 318.4
  },
  {
    "id": 70,
    "cat": "servicio",
    "name": "Escáner 5",
    "x": 1061.3,
    "y": 442.3
  },
  {
    "id": 71,
    "cat": "servicio",
    "name": "Escáner 6",
    "x": 910.9,
    "y": 506.7
  },
  {
    "id": 72,
    "cat": "servicio",
    "name": "Escáner 7",
    "x": 769.6,
    "y": 565.6
  },
  {
    "id": 73,
    "cat": "zona",
    "name": "Zona A",
    "x": 417.1,
    "y": 367.5
  },
  {
    "id": 74,
    "cat": "zona",
    "name": "Zona B",
    "x": 432.2,
    "y": 622.7
  },
  {
    "id": 75,
    "cat": "zona",
    "name": "Zona C",
    "x": 547.9,
    "y": 575.5
  },
  {
    "id": 76,
    "cat": "zona",
    "name": "Zona D",
    "x": 615.9,
    "y": 490.5
  },
  {
    "id": 77,
    "cat": "zona",
    "name": "Zona F",
    "x": 510,
    "y": 892.5
  },
  {
    "id": 78,
    "cat": "zona",
    "name": "Zona G",
    "x": 587.3,
    "y": 813.3
  },
  {
    "id": 79,
    "cat": "zona",
    "name": "Zona I",
    "x": 695.6,
    "y": 773.2
  },
  {
    "id": 80,
    "cat": "zona",
    "name": "Zona J",
    "x": 968.9,
    "y": 828.3
  },
  {
    "id": 81,
    "cat": "zona",
    "name": "Zona K",
    "x": 858.3,
    "y": 682.7
  },
  {
    "id": 82,
    "cat": "zona",
    "name": "Zona L",
    "x": 999.7,
    "y": 694.4
  },
  {
    "id": 83,
    "cat": "zona",
    "name": "Zona M",
    "x": 938.4,
    "y": 586
  },
  {
    "id": 84,
    "cat": "zona",
    "name": "Zona O",
    "x": 1290.8,
    "y": 606.6
  },
  {
    "id": 85,
    "cat": "zona",
    "name": "Zona P",
    "x": 1205.3,
    "y": 515.6
  },
  {
    "id": 86,
    "cat": "zona",
    "name": "Zona S",
    "x": 994.4,
    "y": 37.1
  },
  {
    "id": 87,
    "cat": "zona",
    "name": "Zona T",
    "x": 1028.6,
    "y": 6.7
  },
  {
    "id": 88,
    "cat": "zona",
    "name": "Zona U",
    "x": 1274.1,
    "y": 10.4
  },
  {
    "id": 89,
    "cat": "zona",
    "name": "Zona W",
    "x": 1089.4,
    "y": 6.7
  },
  {
    "id": 90,
    "cat": "zona",
    "name": "Zona X",
    "x": 1291.1,
    "y": 6.7
  },
  {
    "id": 91,
    "cat": "zona",
    "name": "Zona Y",
    "x": 1496.7,
    "y": 6.7
  },
  {
    "id": 92,
    "cat": "zona",
    "name": "Zona Z",
    "x": 1489.1,
    "y": 6.7
  },
  {
    "id": 93,
    "cat": "evento",
    "name": "Plaza del Sol",
    "x": 1125,
    "y": 465,
    "venue": "sol",
    "icon": "☀️",
    "events": [
      {
        "time": "10:30",
        "title": "Ceremonia del Inti",
        "status": "Cultural"
      },
      {
        "time": "13:00",
        "title": "Juegos tradicionales",
        "status": "Familiar"
      },
      {
        "time": "16:00",
        "title": "Música andina en vivo",
        "status": "Hoy"
      }
    ]
  }
];

  const officialCoordinates = Object.freeze({
    11: { x: 690, y: 120 },
    12: { x: 345, y: 555 },
    13: { x: 160, y: 1060 },
    14: { x: 1120, y: 970 },
    15: { x: 1300, y: 525 },
    16: { x: 1415, y: 305 },
    20: { x: 890, y: 755 },
    21: { x: 990, y: 570 },
    22: { x: 740, y: 515 },
    23: { x: 750, y: 590 },
    24: { x: 1050, y: 535 },
    25: { x: 900, y: 660 },
    26: { x: 620, y: 620 },
    27: { x: 235, y: 935 },
    28: { x: 600, y: 685 },
    29: { x: 1175, y: 620 },
    30: { x: 610, y: 650 },
    31: { x: 1010, y: 700 },
    32: { x: 540, y: 610 },
    39: { x: 800, y: 700 },
    40: { x: 820, y: 720 },
    41: { x: 900, y: 600 },
    93: { x: 950, y: 610 },
  });

  const recommendationIds = Object.freeze({
    20: 'megaescenario',
    21: 'mushuc-park',
    22: 'resbaladera-gigante',
    23: 'parque-dinosaurios',
    28: 'plaza-luna',
    29: 'granja-interactiva',
    30: 'patio-luna',
    31: 'patio-mega',
    93: 'plaza-sol',
  });

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  const officialPlaces = legacyPlaces
    .filter((place) => place.cat !== 'trans')
    .map((place) => {
      const coordinate = officialCoordinates[place.id];
      const migrated = coordinate
        ? { ...coordinate, needsReview: false }
        : root.MapGeometryV3.migrateLegacyPoint(place, place, null);
      return {
        ...clone(place),
        ...migrated,
        ...(recommendationIds[place.id]
          ? { recommendationId: recommendationIds[place.id] }
          : {}),
      };
    });

  const legend = Object.freeze({
    entertainment: Object.freeze([
      'Conciertos (Megaescenario)',
      'Mushuc Park',
      'Resbaladera gigante',
      'Juegos mecánicos',
      'Shows cómicos',
      'Parque de dinosaurios',
    ]),
    stands: Object.freeze([
      'Auspiciantes',
      'Corporativos VIP',
      'Comercio',
      'Negocios',
      'Artesanales',
      'Productores',
    ]),
    administration: Object.freeze([
      'Boleterías',
      'Oficina de ventas y dispensario médico',
      'Plaza de toros',
      'Plaza de la Luna',
      'Granja',
      'Punto de hidratación',
      'Estacionamientos',
      'Baños',
      'Ingreso peatonal',
    ]),
    accesses: Object.freeze([
      'Acceso 1 · Turistas',
      'Acceso 2 · Expositores, auspiciantes, Patio Luna y turistas',
      'Acceso 3 · Turistas',
      'Acceso 4 · Negocios, auspiciantes, Patio Mega y turistas',
      'Acceso 5 · Expositores y turistas',
      'Acceso 6 · Turistas',
    ]),
    parking: Object.freeze([
      'Acceso 1 · S, T, W, X, Y, Z',
      'Acceso 2 · A, C, D, K, L, M, E1, E2',
      'Acceso 3 · F, G, I, J, L, M, O, P',
      'Acceso 4 · O, P, U, R',
      'Acceso 5 · V1, V2, S, T, W, X',
      'Acceso 6 · Z, Y, W, T, S, X',
    ]),
  });

  root.MR_LEGACY_PLACES_V2 = Object.freeze(legacyPlaces.map(clone));
  root.MR_MAP_PLACES_V3 = Object.freeze(officialPlaces.map(clone));
  root.MR_MAP_LEGEND_V1 = legend;
})(typeof globalThis !== 'undefined' ? globalThis : window);
