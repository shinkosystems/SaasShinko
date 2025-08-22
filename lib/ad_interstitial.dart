import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AdInterstitial {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  bool get isAdLoaded => _isAdLoaded;

  final String _adUnitId = kIsWeb
      ? ''
      : kDebugMode
          ? Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/1033173712'
              : 'ca-app-pub-3940256099942544/4411468910'
          : Platform.isAndroid
              ? 'ca-app-pub-3648508587330827/9202037676'
              : 'ca-app-pub-3648508587330827/6806974478';

  void loadAd() {
    // A chamada _loadAd() deve ser condicional
    if (!kIsWeb && !_isAdLoaded) {
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
  }

  void showAd({VoidCallback? onAdDismissed}) {
    if (!kIsWeb && _interstitialAd != null) {
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
    } else {
      debugPrint('Aviso: Anúncio intersticial não está pronto ou é um ambiente web.');
      onAdDismissed?.call();
    }
  }
}