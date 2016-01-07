//
//  CaulyAdapter.h
//  AdMixerTest
//
//  Created by Eric Yeohoon Yoon on 12. 9. 10..
//
// v3.0.5

#import "AdMixerAdAdapter.h"
#import "CaulyAdView.h"
#import "CaulyInterstitialAd.h"

@interface CaulyAdapter : AdMixerAdAdapter<CaulyAdViewDelegate, CaulyInterstitialAdDelegate>
{
    	CaulyAdView *_adView;
        CaulyInterstitialAd * _interstitialAd;
}

@end
