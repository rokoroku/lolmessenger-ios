//
//  CaulyAdapter.m
//  AdMixerTest
//
//  Created by Eric Yeohoon Yoon on 12. 9. 10..
//
// 

#import "CaulyAdapter.h"
#import "AXLog.h"
#import "CaulyAdSetting.h"

@implementation CaulyAdapter

static CaulyAdapter * _lastAdapter = nil;

- (void)dealloc {
    if( self.isInterstitial) {
        if( _interstitialAd)
            [_interstitialAd release];
        _interstitialAd = nil;
    }
    else {
        if( _adView)
            [_adView release];
        _adView = nil;
    }
    	
	[super dealloc];
}

- (NSString *)adapterName {
	return AMA_CAULY;
}

- (CGSize)adapterSize {
	return CGSizeMake(0, 48);
}

- (id)initWithAdInfo:(AdMixerInfo *)adInfo adConfig:(NSDictionary *)adConfig {
	self = [super initWithAdInfo:adInfo adConfig:adConfig];
	if(self) {
        [CaulyAdSetting setLogLevel:CaulyLogLevelAll];
        CaulyAdSetting * adSetting = [CaulyAdSetting globalSetting];
        adSetting.appCode = self.appCode;
        adSetting.animType = CaulyAnimNone;
        adSetting.useGPSInfo = NO;
        adSetting.useDynamicReloadTime = NO;
        adSetting.reloadTime = CaulyReloadTime_120;
        
		AXBannerSize adSize = (AXBannerSize)[[self.adConfig objectForKey:@"adSize"] intValue];
		switch (adSize) {
			case AXBannerSize_Default:
				if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
					adSetting.adSize = CaulyAdSize_IPhone;
				else
					adSetting.adSize = CaulyAdSize_IPadLarge;
				break;
			case AXBannerSize_IPhone:
				adSetting.adSize = CaulyAdSize_IPhone;
				break;
			case AXBannerSize_IPad_Small:
				adSetting.adSize = CaulyAdSize_IPadSmall;
				break;
			case AXBannerSize_IPad_Large:
				adSetting.adSize = CaulyAdSize_IPadLarge;
				break;
		}
	}
	return self;
}

- (BOOL)loadAd {
    [CaulyAdSetting adSettingWithAppCode:self.appCode];
    if( self.isInterstitial) {
        _interstitialAd = [[CaulyInterstitialAd alloc] initWithParentViewController:self.baseViewController];
        _interstitialAd.delegate = self;
    }
    else {
    	_adView = [[CaulyAdView alloc] initWithParentViewController:self.baseViewController];
        [self.baseView addSubview:_adView];
        _adView.delegate = self;
        _adView.hidden = YES;
    }
    
	return YES;
}

- (void)start {
	if(self.isInterstitial) {
        [_interstitialAd startInterstitialAdRequest];
	} else {
        [_adView startBannerAdRequest];
		
		if(_lastAdapter)
			[_lastAdapter release];
		_lastAdapter = [self retain];
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
			[_adView removeFromSuperview];
			[_adView release];
			_adView = nil;
		}
	}
}

- (NSObject *)adObject {
	return _adView;
}

#pragma mark - CaulyAdViewDelegate
- (void)didReceiveAd:(CaulyAdView *)adView isChargeableAd:(BOOL)isChargeableAd {
    if( isChargeableAd) {
        AX_LOG(AXLogLevelDebug, @"Cauly - didReceiveAd");
        _adView.hidden = NO;
        [self fireSucceededToReceiveAd];
    }
    else {
        if( [self.appCode isEqualToString:@"CAULY"]) {
            AX_LOG(AXLogLevelDebug, @"Cauly - didReceiveAd");
            _adView.hidden = NO;
            [self fireSucceededToReceiveAd];
        }
        else {
            AX_LOG(AXLogLevelDebug, @"Cauly - FreeAd");
            [self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:@"Free Ad!"]];
        }
    }
}

- (void)didFailToReceiveAd:(CaulyAdView *)adView errorCode:(int)errorCode errorMsg:(NSString *)errorMsg {
    AX_LOG(AXLogLevelDebug, @"Cauly - didFailToReceiveAd : %@", [errorMsg description]);
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[errorMsg description]]];
}

- (void)willShowLandingView:(CaulyAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Cauly - willShowLandingView");
    if( !self.isInterstitial)
        [self firePopUpScreen];
}

- (void)didCloseLandingView:(CaulyAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Cauly - didCloseLandingView");
    if( !self.isInterstitial)
        [self fireDismissScreen];
}

#pragma mark - CaulyInterstitialAdDelegate

- (void)didReceiveInterstitialAd:(CaulyInterstitialAd *)interstitialAd isChargeableAd:(BOOL)isChargeableAd{
    if( isChargeableAd) {
        AX_LOG(AXLogLevelDebug, @"Cauly - didReceiveInterstitialAd");
        [self fireSucceededToReceiveAd];
		if(!self.isLoadOnly) {
			[interstitialAd show];
			[self fireDisplayedInterstitialAd];
		} else
			self.hasInterstitialAd = YES;
    }
    else {
        if( [self.appCode isEqualToString:@"CAULY"]) {
            AX_LOG(AXLogLevelDebug, @"Cauly - didReceiveInterstitialAd");
            [self fireSucceededToReceiveAd];
			if(!self.isLoadOnly) {
				[interstitialAd show];
				[self fireDisplayedInterstitialAd];
			} else
				self.hasInterstitialAd = YES;
        }
        else {
            AX_LOG(AXLogLevelDebug, @"Cauly - FreeInterstitialAd");
            [self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:@"Free Ad!"]];
        }
        
        
        
    }
}

- (void)didCloseInterstitialAd:(CaulyInterstitialAd *)interstitialAd {
	AX_LOG(AXLogLevelDebug, @"Cauly - didCloseInterstitialAd");
	[self fireOnClosedInterstitialAd];
}

- (void)willShowInterstitialAd:(CaulyInterstitialAd *)interstitalAd {
	AX_LOG(AXLogLevelDebug, @"Cauly - willShowInterstitialAd");
}

- (void)didFailToReceiveInterstitialAd:(CaulyInterstitialAd *)interstitalAd errorCode:(int)errorCode errorMsg:(NSString *)errorMsg {
    AX_LOG(AXLogLevelDebug, @"Cauly - didFailToReceiveInterstitialAd");
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[errorMsg description]]];
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
	[_interstitialAd show];
	[self fireDisplayedInterstitialAd];
	return YES;
}

@end
