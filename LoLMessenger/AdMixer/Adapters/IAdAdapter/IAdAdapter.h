//
//  IAdAdapter.h
//  AdMixerTest
//
//  Created by Eric Yeohoon Yoon on 13. 1. 3..
//
//

#import "AdMixerAdAdapter.h"
#import "iAD/iAD.h"

@interface IAdAdapter : AdMixerAdAdapter<ADBannerViewDelegate, ADInterstitialAdDelegate>
{
    ADBannerView *_adView;
    ADInterstitialAd * _interstitialAd;
}

@end
