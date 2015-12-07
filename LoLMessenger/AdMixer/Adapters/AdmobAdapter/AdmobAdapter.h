//
//  AdmobAdapter.h
//  AdMixerTest
//
//  Created by 정건국 on 12. 6. 27..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//
// v7.2.2

#import <Foundation/Foundation.h>
#import "AdMixerAdAdapter.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface AdmobAdapter : AdMixerAdAdapter<GADBannerViewDelegate, GADInterstitialDelegate> {
	
    GADInterstitial * _interstitial;
    GADBannerView * _adView;
	GADRequestError * _error;
	
}

+ (void)registerTestDevices:(NSArray *)devices;

@end
