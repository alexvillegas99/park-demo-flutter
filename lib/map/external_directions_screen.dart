import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExternalDirectionsUri {
  const ExternalDirectionsUri._();

  static const Set<String> _allowedHosts = <String>{
    'google.com',
    'www.google.com',
    'maps.google.com',
  };

  static Uri googleWalking({
    required double destinationLat,
    required double destinationLng,
  }) => Uri.https('www.google.com', '/maps/dir/', <String, String>{
    'api': '1',
    'destination': '$destinationLat,$destinationLng',
    'travelmode': 'walking',
  });

  static bool isAllowed(Uri uri) =>
      uri.scheme == 'https' &&
      _allowedHosts.contains(uri.host.toLowerCase()) &&
      uri.path.startsWith('/maps');
}

typedef ExternalDirectionsLauncher = Future<bool> Function(Uri uri);

class ExternalDirectionsScreen extends StatefulWidget {
  const ExternalDirectionsScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    this.webViewOverride,
    this.initialErrorMessage,
    this.onOpenExternal,
  });

  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final Widget? webViewOverride;
  final String? initialErrorMessage;
  final ExternalDirectionsLauncher? onOpenExternal;

  @override
  State<ExternalDirectionsScreen> createState() =>
      _ExternalDirectionsScreenState();
}

class _ExternalDirectionsScreenState extends State<ExternalDirectionsScreen> {
  WebViewController? _controller;
  late final Uri _uri;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _uri = ExternalDirectionsUri.googleWalking(
      destinationLat: widget.destinationLat,
      destinationLng: widget.destinationLng,
    );
    _errorMessage = widget.initialErrorMessage;
    if (widget.webViewOverride == null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF7F5EF))
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final requested = Uri.tryParse(request.url);
              if (requested != null &&
                  ExternalDirectionsUri.isAllowed(requested)) {
                return NavigationDecision.navigate;
              }
              _showError('Se bloqueó una salida no segura del mapa');
              return NavigationDecision.prevent;
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == true) {
                _showError(
                  'No pudimos cargar las indicaciones. Revisa tu conexión.',
                );
              }
            },
          ),
        )
        ..loadRequest(_uri);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
  }

  Future<void> _openExternal() async {
    final launcher =
        widget.onOpenExternal ??
        (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
    final opened = await launcher(_uri);
    if (!opened) _showError('No se pudo abrir el navegador');
  }

  @override
  Widget build(BuildContext context) {
    final map =
        widget.webViewOverride ?? WebViewWidget(controller: _controller!);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EF),
      appBar: AppBar(
        title: Text('Cómo llegar a ${widget.destinationName}'),
        backgroundColor: const Color(0xFF7A0708),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: map),
          if (_errorMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                elevation: 8,
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFF0A0203),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _openExternal,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7A0708),
                        ),
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Abrir en navegador'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
