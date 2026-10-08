(function (root) {
  'use strict';

  const WIDTH = 1600;
  const HEIGHT = 1327;
  const ORIGIN_LAT = -1.369;
  const ORIGIN_LNG = -78.648;
  const METERS_PER_LATITUDE_DEGREE = 111132;
  const METERS_PER_LONGITUDE_DEGREE =
    111320 * Math.cos((ORIGIN_LAT * Math.PI) / 180);

  const controls = [
    {
      id: 'access-1',
      lat: -1.3684769962114673,
      lng: -78.65151912830171,
      x: 690,
      y: 120,
    },
    {
      id: 'access-3',
      lat: -1.3721312850255056,
      lng: -78.6506831995043,
      x: 160,
      y: 1060,
    },
    {
      id: 'access-5',
      lat: -1.3657756022784497,
      lng: -78.64414004716147,
      x: 1300,
      y: 525,
    },
    {
      id: 'access-6',
      lat: -1.365766258405764,
      lng: -78.64403182422295,
      x: 1415,
      y: 305,
    },
  ];

  const legacyGeoreference = Object.freeze({
    p: 0.44185994261082073,
    q: 0.03809624037398862,
    tx: -408.432125697813,
    ty: 271.33543876584343,
    mlat: 111132,
    mlng: 111288.229743186,
    scale: 1900 / 2830,
  });

  function localMeters(lat, lng) {
    return {
      x: (lng - ORIGIN_LNG) * METERS_PER_LONGITUDE_DEGREE,
      y: (lat - ORIGIN_LAT) * METERS_PER_LATITUDE_DEGREE,
    };
  }

  function solve3(matrix, values) {
    const augmented = matrix.map((row, index) => [
      ...row,
      values[index],
    ]);
    for (let column = 0; column < 3; column += 1) {
      let pivot = column;
      for (let row = column + 1; row < 3; row += 1) {
        if (
          Math.abs(augmented[row][column]) >
          Math.abs(augmented[pivot][column])
        ) {
          pivot = row;
        }
      }
      [augmented[column], augmented[pivot]] = [
        augmented[pivot],
        augmented[column],
      ];
      const divisor = augmented[column][column];
      if (Math.abs(divisor) < 1e-12) {
        throw new Error('Los puntos de calibración no son independientes');
      }
      for (let index = column; index < 4; index += 1) {
        augmented[column][index] /= divisor;
      }
      for (let row = 0; row < 3; row += 1) {
        if (row === column) continue;
        const factor = augmented[row][column];
        for (let index = column; index < 4; index += 1) {
          augmented[row][index] -= factor * augmented[column][index];
        }
      }
    }
    return augmented.map((row) => row[3]);
  }

  function leastSquares(axis) {
    const rows = controls.map((control) => {
      const meters = localMeters(control.lat, control.lng);
      return [meters.x, meters.y, 1];
    });
    const normal = Array.from({ length: 3 }, (_, row) =>
      Array.from({ length: 3 }, (_, column) =>
        rows.reduce(
          (sum, values) => sum + values[row] * values[column],
          0,
        ),
      ),
    );
    const target = rows.map((_, index) => controls[index][axis]);
    const projected = Array.from({ length: 3 }, (_, row) =>
      rows.reduce(
        (sum, values, index) => sum + values[row] * target[index],
        0,
      ),
    );
    return solve3(normal, projected);
  }

  const xCoefficients = leastSquares('x');
  const yCoefficients = leastSquares('y');
  const determinant =
    xCoefficients[0] * yCoefficients[1] -
    xCoefficients[1] * yCoefficients[0];

  function toMap(lat, lng) {
    const meters = localMeters(Number(lat), Number(lng));
    return {
      x:
        xCoefficients[0] * meters.x +
        xCoefficients[1] * meters.y +
        xCoefficients[2],
      y:
        yCoefficients[0] * meters.x +
        yCoefficients[1] * meters.y +
        yCoefficients[2],
    };
  }

  function toLatLng(x, y) {
    const translatedX = Number(x) - xCoefficients[2];
    const translatedY = Number(y) - yCoefficients[2];
    const metersX =
      (translatedX * yCoefficients[1] -
        xCoefficients[1] * translatedY) /
      determinant;
    const metersY =
      (xCoefficients[0] * translatedY -
        translatedX * yCoefficients[0]) /
      determinant;
    return {
      lat: ORIGIN_LAT + metersY / METERS_PER_LATITUDE_DEGREE,
      lng: ORIGIN_LNG + metersX / METERS_PER_LONGITUDE_DEGREE,
    };
  }

  function distanceMeters(first, second) {
    const a = toLatLng(first.x, first.y);
    const b = toLatLng(second.x, second.y);
    const averageLatitude = ((a.lat + b.lat) / 2) * (Math.PI / 180);
    const north = (b.lat - a.lat) * METERS_PER_LATITUDE_DEGREE;
    const east =
      (b.lng - a.lng) * 111320 * Math.cos(averageLatitude);
    return Math.hypot(east, north);
  }

  function legacyToLatLng(x, y) {
    const ex = Number(x) / legacyGeoreference.scale;
    const ey = Number(y) / legacyGeoreference.scale;
    const projectedX =
      legacyGeoreference.tx +
      legacyGeoreference.p * ex +
      legacyGeoreference.q * ey;
    const projectedY =
      legacyGeoreference.ty +
      legacyGeoreference.q * ex -
      legacyGeoreference.p * ey;
    return {
      lat: projectedY / legacyGeoreference.mlat - 1.369,
      lng: projectedX / legacyGeoreference.mlng - 78.65,
    };
  }

  function migrateLegacyPoint(point, legacySeed, officialSeed) {
    const unchanged =
      legacySeed &&
      officialSeed &&
      Math.hypot(
        Number(point.x) - Number(legacySeed.x),
        Number(point.y) - Number(legacySeed.y),
      ) <= 1;
    if (unchanged) {
      return {
        x: Number(officialSeed.x),
        y: Number(officialSeed.y),
        needsReview: false,
      };
    }
    const location = legacyToLatLng(point.x, point.y);
    const migrated = toMap(location.lat, location.lng);
    return {
      x: Math.max(0, Math.min(WIDTH, migrated.x)),
      y: Math.max(0, Math.min(HEIGHT, migrated.y)),
      needsReview: true,
    };
  }

  const calibrationResiduals = controls.map((control) => {
    const mapped = toMap(control.lat, control.lng);
    return {
      id: control.id,
      pixels: Math.hypot(mapped.x - control.x, mapped.y - control.y),
    };
  });

  root.MapGeometryV3 = Object.freeze({
    width: WIDTH,
    height: HEIGHT,
    controls: controls.map((control) => Object.freeze({ ...control })),
    calibrationResiduals,
    toMap,
    toLatLng,
    distanceMeters,
    migrateLegacyPoint,
  });
})(typeof globalThis !== 'undefined' ? globalThis : window);
