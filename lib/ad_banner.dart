// ad_banner.dart

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late BannerAd _ad;
  bool _isLoaded = false;
  
  final String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // ID de teste do AdMob
      : 'ca-app-pub-3648508587330827/7781947128'; // Substitua pelo seu ID de produção

  @override
  void initState() {
    super.initState();
    _loadAd();
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
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
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