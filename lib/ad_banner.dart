import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_html/flutter_html.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  late BannerAd _ad;
  bool _isLoaded = false;
  
  final String _adUnitId = kIsWeb
      ? '' 
      : kDebugMode
          ? Platform.isAndroid
              ? 'ca-app-pub-3940256099942544/6300978111'
              : 'ca-app-pub-3940256099942544/2934735716'
          : Platform.isAndroid
              ? 'ca-app-pub-3648508587330827/7781947128'
              : 'ca-app-pub-3648508587330827/6806974478';
            
  final String _adSenseCode = '''
    <ins class="adsbygoogle"
         style="display:block"
         data-ad-client="ca-pub-3648508587330827"
         data-ad-slot="SEU_AD_SLOT_ID_AQUI"
         data-ad-format="auto"
         data-full-width-responsive="true"></ins>
    <script>
      (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
  ''';
            
  @override
  void initState() {
    super.initState();
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
    if (_isLoaded) { 
        _ad.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Html(
        data: _adSenseCode,
      );
    } else if (_isLoaded) { 
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