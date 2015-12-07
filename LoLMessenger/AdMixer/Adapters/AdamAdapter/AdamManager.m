//
//  AdamManager.m
//  AdMixerTest
//
//  Created by Eric Yeohoon Yoon on 12. 8. 28..
//
//

#import "AdamManager.h"

@implementation AdamManager

@synthesize adapter = _adapter;
static AdamManager * _instance = nil;

- (void)dealloc {

}

+ (AdamManager *)sharedInstance {
	if(_instance == nil) {
		_instance = [[AdamManager alloc] init];
	}
	return _instance;
}

- (int)lastErrorCode {
	return _lastErrorCode;
}

- (NSString *)lastErrorMsg {
	return _lastErrorMsg;
}

- (BOOL)hasAvailableLastResult {
	if(_lastResultDate == nil)
		return NO;
	
	if(_lastErrorCode != 0)
		return NO;
	
	AXDate * date = [[AXDate alloc] initWithNSDate:[NSDate dateWithTimeIntervalSinceNow:0]];
	int diffTime = [date diffTimeWithDate:_lastResultDate];
    date = nil;
	if(diffTime < 30)
		return YES;
	return NO;
}

- (void)clearLastResult {
	_lastResultDate = nil;
}

#pragma mark - AdamAdViewDelegate

- (void)didReceiveAd:(AdamAdView *)adView {
    _lastErrorCode = 0;
	_lastErrorMsg = nil;
	
	_lastResultDate = [[AXDate alloc] initWithNSDate:[NSDate dateWithTimeIntervalSinceNow:0]];
	
    [_adapter didReceiveAd:adView];
}

- (void)didFailToReceiveAd:(AdamAdView *)adView error:(NSError *)error {
    NSString * errorMsg = [NSString stringWithUTF8String:[[error domain] cStringUsingEncoding:NSUTF8StringEncoding]];
	_lastErrorMsg = errorMsg;
	_lastErrorCode = error.code;
	
	_lastResultDate = [[AXDate alloc] initWithNSDate:[NSDate dateWithTimeIntervalSinceNow:0]];

    [_adapter didFailToReceiveAd:adView error:error];
}

- (void)willOpenFullScreenAd:(AdamAdView *)adView {
    [_adapter willOpenFullScreenAd:adView];
}

- (void)didOpenFullScreenAd:(AdamAdView *)adView {
    [_adapter didOpenFullScreenAd:adView];
}

- (void)willCloseFullScreenAd:(AdamAdView *)adView {
    [_adapter willCloseFullScreenAd:adView];
}

- (void)didCloseFullScreenAd:(AdamAdView *)adView {
    [_adapter didCloseFullScreenAd:adView];
}

- (void)willResignByAd:(AdamAdView *)adView {
    [_adapter willResignByAd:adView];
}


#pragma mark - AdamInterstitialDelegate

- (void)didReceiveInterstitialAd:(AdamInterstitial *)interstitial {
    [_adapter didReceiveInterstitialAd:interstitial];
}

- (void)didFailToReceiveInterstitialAd:(AdamInterstitial *)interstitial error:(NSError *)error {
    [_adapter didFailToReceiveInterstitialAd:interstitial error:error];
}

- (void)willOpenInterstitialAd:(AdamInterstitial *)interstitial {
    [_adapter willOpenInterstitialAd:interstitial];
}

- (void)didOpenInterstitialAd:(AdamInterstitial *)interstitial {
    [_adapter didOpenInterstitialAd:interstitial];
}

- (void)willCloseInterstitialAd:(AdamInterstitial *)interstitial {
    [_adapter willCloseInterstitialAd:interstitial];
}

- (void)didCloseInterstitialAd:(AdamInterstitial *)interstitial {
    [_adapter didCloseInterstitialAd:interstitial];
}

- (void)willResignByInterstitialAd:(AdamInterstitial *)interstitial {
    [_adapter willResignByInterstitialAd:interstitial];
}

@end
