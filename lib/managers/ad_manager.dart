import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // アプリID: ca-app-pub-3971807513032614~6098994742
  // プラットフォーム別の広告ユニットID

  // インタースティシャル広告ユニットID
  static String get _interstitialAdUnitId {
    if (kIsWeb) {
      return ''; // Web環境では使用しない
    }

    try {
      if (Platform.isAndroid) {
        // テスト用Android広告ID（必ず広告が表示される）
        return 'ca-app-pub-3940256099942544/1033173712';
        // 本番用: 'ca-app-pub-3971807513032614/8822179249'
      } else if (Platform.isIOS) {
        // テスト用iOS広告ID（必ず広告が表示される）
        return 'ca-app-pub-3940256099942544/4411468910';
        // 本番用: 'ca-app-pub-3971807513032614/4075466639'
      }
    } catch (e) {
      // Platform情報が取得できない場合
    }

    return 'ca-app-pub-3940256099942544/1033173712'; // デフォルト（Androidテスト用）
  }

  // バナー広告ユニットID
  static String get _bannerAdUnitId {
    if (kIsWeb) {
      return ''; // Web環境では使用しない
    }

    try {
      if (Platform.isAndroid) {
        // テスト用Androidバナー広告ID（必ず広告が表示される）
        return 'ca-app-pub-3940256099942544/6300978111';
        // 本番用: 'ca-app-pub-3971807513032614/2476154940'
      } else if (Platform.isIOS) {
        // テスト用iOSバナー広告ID（必ず広告が表示される）
        return 'ca-app-pub-3940256099942544/2934735716';
        // 本番用: 'ca-app-pub-3971807513032614/7983740292'
      }
    } catch (e) {
      // Platform情報が取得できない場合
    }

    return 'ca-app-pub-3940256099942544/6300978111'; // デフォルト（Androidテスト用）
  }

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  Future<void> initialize() async {
    // Web環境では広告を無効化
    if (kIsWeb) return;

    try {
      await MobileAds.instance.initialize();
      _loadInterstitialAd();
      _loadBannerAd();
    } catch (e) {
      // 初期化エラーを無視
    }
  }

  void _loadBannerAd() {
    // Web環境では広告を読み込まない
    if (kIsWeb) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isBannerAdLoaded = false;
            // 失敗したら少し待ってから再読み込み
            Future.delayed(const Duration(seconds: 5), () {
              _loadBannerAd();
            });
          },
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      _isBannerAdLoaded = false;
    }
  }

  void _loadInterstitialAd() {
    // Web環境では広告を読み込まない
    if (kIsWeb) return;

    try {
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _isAdLoaded = false;
                _loadInterstitialAd(); // 次の広告をプリロード
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _isAdLoaded = false;
                _loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isAdLoaded = false;
            // 失敗したら少し待ってから再読み込み
            Future.delayed(const Duration(seconds: 5), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      _isAdLoaded = false;
    }
  }

  Future<void> showInterstitialAd({required Function onAdClosed}) async {
    // Web環境では広告をスキップ
    if (kIsWeb) {
      onAdClosed();
      return;
    }

    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();
          onAdClosed();
        },
      );

      await _interstitialAd!.show();
    } else {
      // 広告が読み込まれていない場合はすぐにコールバックを実行
      onAdClosed();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
  }
}
