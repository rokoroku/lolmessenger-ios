//
//  AdamAdapter.m
//  AdMixerTest
//
//  Created by 정건국 on 12. 6. 27..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import "AdamAdapter.h"
#import "AXLog.h"
#import "AdamManager.h"

@interface AdamAdapter(Private)

- (void)delayedStart;

@end

@implementation AdamAdapter

- (void)dealloc {
	_adView = nil;
	_interstitial = nil;
	
}

- (NSString *)adapterName {
	return AMA_ADAM;
}

- (CGSize)adapterSize {
	return CGSizeMake(0, 48);
}

- (id)initWithAdInfo:(AdMixerInfo *)adInfo adConfig:(NSDictionary *)adConfig {
	self = [super initWithAdInfo:adInfo adConfig:adConfig];
	if(self) {
	}
	return self;
}

- (BOOL)loadAd {
    [AdamManager sharedInstance].adapter = self;
    
	if(self.isInterstitial) {
		_interstitial = [AdamInterstitial sharedInterstitial];
		_interstitial.delegate = [AdamManager sharedInstance];
		if(self.adInfo.isTestMode)
			_interstitial.clientId = @"InterstitialTestClientId";
		else
			_interstitial.clientId = self.appCode;
	} else {
		_adView = [AdamAdView sharedAdView];
		_adView.frame = self.baseView.bounds;
		if(self.adInfo.isTestMode)
			_adView.clientId = @"TestClientId";
		else
			_adView.clientId = self.appCode;
		
		_adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_adView.delegate = [AdamManager sharedInstance];
		_adView.hidden = YES;
		[self.baseView addSubview:_adView];
        
	}
	return YES;
}

- (void)start {
	[self performSelector:@selector(delayedStart) withObject:nil afterDelay:0.001];
}

- (void)stop {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedStart) object:nil];
	
	if(self.isInterstitial) {
		if(_interstitial) {
			_interstitial = nil;
		}
	} else {
		if(_adView) {
			_adView.delegate = nil;
			[_adView removeFromSuperview];
			_adView = nil;
		}
	}
}

- (NSObject *)adObject {
	return _adView;
}

- (BOOL)supportSuccessiveLoading {
	return NO;
}

- (BOOL)successiveLoadResult {
	BOOL ret = [[AdamManager sharedInstance] hasAvailableLastResult];
	[[AdamManager sharedInstance] clearLastResult];
	return ret;
}

#pragma mark - AdamAdViewDelegate

- (void)didReceiveAd:(AdamAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Adam - didReceiveAd");
	_adView.hidden = NO;
	[self fireSucceededToReceiveAd];
}

- (void)didFailToReceiveAd:(AdamAdView *)adView error:(NSError *)error {
	AX_LOG(AXLogLevelDebug, @"Adam - didFailToReceiveAd : %@", [error description]);
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[error description]]];
}

- (void)willOpenFullScreenAd:(AdamAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Adam - willOpenFullScreenAd");
    [self firePopUpScreen];
}

- (void)didOpenFullScreenAd:(AdamAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Adam - didOpenFullScreenAd");
}

- (void)willCloseFullScreenAd:(AdamAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Adam - willCloseFullScreenAd");
    [self fireDismissScreen];
}

- (void)didCloseFullScreenAd:(AdamAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Adam - didCloseFullScreenAd");
}

- (void)willResignByAd:(AdamAdView *)adView {
    AX_LOG(AXLogLevelDebug, @"Adam - willResignByAd");
}


#pragma mark - AdamInterstitialDelegate

- (void)didReceiveInterstitialAd:(AdamInterstitial *)interstitial {
    AX_LOG(AXLogLevelDebug, @"Adam - didReceiveInterstitialAd");
	[self fireSucceededToReceiveAd];
}

- (void)didFailToReceiveInterstitialAd:(AdamInterstitial *)interstitial error:(NSError *)error {
    AX_LOG(AXLogLevelDebug, @"Adam - didFailToReceiveInterstitialAd");
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[error description]]];
}

- (void)willOpenInterstitialAd:(AdamInterstitial *)interstitial {
    AX_LOG(AXLogLevelDebug, @"Adam - willOpenInterstitialAd");

}

- (void)didOpenInterstitialAd:(AdamInterstitial *)interstitial {
    AX_LOG(AXLogLevelDebug, @"Adam - didOpenInterstitialAd");
}

- (void)willCloseInterstitialAd:(AdamInterstitial *)interstitial {
    AX_LOG(AXLogLevelDebug, @"Adam - willCloseInterstitialAd");
	[self fireOnClosedInterstitialAd];
}

- (void)didCloseInterstitialAd:(AdamInterstitial *)interstitial {
    AX_LOG(AXLogLevelDebug, @"Adam - didCloseInterstitialAd");
}

- (void)willResignByInterstitialAd:(AdamInterstitial *)interstitial {
    AX_LOG(AXLogLevelDebug, @"Adam - willResignByInterstitialAd");
}


#pragma mark - Private

- (void)delayedStart {
	if(self.isInterstitial) {
		[_interstitial requestAndPresent];    
	} else {
		[_adView requestAd];
	}
}





@end
