import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // 広告表示カウンター（3回に1回表示）
  static const String _restartCountKey = 'restart_count';
  static const int _adFrequency = 3; // 3回に1回表示
  int _restartCount = 0;

  // アプリID: ca-app-pub-3971807513032614~6098994742
  // プラットフォーム別の広告ユニットID

  // デバッグモード設定（本番環境）
  static const bool _useTestAds = false; // 本番環境ではfalse

  // インタースティシャル広告ユニットID
  static String get _interstitialAdUnitId {
    if (kIsWeb) {
      return ''; // Web環境では使用しない
    }

    // テスト広告を使用する場合
    if (_useTestAds) {
      try {
        if (Platform.isAndroid) {
          return 'ca-app-pub-3940256099942544/1033173712'; // テスト用Android
        } else if (Platform.isIOS) {
          return 'ca-app-pub-3940256099942544/4411468910'; // テスト用iOS
        }
      } catch (e) {
        // Platform情報が取得できない場合
      }
      return 'ca-app-pub-3940256099942544/1033173712'; // デフォルト
    }

    // 本番広告を使用する場合
    try {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3971807513032614/8822179249';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3971807513032614/4075466639';
      }
    } catch (e) {
      // Platform情報が取得できない場合
    }

    return 'ca-app-pub-3971807513032614/8822179249'; // デフォルト（Android本番用）
  }

  // バナー広告ユニットID
  static String get _bannerAdUnitId {
    if (kIsWeb) {
      return ''; // Web環境では使用しない
    }

    // テスト広告を使用する場合
    if (_useTestAds) {
      try {
        if (Platform.isAndroid) {
          return 'ca-app-pub-3940256099942544/6300978111'; // テスト用Android
        } else if (Platform.isIOS) {
          return 'ca-app-pub-3940256099942544/2934735716'; // テスト用iOS
        }
      } catch (e) {
        // Platform情報が取得できない場合
      }
      return 'ca-app-pub-3940256099942544/6300978111'; // デフォルト
    }

    // 本番広告を使用する場合
    try {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3971807513032614/2476154940';
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3971807513032614/7983740292';
      }
    } catch (e) {
      // Platform情報が取得できない場合
    }

    return 'ca-app-pub-3971807513032614/2476154940'; // デフォルト（Android本番用）
  }

  // リワード広告ユニットID
  static String get _rewardedAdUnitId {
    if (kIsWeb) {
      return ''; // Web環境では使用しない
    }

    // テスト広告を使用する場合
    if (_useTestAds) {
      try {
        if (Platform.isAndroid) {
          return 'ca-app-pub-3940256099942544/5224354917'; // テスト用Android
        } else if (Platform.isIOS) {
          return 'ca-app-pub-3940256099942544/1712485313'; // テスト用iOS
        }
      } catch (e) {
        // Platform情報が取得できない場合
      }
      return 'ca-app-pub-3940256099942544/5224354917'; // デフォルト
    }

    // 本番広告を使用する場合（あなたのリワード広告ID）
    return 'ca-app-pub-3971807513032614/1697780305';
  }

  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  Future<void> initialize() async {
    // Web環境では広告を無効化
    if (kIsWeb) return;

    try {
      // カウンターを読み込み
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

  // リスタートカウンターを読み込み
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

  // リスタートカウンターを保存
  Future<void> _saveRestartCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_restartCountKey, _restartCount);
      debugPrint('Saved restart count: $_restartCount');
    } catch (e) {
      debugPrint('Failed to save restart count: $e');
    }
  }

  void _loadBannerAd() {
    // Web環境では広告を読み込まない
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
            // 失敗したら少し待ってから再読み込み
            Future.delayed(const Duration(seconds: 5), () {
              _loadBannerAd();
            });
          },
        ),
      );
      _bannerAd!.load();
    } catch (e) {
      debugPrint('Banner ad loading exception: $e');
      _isBannerAdLoaded = false;
    }
  }

  void _loadInterstitialAd() {
    // Web環境では広告を読み込まない
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

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                _isAdLoaded = false;
                _loadInterstitialAd(); // 次の広告をプリロード
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: ${error.message}');
                ad.dispose();
                _isAdLoaded = false;
                _loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: ${error.message}');
            _isAdLoaded = false;
            // 失敗したら少し待ってから再読み込み
            Future.delayed(const Duration(seconds: 5), () {
              _loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial ad loading exception: $e');
      _isAdLoaded = false;
    }
  }

  Future<void> showInterstitialAd({required Function onAdClosed}) async {
    // Web環境では広告をスキップ
    if (kIsWeb) {
      onAdClosed();
      return;
    }

    // カウンターをインクリメント
    _restartCount++;
    await _saveRestartCount();

    // 3回に1回だけ広告を表示
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
      if (!shouldShowAd) {
        debugPrint('Skipping ad (not every 3rd restart)');
      } else {
        debugPrint('Interstitial ad not ready, skipping');
      }
      // 広告を表示しない場合はすぐにコールバックを実行
      onAdClosed();
    }
  }

  // リワード広告を読み込み
  void _loadRewardedAd() {
    // Web環境では広告を読み込まない
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

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Rewarded ad dismissed');
                ad.dispose();
                _isRewardedAdLoaded = false;
                _loadRewardedAd(); // 次の広告をプリロード
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Rewarded ad failed to show: ${error.message}');
                ad.dispose();
                _isRewardedAdLoaded = false;
                _loadRewardedAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: ${error.message}');
            _isRewardedAdLoaded = false;
            // 失敗したら少し待ってから再読み込み
            Future.delayed(const Duration(seconds: 5), () {
              _loadRewardedAd();
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('Rewarded ad loading exception: $e');
      _isRewardedAdLoaded = false;
    }
  }

  // リワード広告を表示
  Future<void> showRewardedAd({required Function(bool) onComplete}) async {
    // Web環境では広告をスキップ
    if (kIsWeb) {
      onComplete(false);
      return;
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      debugPrint('Showing rewarded ad');
      bool rewarded = false;

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          rewarded = true;
        },
      );

      // 広告が閉じられるまで待つ
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
    } else {
      debugPrint('Rewarded ad not ready');
      onComplete(false);
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}
