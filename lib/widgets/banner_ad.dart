import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob のユニットID。
///
/// debug ビルドでは Google 公式のテスト用IDを利用し、
/// リリースビルドでのみ本番のバナーIDを利用する。
class AdMobID {
  final appId = 'ca-app-pub-9554523900151411~9493931347';
  final adId = 'ca-app-pub-9554523900151411/4968628903';

  /// Google 公式のテスト用バナーユニットID。
  static const _androidTestUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestUnitId = 'ca-app-pub-3940256099942544/2934735716';

  String get bannerUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _androidTestUnitId : _iosTestUnitId;
    }
    return adId;
  }
}

/// 画面下部に表示する適応型アンカーバナー広告。
///
/// 読み込みが完了するまでは何も表示せず、レイアウトを詰めておく。
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 端末幅に応じた適応型バナーサイズを取得するため、
    // MediaQuery が使える didChangeDependencies で読み込む。
    if (_bannerAd == null) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null) {
      debugPrint('Unable to get adaptive banner size.');
      return;
    }

    final ad = BannerAd(
      adUnitId: AdMobID().bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    );

    await ad.load();
    if (!mounted) {
      ad.dispose();
      return;
    }
    setState(() => _bannerAd = ad);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
