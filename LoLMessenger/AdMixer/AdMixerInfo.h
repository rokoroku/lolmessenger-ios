//
//  AdMixerInfo.h
//  AdMixer
//
//  Created by 정건국 on 12. 6. 25..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdMixerInterstitialPopupOption.h"

typedef enum {
	AdMixerRTBAdVAlignTop,
	AdMixerRTBVAlignCenter,
	AdMixerRTBVAlignBottom
} AdMixerRTBVAlign;

typedef enum {
    AdMixerInterstitialBasicType,
    AdMixerInterstitialPopupType
} AdMixerInterstitialAdType;

typedef enum {
    AdMixerRTBBannerHeightRatio,
    AdMixerRTBBannerHeightFixed
} AdMixerRTBBannerHeight;

@interface AdMixerInfo : NSObject

@property (nonatomic, retain) NSString * axKey;
@property (nonatomic, assign) int threadPriority;
@property (nonatomic, assign) BOOL isTestMode;
@property (nonatomic, assign) int interstitialTimeout;
@property (nonatomic, assign) AdMixerRTBVAlign rtbVerticalAlign;
@property (nonatomic, assign) float defaultAdTime;
@property (nonatomic, assign) BOOL useRTBGPSInfo;
@property (nonatomic, readonly) AdMixerInterstitialAdType interstitialAdType;
@property (nonatomic, retain, readonly) AdMixerInterstitialPopupOption *interstitialPopupOption;
@property (nonatomic, assign) BOOL setInterstitialBackgroundAlpha;
@property (nonatomic, assign) AdMixerRTBBannerHeight rtbBannerHeight;

- (void)setInterstitialAdType:(AdMixerInterstitialAdType)adType withInterstitialPopupOption:(AdMixerInterstitialPopupOption *)adOption;

@end
