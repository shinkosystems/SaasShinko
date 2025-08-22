import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late BannerAd _ad;
  bool _isLoaded = false;
  
  // A verificação de plataforma deve ser feita aqui, na inicialização
  final String _adUnitId = kIsWeb
      ? '' // Vazio para a web
      : kDebugMode
          ? Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716'
          : Platform.isAndroid
              ? 'ca-app-pub-3648508587330827/7781947128'
              : 'ca-app-pub-3648508587330827/6806974478';
            
  @override
  void initState() {
    super.initState();
    // A chamada _loadAd() deve ser condicional
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    _ad = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('Anúncio de banner carregado.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Falha ao carregar anúncio de banner: $error');
          ad.dispose();
        },
      ),
    );
    _ad.load();
  }

  @override
  void dispose() {
    if (_isLoaded) { // Dispor o anúncio apenas se ele foi carregado
        _ad.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && _isLoaded) { // Renderizar o anúncio apenas se não for web e se estiver carregado
      return SizedBox(
        width: _ad.size.width.toDouble(),
        height: _ad.size.height.toDouble(),
        child: AdWidget(ad: _ad),
      );
    } else {
      return const SizedBox(
        height: 50,
      );
    }
  }
}