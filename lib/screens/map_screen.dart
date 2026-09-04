import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../design/brand_theme.dart';
import '../shell/fair_location.dart';

class MapScreen extends StatefulWidget {
  final bool active;

  const MapScreen({super.key, this.active = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _wc;
  bool _loading = true;
  bool _pageReady = false;
  bool _gpsStarted = false;
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
            _pageReady = true;
            await _startGpsWhenVisible();
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadFlutterAsset('assets/map/index.html');
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _startGpsWhenVisible();
    }
  }

  Future<void> _startGpsWhenVisible() async {
    if (!widget.active || !_pageReady || _gpsStarted) return;
    _gpsStarted = true;
    await _wc.runJavaScript('startGPS();');
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
        locationSettings: FairLocation.initialLocationSettings,
      );
      final distMeters = Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        FairLocation.latitude,
        FairLocation.longitude,
      );
      if (distMeters > FairLocation.radiusMeters) {
        _reject(id, 2, 'Estás fuera del recinto');
        if (!_promptingMaps && mounted) {
          _promptingMaps = true;
          await _promptOpenMaps(distMeters);
          _promptingMaps = false;
        }
        return;
      }
      _resolve(id, p);
      if (kind == 'watch') {
        _posSub?.cancel();
        _posSub =
            Geolocator.getPositionStream(
              locationSettings: FairLocation.trackingLocationSettings,
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
    const bottomNavGap = 96.0;
    return ColoredBox(
      color: const Color(0xFF94BD78),
      child: Padding(
        padding: EdgeInsets.only(top: topPad, bottom: bottomNavGap),
        child: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _wc)),
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
