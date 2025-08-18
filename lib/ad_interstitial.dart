// ad_interstitial.dart

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io'; // Importe para ter acesso à classe Platform

class AdInterstitial {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  bool get isAdLoaded => _isAdLoaded;

  final String _adUnitId =
      kDebugMode //Verifica se o app está rodando em modo DEBUG ou não.
      ? Platform
                .isAndroid //Se for DEBUG, entra nesse IF/ELSE
            ? 'ca-app-pub-3940256099942544/1033173712' // Teste Android
            : 'ca-app-pub-3940256099942544/4411468910' // Teste iOS
      : Platform.isAndroid //Se não for DEBUG, entra nesse IF/ELSE
      ? 'ca-app-pub-3648508587330827/9202037676' // Seu ID de produção Android
      : 'ca-app-pub-3648508587330827/6806974478'; // Substitua pelo seu ID de produção iOS

  void loadAd() {
    if (_isAdLoaded) return;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          debugPrint('Anúncio intersticial carregado.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Falha ao carregar anúncio intersticial: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd == null) {
      debugPrint('Aviso: Anúncio intersticial não está pronto.');
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Anúncio intersticial exibido.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Anúncio intersticial fechado.');
        ad.dispose();
        _isAdLoaded = false;
        _interstitialAd = null;
        loadAd();

        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('Falha ao exibir anúncio intersticial: $error');
        ad.dispose();
        _isAdLoaded = false;
        _interstitialAd = null;
        loadAd();

        onAdDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }
}
