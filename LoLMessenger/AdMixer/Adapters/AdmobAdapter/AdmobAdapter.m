//
//  AdmobAdapter.m
//  AdMixerTest
//
//  Created by 정건국 on 12. 6. 27..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "AdmobAdapter.h"
#import "AXLog.h"

@interface AdmobAdapter(Private)

- (void)delayedFail;

@end

@implementation AdmobAdapter

static NSArray * g_testDevices = nil;

- (void)dealloc {

	_adView = nil;
	_interstitial = nil;
	
}

+ (void)registerTestDevices:(NSArray *)devices {
    g_testDevices = devices;
    
}

- (NSString *)adapterName {
	return AMA_ADMOB;
}

- (CGSize)adapterSize {
	if(_adView != nil)
		return _adView.bounds.size;
	return CGSizeMake(0, 0);
}

- (id)initWithAdInfo:(AdMixerInfo *)adInfo adConfig:(NSDictionary *)adConfig {
	self = [super initWithAdInfo:adInfo adConfig:adConfig];
	if(self) {
	}
	return self;
}

- (BOOL)loadAd {
	if(self.isInterstitial) {
		_interstitial = [[GADInterstitial alloc] initWithAdUnitID:self.appCode];
		_interstitial.delegate = self;
	} else {
		AXBannerSize adSize = (AXBannerSize)[[self.adConfig objectForKey:@"adSize"] intValue];
		switch (adSize) {
			case AXBannerSize_Default:
				_adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
				break;
			case AXBannerSize_IPhone:
				_adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
				break;
			case AXBannerSize_IPad_Small:
				_adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeFullBanner];
				break;
			case AXBannerSize_IPad_Large:
				_adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeLeaderboard];
				break;
		}

		_adView.adUnitID = self.appCode;
		_adView.delegate = self;
		_adView.rootViewController = self.baseViewController;
		_adView.hidden = YES;
		[self.baseView addSubview:_adView];

	}
	return YES;
}

- (void)start {
	GADRequest * request = [GADRequest request];
	request.testDevices = g_testDevices;
    request.requestAgent = @"AdMixer";
//	request.testing = self.adInfo.isTestMode;
	
	if(self.isInterstitial) {
		[_interstitial loadRequest:request];
	} else {
		[_adView loadRequest:request];
	}
}

- (void)stop {
	if(self.isInterstitial) {
		if(_interstitial) {
			_interstitial.delegate = nil;
			_interstitial = nil;
		}
	} else {
		if(_adView) {
			_adView.delegate = nil;
			[_adView removeFromSuperview];
			_adView = nil;
		}
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedFail) object:nil];
}

- (NSObject *)adObject {
	return _adView;
}

#pragma mark - GADBannerViewDelegate

- (void)adViewDidReceiveAd:(GADBannerView *)view {
    AX_LOG(AXLogLevelDebug, @"Admob - adViewDidReceiveAd");
	_adView.hidden = NO;
	[self fireSucceededToReceiveAd];
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
	_error = error;
	[self performSelector:@selector(delayedFail) withObject:nil afterDelay:0.01];
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    AX_LOG(AXLogLevelDebug, @"Admob - adViewWillPresentScreen");
    [self firePopUpScreen];
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    AX_LOG(AXLogLevelDebug, @"Admob - adViewWillDismissScreen");
    [self fireDismissScreen];
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    AX_LOG(AXLogLevelDebug, @"Admob - adViewDidDismissScreen");
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    AX_LOG(AXLogLevelDebug, @"Admob - adViewWillLeaveApplication");
}

#pragma mark - GADInterstitialDelegate

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad {
    AX_LOG(AXLogLevelDebug, @"Admob - interstitialDidReceiveAd");
	
	[self fireSucceededToReceiveAd];
	
	if(!self.isLoadOnly) {
		[_interstitial presentFromRootViewController:self.baseViewController];
		[self fireDisplayedInterstitialAd];
	} else
		self.hasInterstitialAd = YES;
}

- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error {
	_error = error;
	[self performSelector:@selector(delayedFail) withObject:nil afterDelay:0.01];
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)ad {
    AX_LOG(AXLogLevelDebug, @"Admob - interstitialWillPresentScreen");
}

- (void)interstitialWillDismissScreen:(GADInterstitial *)ad {
    AX_LOG(AXLogLevelDebug, @"Admob - interstitialWillDismissScreen");
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad {
    AX_LOG(AXLogLevelDebug, @"Admob - interstitialDidDismissScreen");
	[self fireOnClosedInterstitialAd];
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad {
    AX_LOG(AXLogLevelDebug, @"Admob - interstitialWillLeaveApplication");
}


#pragma mark - Private

- (void)delayedFail {
    AX_LOG(AXLogLevelDebug, @"Admob - didFailToReceiveAdWithError");
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[_error description]]];
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
    [_interstitial presentFromRootViewController:self.baseViewController];
	[self fireDisplayedInterstitialAd];
	return YES;
}



@end
