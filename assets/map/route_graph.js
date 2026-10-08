(function (root) {
  'use strict';

  const nodes = [
    {id: 'access-1', x: 690, y: 120, accessId: 11},
    {id: 'north-1', x: 680, y: 300},
    {id: 'north-2', x: 650, y: 500},
    {id: 'access-2', x: 345, y: 555, accessId: 12},
    {id: 'west-1', x: 450, y: 600},
    {id: 'access-3', x: 160, y: 1060, accessId: 13},
    {id: 'west-3', x: 250, y: 900},
    {id: 'west-2', x: 450, y: 800},
    {id: 'plaza-luna', x: 600, y: 685, placeId: 28},
    {id: 'patio-luna', x: 610, y: 650, placeId: 30},
    {id: 'center-south-1', x: 720, y: 720},
    {id: 'center-south-2', x: 810, y: 735},
    {id: 'megaescenario', x: 890, y: 755, placeId: 20},
    {id: 'patio-mega', x: 1010, y: 700, placeId: 31},
    {id: 'plaza-sol', x: 950, y: 610, placeId: 93},
    {id: 'mushuc-park', x: 990, y: 570, placeId: 21},
    {id: 'center-north', x: 800, y: 550},
    {id: 'access-4', x: 1120, y: 970, accessId: 14},
    {id: 'east-south', x: 1050, y: 900},
    {id: 'access-5', x: 1300, y: 525, accessId: 15},
    {id: 'east-mid', x: 1200, y: 560},
    {id: 'access-6', x: 1415, y: 305, accessId: 16},
    {id: 'east-north', x: 1320, y: 400},
  ];

  const edgePairs = [
    ['access-1', 'north-1'],
    ['north-1', 'north-2'],
    ['north-2', 'west-1'],
    ['access-2', 'west-1'],
    ['west-1', 'plaza-luna'],
    ['access-3', 'west-3'],
    ['west-3', 'west-2'],
    ['west-2', 'plaza-luna'],
    ['north-2', 'center-north'],
    ['center-north', 'plaza-sol'],
    ['center-north', 'plaza-luna'],
    ['plaza-luna', 'patio-luna'],
    ['plaza-luna', 'center-south-1'],
    ['center-south-1', 'center-south-2'],
    ['center-south-2', 'megaescenario'],
    ['megaescenario', 'patio-mega'],
    ['patio-mega', 'plaza-sol'],
    ['plaza-sol', 'mushuc-park'],
    ['mushuc-park', 'east-mid'],
    ['patio-mega', 'east-south'],
    ['access-4', 'east-south'],
    ['access-5', 'east-mid'],
    ['access-5', 'east-north'],
    ['access-6', 'east-north'],
  ];

  root.MR_ROUTE_GRAPH_V1 = Object.freeze({
    version: 1,
    nodes: Object.freeze(nodes.map((node) => Object.freeze({...node}))),
    edges: Object.freeze(
      edgePairs.map(([from, to]) => Object.freeze({from, to})),
    ),
  });
})(typeof globalThis !== 'undefined' ? globalThis : window);
