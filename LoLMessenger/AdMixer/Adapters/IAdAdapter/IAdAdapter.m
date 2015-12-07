//
//  IAdAdapter.m
//  AdMixerTest
//
//  Created by Eric Yeohoon Yoon on 13. 1. 3..
//
//

#import "IAdAdapter.h"
#import "AXLog.h"

@implementation IAdAdapter
- (void)dealloc {
    if( self.isInterstitial) {
        _interstitialAd = nil;
    }
    else {
        _adView = nil;
    }
}

- (NSString *)adapterName {
	return AMA_IAD;
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

    if( self.isInterstitial) {
		if ([[UIDevice currentDevice] respondsToSelector: @selector(userInterfaceIdiom)]) {
			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				_interstitialAd = [[ADInterstitialAd alloc] init];
                [_interstitialAd cancelAction];
				_interstitialAd.delegate = self;
				return  YES;
			}
		}
		return NO;
    }
    else {
    	_adView = [[ADBannerView alloc] initWithFrame:CGRectZero];
        _adView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        _adView.delegate = self;

        [self.baseView addSubview:_adView];
        _adView.hidden = YES;
    }
    
	return YES;
}

- (void)start {
    if(self.isInterstitial) {
        [_interstitialAd presentFromViewController:self.baseViewController];
    }
}

- (void)stop {
	if(self.isInterstitial) {
		if(_interstitialAd) {
			_interstitialAd.delegate = nil;
			_interstitialAd = nil;
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

#pragma mark - ADBannerViewDelegate
- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    AX_LOG(AXLogLevelDebug, @"iAd - didFailToReceiveAd : %@", [error localizedDescription]);
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[error description]]];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    AX_LOG(AXLogLevelDebug, @"iAd - bannerViewActionDidFinish");
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    AX_LOG(AXLogLevelDebug, @"iAd - bannerViewActionShouldBegin");
	return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    AX_LOG(AXLogLevelDebug, @"iAd - didReceiveAd");
    _adView.hidden = NO;
    [self fireSucceededToReceiveAd];
}

- (void)bannerViewWillLoadAd:(ADBannerView *)banner
{
    AX_LOG(AXLogLevelDebug, @"iAd - bannerViewWillLoadAd");
}


#pragma mark - ADInterstitialAdDelegate

- (void)interstitialAd:(ADInterstitialAd *)interstitialAd didFailWithError:(NSError *)error
{
    AX_LOG(AXLogLevelDebug, @"iAd - didFailToReceiveInterstitialAd : %@", [error localizedDescription]);
	[self fireFailedToReceiveAdWithError:[AXError errorWithCode:AX_ERR_ADAPTER_ERROR message:[error description]]];
}

- (void)interstitialAdActionDidFinish:(ADInterstitialAd *)interstitialAd
{
    AX_LOG(AXLogLevelDebug, @"iAd - interstitialAdActionDidFinish");
	[self fireOnClosedInterstitialAd];
}


- (BOOL)interstitialAdActionShouldBegin:(ADInterstitialAd *)interstitialAd willLeaveApplication:(BOOL)willLeave
{
    AX_LOG(AXLogLevelDebug, @"iAd - interstitialAdActionShouldBegin");
	return YES;
}

- (void)interstitialAdDidLoad:(ADInterstitialAd *)interstitialAd
{
    AX_LOG(AXLogLevelDebug, @"iAd - interstitialAdDidLoad");
    _adView.hidden = NO;
    [self fireSucceededToReceiveAd];
    
}

- (void)interstitialAdDidUnload:(ADInterstitialAd *)interstitialAd
{
    AX_LOG(AXLogLevelDebug, @"iAd - interstitialAdDidUnload");    
}

- (void)interstitialAdWillLoad:(ADInterstitialAd *)interstitialAd {
    AX_LOG(AXLogLevelDebug, @"iAd - interstitialAdWillLoad");
}

@end
