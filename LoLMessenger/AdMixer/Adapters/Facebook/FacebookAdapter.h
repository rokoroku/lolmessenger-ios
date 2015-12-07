//
//  FacebookAdapter.h
//  AdMixerTest
//
//  Created by 원소정 on 2015. 1. 28..
//
// v4.1.0

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "AdMixerAdAdapter.h"

@interface FacebookAdapter : AdMixerAdAdapter <FBAdViewDelegate, FBInterstitialAdDelegate>
{
    FBAdView *_adView;
    FBInterstitialAd *_interstitialAd;
}

@end
