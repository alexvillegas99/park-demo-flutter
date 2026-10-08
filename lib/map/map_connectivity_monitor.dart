import 'dart:async';
import 'dart:io';

abstract interface class HostResolver {
  Future<List<String>> resolve(String host);
}

class InternetHostResolver implements HostResolver {
  const InternetHostResolver();

  @override
  Future<List<String>> resolve(String host) async =>
      (await InternetAddress.lookup(
        host,
      )).map((address) => address.address).toList();
}

class MapConnectivityMonitor {
  const MapConnectivityMonitor({
    HostResolver resolver = const InternetHostResolver(),
    this.timeout = const Duration(seconds: 3),
  }) : _resolver = resolver;

  final HostResolver _resolver;
  final Duration timeout;

  Future<bool> check() async {
    try {
      final addresses = await _resolver
          .resolve('maps.googleapis.com')
          .timeout(timeout);
      return addresses.isNotEmpty;
    } on Object {
      return false;
    }
  }
}
