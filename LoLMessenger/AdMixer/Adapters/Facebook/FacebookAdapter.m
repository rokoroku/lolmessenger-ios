//
//  FacebookAdapter.m
//  AdMixerTest
//
//  Created by 원소정 on 2015. 1. 28..
//
//

#import "FacebookAdapter.h"
#import "AXLog.h"

@implementation FacebookAdapter

static bool _adViewDidLoad;

- (void)dealloc {
    [_interstitialAd release];
    [_adView release];
    
    [super dealloc];
}

- (NSString *)adapterName {
    return AMA_FACEBOOK;
}

- (CGSize)adapterSize {
    return CGSizeMake(0, 50);
}

- (id)initWithAdInfo:(AdMixerInfo *)adInfo adConfig:(NSDictionary *)adConfig {
    self = [super initWithAdInfo:adInfo adConfig:adConfig];
    if(self) {
    }
    return self;
}

- (BOOL)loadAd {
    _adViewDidLoad = NO;
    if(self.isInterstitial) {
        _interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:self.appCode];
        _interstitialAd.delegate = self;
    }else {
        FBAdSize adSize = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? kFBAdSizeHeight50Banner : kFBAdSizeHeight90Banner;
        _adView = [[FBAdView alloc] initWithPlacementID:self.appCode adSize:adSize rootViewController:self.baseViewController];
        _adView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        _adView.delegate = self;
        _adView.hidden = YES;
        [_adView disableAutoRefresh];
        CGRect frame = self.baseView.bounds;
        _adView.frame = frame;
        [self.baseView addSubview:_adView];
    }
    
    return YES;
}

- (void)start {
    if(self.isInterstitial) {
        [_interstitialAd loadAd];
    } else {
        [_adView loadAd];
    }
}

- (void)stop {
    if(self.isInterstitial) {
        if(_interstitialAd) {
            _interstitialAd.delegate = nil;
            [_interstitialAd release];
            _interstitialAd = nil;
        }
    } else {
        if(_adView) {
            _adView.delegate = nil;
            if(_adViewDidLoad)
                [_adView removeFromSuperview];
            [_adView release];
            _adView = nil;
        }
    }
}

- (NSObject *)adObject {
    return _adView;
}

# pragma mark - FBAdViewDelegate

- (void)adViewDidLoad:(FBAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Facebook - adViewDidLoad");
    _adViewDidLoad = YES;
    _adView.hidden = NO;
    [self fireSucceededToReceiveAd];
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
    AX_LOG(AXLogLevelDebug, @"Facebook - didFailWithError");
    [self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[error localizedDescription]]];
}

# pragma mark - FBInterstitialAdDelegate

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
    AX_LOG(AXLogLevelDebug, @"Facebook - interstitialAdDidLoad");
    [self fireSucceededToReceiveAd];
    
    if(!self.isLoadOnly) {
        [_interstitialAd showAdFromRootViewController:self.baseViewController];
        [self fireDisplayedInterstitialAd];
    } else
        self.hasInterstitialAd = YES;
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
    AX_LOG(AXLogLevelDebug, @"Facebook - didFailWithError");
    [self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[error localizedDescription]]];
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
}

- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
    AX_LOG(AXLogLevelDebug, @"Facebook - interstitialAdWillClose");
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
    AX_LOG(AXLogLevelDebug, @"Facebook - interstitialAdDidClose");
    [self fireOnClosedInterstitialAd];
}

- (BOOL)canLoadOnly:(BOOL)isInterstitial {
    if(isInterstitial)
        return YES;
    return NO;
}

- (BOOL)displayInterstital {
    if(!self.hasInterstitialAd)
        return NO;
    self.hasInterstitialAd = NO;
    [_interstitialAd showAdFromRootViewController:self.baseViewController];
    [self fireDisplayedInterstitialAd];
    return YES;
}

@end
