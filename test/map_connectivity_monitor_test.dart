import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_connectivity_monitor.dart';

class _Resolver implements HostResolver {
  _Resolver(this.action);
  final Future<List<String>> Function(String host) action;

  @override
  Future<List<String>> resolve(String host) => action(host);
}

void main() {
  test('devuelve true con DNS disponible y false ante error', () async {
    expect(
      await MapConnectivityMonitor(
        resolver: _Resolver((_) async => <String>['1.1.1.1']),
      ).check(),
      isTrue,
    );
    expect(
      await MapConnectivityMonitor(
        resolver: _Resolver((_) => Future<List<String>>.error('sin red')),
      ).check(),
      isFalse,
    );
  });

  test('un timeout devuelve false sin propagar excepción', () async {
    final monitor = MapConnectivityMonitor(
      resolver: _Resolver((_) => Completer<List<String>>().future),
      timeout: const Duration(milliseconds: 5),
    );
    expect(await monitor.check(), isFalse);
  });
}
