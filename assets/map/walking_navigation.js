(function (root) {
  'use strict';

  class WalkingRouteError extends Error {
    constructor(code, message, details) {
      super(message);
      this.name = 'WalkingRouteError';
      this.code = code;
      this.details = details || {};
    }
  }

  function copyPoint(point) {
    return {x: Number(point.x), y: Number(point.y)};
  }

  function deduplicate(points) {
    return points.filter((point, index) => {
      if (index === 0) return true;
      const previous = points[index - 1];
      return point.x !== previous.x || point.y !== previous.y;
    });
  }

  class WalkingRouteGraph {
    constructor(document, geometry) {
      if (!document || !Array.isArray(document.nodes) || !Array.isArray(document.edges)) {
        throw new WalkingRouteError('invalid_graph', 'La red peatonal no es válida');
      }
      this.geometry = geometry;
      this.nodes = new Map(document.nodes.map((node) => [node.id, {...node}]));
      this.adjacency = new Map([...this.nodes.keys()].map((id) => [id, []]));
      for (const edge of document.edges) {
        const first = this.nodes.get(edge.from);
        const second = this.nodes.get(edge.to);
        if (!first || !second) {
          throw new WalkingRouteError('invalid_graph', 'La red contiene una conexión inválida');
        }
        const weight = this.geometry.distanceMeters(first, second);
        this.adjacency.get(first.id).push({id: second.id, weight});
        this.adjacency.get(second.id).push({id: first.id, weight});
      }
    }

    snap(point, toleranceMeters = 35) {
      let closest = null;
      for (const node of this.nodes.values()) {
        const distanceMeters = this.geometry.distanceMeters(point, node);
        if (!closest || distanceMeters < closest.distanceMeters) {
          closest = {node: {...node}, distanceMeters};
        }
      }
      if (!closest || closest.distanceMeters > toleranceMeters) {
        throw new WalkingRouteError(
          'point_not_connected',
          'Este punto todavía no está conectado a la red peatonal',
          {distanceMeters: closest ? closest.distanceMeters : null},
        );
      }
      return closest;
    }

    connectedComponents() {
      const pending = new Set(this.nodes.keys());
      const components = [];
      while (pending.size) {
        const first = pending.values().next().value;
        const component = [];
        const queue = [first];
        pending.delete(first);
        while (queue.length) {
          const current = queue.shift();
          component.push(current);
          for (const edge of this.adjacency.get(current)) {
            if (pending.delete(edge.id)) queue.push(edge.id);
          }
        }
        components.push(component);
      }
      return components;
    }

    route(origin, destination) {
      const start = this.snap(origin);
      const finish = this.snap(destination);
      const frontier = new Set([start.node.id]);
      const cameFrom = new Map();
      const cost = new Map([[start.node.id, 0]]);
      const estimate = new Map([[
        start.node.id,
        this.geometry.distanceMeters(start.node, finish.node),
      ]]);

      while (frontier.size) {
        let current = null;
        let best = Infinity;
        for (const id of frontier) {
          const score = estimate.get(id) ?? Infinity;
          if (score < best) {
            best = score;
            current = id;
          }
        }
        if (current === finish.node.id) break;
        frontier.delete(current);
        for (const edge of this.adjacency.get(current)) {
          const candidate = cost.get(current) + edge.weight;
          if (candidate >= (cost.get(edge.id) ?? Infinity)) continue;
          cameFrom.set(edge.id, current);
          cost.set(edge.id, candidate);
          estimate.set(
            edge.id,
            candidate + this.geometry.distanceMeters(this.nodes.get(edge.id), finish.node),
          );
          frontier.add(edge.id);
        }
      }

      if (!cost.has(finish.node.id)) {
        throw new WalkingRouteError('no_route', 'No existe una ruta peatonal disponible');
      }
      const nodeIds = [finish.node.id];
      while (nodeIds[0] !== start.node.id) nodeIds.unshift(cameFrom.get(nodeIds[0]));
      const polyline = deduplicate([
        copyPoint(origin),
        ...nodeIds.map((id) => copyPoint(this.nodes.get(id))),
        copyPoint(destination),
      ]);
      return {
        polyline,
        distanceMeters: this.polylineDistance(polyline),
        startSnap: start,
        endSnap: finish,
        accessId: finish.node.accessId || null,
      };
    }

    polylineDistance(polyline) {
      let distance = 0;
      for (let index = 1; index < polyline.length; index += 1) {
        distance += this.geometry.distanceMeters(polyline[index - 1], polyline[index]);
      }
      return distance;
    }

    distanceToRoute(point, polyline) {
      return this._projection(point, polyline).distanceMeters;
    }

    _projection(point, polyline) {
      let closest = null;
      let completedBefore = 0;
      let travelled = 0;
      for (let index = 1; index < polyline.length; index += 1) {
        const first = polyline[index - 1];
        const second = polyline[index];
        const dx = second.x - first.x;
        const dy = second.y - first.y;
        const denominator = dx * dx + dy * dy;
        const raw = denominator === 0
          ? 0
          : ((point.x - first.x) * dx + (point.y - first.y) * dy) / denominator;
        const ratio = Math.max(0, Math.min(1, raw));
        const projected = {x: first.x + dx * ratio, y: first.y + dy * ratio};
        const distanceMeters = this.geometry.distanceMeters(point, projected);
        const segmentMeters = this.geometry.distanceMeters(first, second);
        if (!closest || distanceMeters < closest.distanceMeters) {
          closest = {
            point: projected,
            distanceMeters,
            segmentIndex: index - 1,
            ratio,
            completedMeters: travelled + segmentMeters * ratio,
          };
        }
        travelled += segmentMeters;
        completedBefore = travelled;
      }
      return closest || {
        point: copyPoint(polyline[0]),
        distanceMeters: this.geometry.distanceMeters(point, polyline[0]),
        segmentIndex: 0,
        ratio: 0,
        completedMeters: completedBefore,
      };
    }
  }

  class WalkingNavigationSession {
    constructor(graph) {
      this.graph = graph;
      this.state = null;
      this.destination = null;
    }

    start(origin, destination) {
      const route = this.graph.route(origin, destination);
      this.destination = copyPoint(destination);
      this.state = {
        polyline: route.polyline,
        completedPolyline: [copyPoint(route.polyline[0])],
        remainingPolyline: route.polyline.map(copyPoint),
        totalMeters: route.distanceMeters,
        remainingMeters: route.distanceMeters,
        progress: 0,
        arrived: false,
        offRouteCount: 0,
        recalculations: 0,
        arrivalRadiusMeters: 6,
        accessId: route.accessId,
      };
      return this.snapshot();
    }

    update(sample) {
      if (!this.state) return null;
      const point = copyPoint(sample);
      const accuracy = Number.isFinite(Number(sample.accuracy))
        ? Number(sample.accuracy)
        : 6;
      this.state.arrivalRadiusMeters = Math.max(6, Math.min(accuracy, 15));
      const distanceToDestination = this.graph.geometry.distanceMeters(
        point,
        this.destination,
      );
      if (distanceToDestination <= this.state.arrivalRadiusMeters) {
        this.state.arrived = true;
        this.state.remainingMeters = 0;
        this.state.progress = 1;
        this.state.completedPolyline = this.state.polyline.map(copyPoint);
        this.state.remainingPolyline = [copyPoint(this.destination)];
        return this.snapshot();
      }

      const routeDistance = this.graph.distanceToRoute(point, this.state.polyline);
      if (routeDistance > 15) this.state.offRouteCount += 1;
      else this.state.offRouteCount = 0;
      if (this.state.offRouteCount >= 2) {
        const recalculations = this.state.recalculations + 1;
        const route = this.graph.route(point, this.destination);
        this.state.polyline = route.polyline;
        this.state.totalMeters = route.distanceMeters;
        this.state.offRouteCount = 0;
        this.state.recalculations = recalculations;
        this.state.accessId = route.accessId;
      }

      const projection = this.graph._projection(point, this.state.polyline);
      const index = projection.segmentIndex;
      this.state.completedPolyline = [
        ...this.state.polyline.slice(0, index + 1).map(copyPoint),
        copyPoint(projection.point),
      ];
      this.state.remainingPolyline = [
        copyPoint(projection.point),
        ...this.state.polyline.slice(index + 1).map(copyPoint),
      ];
      this.state.remainingMeters = Math.max(
        0,
        this.graph.polylineDistance(this.state.remainingPolyline),
      );
      this.state.progress = this.state.totalMeters <= 0
        ? 1
        : Math.max(0, Math.min(1, 1 - this.state.remainingMeters / this.state.totalMeters));
      return this.snapshot();
    }

    snapshot() {
      return this.state ? JSON.parse(JSON.stringify(this.state)) : null;
    }

    finish() {
      this.state = null;
      this.destination = null;
      return null;
    }
  }

  Object.assign(root, {
    WalkingRouteError,
    WalkingRouteGraph,
    WalkingNavigationSession,
  });
})(typeof globalThis !== 'undefined' ? globalThis : window);
