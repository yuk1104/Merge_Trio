import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // 広告インスタンス
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;

  // 広告読み込み状態
  bool _isAdLoaded = false;
  bool _isBannerAdLoaded = false;
  bool _isRewardedAdLoaded = false;

  // 広告表示カウンター（3回に1回表示）
  static const String _restartCountKey = 'restart_count';
  static const int _adFrequency = 3;
  int _restartCount = 0;

  // 広告設定
  static const bool _useTestAds = false;

  // 広告ユニットID定数
  static const _AdUnitIds _testAdIds = _AdUnitIds(
    interstitialAndroid: 'ca-app-pub-3940256099942544/1033173712',
    interstitialIOS: 'ca-app-pub-3940256099942544/4411468910',
    bannerAndroid: 'ca-app-pub-3940256099942544/6300978111',
    bannerIOS: 'ca-app-pub-3940256099942544/2934735716',
    rewardedAndroid: 'ca-app-pub-3940256099942544/5224354917',
    rewardedIOS: 'ca-app-pub-3940256099942544/1712485313',
  );

  static const _AdUnitIds _prodAdIds = _AdUnitIds(
    interstitialAndroid: 'ca-app-pub-3971807513032614/8822179249',
    interstitialIOS: 'ca-app-pub-3971807513032614/4075466639',
    bannerAndroid: 'ca-app-pub-3971807513032614/2476154940',
    bannerIOS: 'ca-app-pub-3971807513032614/7983740292',
    rewardedAndroid: 'ca-app-pub-3971807513032614/4576113138',
    rewardedIOS: 'ca-app-pub-3971807513032614/4576113138',
  );

  // Getters
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  // 広告ユニットID取得（共通メソッド）
  static String _getAdUnitId({
    required String androidId,
    required String iosId,
    required String defaultId,
  }) {
    if (kIsWeb) return '';

    try {
      if (Platform.isAndroid) return androidId;
      if (Platform.isIOS) return iosId;
    } catch (e) {
      debugPrint('Platform check failed: $e');
    }

    return defaultId;
  }

  static String get _interstitialAdUnitId {
    final ids = _useTestAds ? _testAdIds : _prodAdIds;
    return _getAdUnitId(
      androidId: ids.interstitialAndroid,
      iosId: ids.interstitialIOS,
      defaultId: ids.interstitialAndroid,
    );
  }

  static String get _bannerAdUnitId {
    final ids = _useTestAds ? _testAdIds : _prodAdIds;
    return _getAdUnitId(
      androidId: ids.bannerAndroid,
      iosId: ids.bannerIOS,
      defaultId: ids.bannerAndroid,
    );
  }

  static String get _rewardedAdUnitId {
    final ids = _useTestAds ? _testAdIds : _prodAdIds;
    return _getAdUnitId(
      androidId: ids.rewardedAndroid,
      iosId: ids.rewardedIOS,
      defaultId: ids.rewardedAndroid,
    );
  }

  // 初期化
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await _loadRestartCount();
      await MobileAds.instance.initialize();
      debugPrint('AdMob initialized successfully');

      _loadInterstitialAd();
      _loadBannerAd();
      _loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  // リスタートカウンター管理
  Future<void> _loadRestartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _restartCount = prefs.getInt(_restartCountKey) ?? 0;
      debugPrint('Loaded restart count: $_restartCount');
    } catch (e) {
      debugPrint('Failed to load restart count: $e');
      _restartCount = 0;
    }
  }

  Future<void> _saveRestartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_restartCountKey, _restartCount);
      debugPrint('Saved restart count: $_restartCount');
    } catch (e) {
      debugPrint('Failed to save restart count: $e');
    }
  }

  // バナー広告
  void _loadBannerAd() {
    if (kIsWeb) return;

    try {
      debugPrint('Loading banner ad with ID: $_bannerAdUnitId');
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.message}');
            ad.dispose();
            _isBannerAdLoaded = false;
            Future.delayed(const Duration(seconds: 5), _loadBannerAd);
          },
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Banner ad loading exception: $e');
      _isBannerAdLoaded = false;
    }
  }

  // インタースティシャル広告
  void _loadInterstitialAd() {
    if (kIsWeb) return;

    try {
      debugPrint('Loading interstitial ad with ID: $_interstitialAdUnitId');
      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isAdLoaded = true;
            _setupInterstitialCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: ${error.message}');
            _isAdLoaded = false;
            Future.delayed(const Duration(seconds: 5), _loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial ad loading exception: $e');
      _isAdLoaded = false;
    }
  }

  void _setupInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _isAdLoaded = false;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _isAdLoaded = false;
        _loadInterstitialAd();
      },
    );
  }

  Future<void> showInterstitialAd({required Function onAdClosed}) async {
    if (kIsWeb) {
      onAdClosed();
      return;
    }

    _restartCount++;
    await _saveRestartCount();

    final shouldShowAd = _restartCount % _adFrequency == 0;
    debugPrint('Restart count: $_restartCount, Should show ad: $shouldShowAd');

    if (shouldShowAd && _isAdLoaded && _interstitialAd != null) {
      debugPrint('Showing interstitial ad');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial ad failed to show: ${error.message}');
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();
          onAdClosed();
        },
      );

      await _interstitialAd!.show();
    } else {
      debugPrint(shouldShowAd
          ? 'Interstitial ad not ready, skipping'
          : 'Skipping ad (not every 3rd restart)');
      onAdClosed();
    }
  }

  // リワード広告
  void _loadRewardedAd() {
    if (kIsWeb) return;

    try {
      debugPrint('Loading rewarded ad with ID: $_rewardedAdUnitId');
      RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded successfully');
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
            _setupRewardedCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: ${error.message}');
            _isRewardedAdLoaded = false;
            Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('Rewarded ad loading exception: $e');
      _isRewardedAdLoaded = false;
    }
  }

  void _setupRewardedCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed');
        ad.dispose();
        _isRewardedAdLoaded = false;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _isRewardedAdLoaded = false;
        _loadRewardedAd();
      },
    );
  }

  Future<void> showRewardedAd({required Function(bool) onComplete}) async {
    if (kIsWeb) {
      onComplete(false);
      return;
    }

    if (!_isRewardedAdLoaded || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      onComplete(false);
      return;
    }

    debugPrint('Showing rewarded ad');
    bool rewarded = false;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed, rewarded: $rewarded');
        ad.dispose();
        _isRewardedAdLoaded = false;
        _loadRewardedAd();
        onComplete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _isRewardedAdLoaded = false;
        _loadRewardedAd();
        onComplete(false);
      },
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}

// 広告ユニットIDの構造体
class _AdUnitIds {
  final String interstitialAndroid;
  final String interstitialIOS;
  final String bannerAndroid;
  final String bannerIOS;
  final String rewardedAndroid;
  final String rewardedIOS;

  const _AdUnitIds({
    required this.interstitialAndroid,
    required this.interstitialIOS,
    required this.bannerAndroid,
    required this.bannerIOS,
    required this.rewardedAndroid,
    required this.rewardedIOS,
  });
}
