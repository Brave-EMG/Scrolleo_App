import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'feexpay_launcher_stub.dart'
    if (dart.library.html) 'feexpay_launcher_web.dart';
import 'feexpay_webview_stub.dart'
    if (dart.library.io) 'feexpay_webview_mobile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;
import '../config/environment.dart';

class CoinPack {
  final String id;
  final String name;
  final int price;
  final int coins;
  final String description;

  CoinPack({
    required this.id,
    required this.name,
    required this.price,
    required this.coins,
    required this.description,
  });

  factory CoinPack.fromJson(Map<String, dynamic> json) {
    return CoinPack(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      coins: json['coins'],
      description: json['description'],
    );
  }
}

class FeexpayButtonWeb extends StatefulWidget {
  final Map<String, dynamic> feexpayParams;
  final VoidCallback? onClose;
  const FeexpayButtonWeb({Key? key, required this.feexpayParams, this.onClose}) : super(key: key);

  @override
  State<FeexpayButtonWeb> createState() => _FeexpayButtonWebState();
}

class _FeexpayButtonWebState extends State<FeexpayButtonWeb> {
  late String _viewType;
  html.DivElement? _container;

  @override
  void initState() {
    super.initState();
    _viewType = 'feexpay-btn-${DateTime.now().millisecondsSinceEpoch}';
    _container = html.DivElement()
      ..id = 'render-$_viewType'
      ..style.width = '100%'
      ..style.backgroundColor = 'transparent'
      ..style.border = 'none'
      ..style.borderRadius = '0'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.alignItems = 'center'
      ..style.padding = '0';
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _container!);
    _injectFeexpayScript();
  }

  void _injectFeexpayScript() {
    if (html.document.getElementById('feexpay-sdk') == null) {
      final script = html.ScriptElement()
        ..id = 'feexpay-sdk'
        ..src = 'https://api.feexpay.me/feexpay-javascript-sdk/index.js';
      html.document.body!.append(script);
      script.onLoad.listen((_) => _initFeexpayButton());
    } else {
      _initFeexpayButton();
    }
  }

  void _initFeexpayButton() {
    final params = widget.feexpayParams;
    final js = '''
      FeexPayButton.init("${_container!.id}", {
        id: "${params['id']}",
        amount: ${params['amount']},
        token: "${params['token']}",
        callback: function(response) {
          if (response.status === 'success') {
            alert('Paiement réussi !');
            window.location.reload();
          } else {
            alert('Erreur lors du paiement.');
          }
        },
        callback_url: "${params['callback_url']}",
        callback_info: '${params['callback_info']}',
        mode: 'SANDBOX',
        description: "${params['description']}",
        buttonText: "Payer",
        buttonClass: "mt-3",
        defaultValueField: ${jsonEncode(params['defaultValueField'] ?? {})}
      });
    ''';
    html.ScriptElement script = html.ScriptElement()
      ..type = 'text/javascript'
      ..text = js;
    html.document.body!.append(script);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(child: HtmlElementView(viewType: _viewType)),
    );
  }
}

class CoinPacksScreen extends StatefulWidget {
  const CoinPacksScreen({Key? key}) : super(key: key);

  @override
  _CoinPacksScreenState createState() => _CoinPacksScreenState();
}

class _CoinPacksScreenState extends State<CoinPacksScreen> {
  List<CoinPack> _packs = [];
  bool _isLoading = true;
  String? _error;
  String? _token;
  int? _selectedPackIndexWeb;
  Map<String, dynamic>? _feexpayParamsWeb;
  Map<int, Map<String, dynamic>> _feexpayParamsByIndex = {};
  int? _loadingPackIndexWeb;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    _token = authService.jwtToken;
    if (_token == null) {
      Future.microtask(() => _showLoginRequiredDialog());
    } else {
      _loadPacks();
    }
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _preloadAllFeexpayParams();
    }
  }

  Future<void> _showLoginRequiredDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Vous devez être connecté à votre compte pour effectuer cette action.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPacks() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/payments/coins/packs'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _packs = data.map((json) => CoinPack.fromJson(json)).toList();
          _isLoading = false;
        });
        if (kIsWeb) {
          _preloadAllFeexpayParams();
        }
      } else if (response.statusCode == 401) {
        Future.microtask(() => _showLoginRequiredDialog());
      } else {
        setState(() {
          _error = 'Erreur lors du chargement des packs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  Future<void> _preloadAllFeexpayParams() async {
    for (int i = 0; i < _packs.length; i++) {
      final pack = _packs[i];
      try {
        final response = await http.post(
          Uri.parse('${Environment.apiBaseUrl}/payments/params'),
          headers: {
            'Content-Type': 'application/json',
            if (_token != null) 'Authorization': 'Bearer $_token',
          },
          body: json.encode({
            'type': 'coins',
            'planId': pack.id,
          }),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final feexpayParams = data['feexpayParams'];
          if (feexpayParams != null) {
            setState(() {
              _feexpayParamsByIndex[i] = feexpayParams;
            });
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }

  void _showPaymentDialog(BuildContext context, CoinPack pack, int index) async {
    if (kIsWeb) {
      setState(() {
        _selectedPackIndexWeb = index;
        _loadingPackIndexWeb = index;
      });
      // Attendre que les params soient prêts ou timeout 5s
      final start = DateTime.now();
      while (_feexpayParamsByIndex[index] == null && DateTime.now().difference(start).inSeconds < 5) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      setState(() {
        _loadingPackIndexWeb = null;
        _feexpayParamsWeb = _feexpayParamsByIndex[index];
      });
      if (_feexpayParamsWeb != null) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            backgroundColor: Colors.transparent,
            content: SizedBox(
              width: 400,
              height: 480,
              child: FeexpayButtonWeb(feexpayParams: _feexpayParamsWeb!),
            ),
          ),
        );
      }
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/payments/params'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'type': 'coins',
          'planId': pack.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feexpayParams = data['feexpayParams'];
        if (feexpayParams != null) {
          final htmlContent = '''
            <!DOCTYPE html>
            <html>
            <head>
              <title>Paiement Feexpay</title>
              <script src="https://api.feexpay.me/feexpay-javascript-sdk/index.js"></script>
            </head>
            <body>
              <div id="feexpay-button"></div>
              <script>
                const params = ${jsonEncode(feexpayParams)};
                FeexPayButton.init(params);
              </script>
            </body>
            </html>
          ''';

          // Ouvrir le HTML dans une nouvelle fenêtre
          final uri = Uri.dataFromString(
            htmlContent,
            mimeType: 'text/html',
            encoding: Encoding.getByName('utf-8'),
          );
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paramètres Feexpay manquants.')),
          );
        }
      } else if (response.statusCode == 401) {
        Future.microtask(() => _showLoginRequiredDialog());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'achat du pack')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion')),
      );
    }
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Packs de Coins')),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packs de Coins'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.95,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _packs.length,
        itemBuilder: (context, index) {
          final pack = _packs[index];
          return Card(
            color: const Color(0xFF232323),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    pack.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pack.coins} coins',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pack.price} FCFA',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (kIsWeb && _selectedPackIndexWeb == index && _loadingPackIndexWeb == index)
                    Column(
                      children: const [
                        SizedBox(height: 16),
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Chargement du paiement...', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => _showPaymentDialog(context, pack, index),
                        child: const Text('Acheter', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 