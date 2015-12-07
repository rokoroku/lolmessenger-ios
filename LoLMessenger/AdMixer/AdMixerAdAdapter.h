//
//  AdMixerAdAdapter.h
//  AdMixer
//
//  Created by 정건국 on 12. 6. 17..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdMixer.h"
#import "AdMixerInfo.h"

@class AdMixerAdAdapter;

@protocol AdMixerAdAdapterDelegate <NSObject>

- (void)succeededToReceiveAdWithAdapter:(AdMixerAdAdapter *)adapter;
- (void)failedToReceiveAdWithAdapter:(AdMixerAdAdapter *)adapter error:(AXError *)error;
- (void)poppedUpScreenWithAdapter:(AdMixerAdAdapter *)adapter;
- (void)dismissedScreenWithAdapter:(AdMixerAdAdapter *)adapter;
- (void)displayedInterstitialAd:(AdMixerAdAdapter *)adapter;
- (void)closedInterstitialAd:(AdMixerAdAdapter *)adapter;
- (void)clickedPopupButton:(AdMixerAdAdapter *)adapter;

@end

@interface AdMixerAdAdapter : NSObject

@property (nonatomic, retain) AdMixerInfo * adInfo;
@property (nonatomic, retain) NSDictionary * adConfig;
@property (nonatomic, retain) NSString * appCode;
@property (nonatomic, retain) AdMixerInterstitialPopupOption *interstitialPopupOption;

@property (nonatomic, assign) id<AdMixerAdAdapterDelegate> delegate;
@property (nonatomic, retain) UIViewController * baseViewController;
@property (nonatomic, retain) UIView * baseView;
@property (nonatomic, assign) BOOL isInterstitial;
@property (nonatomic, assign) BOOL isResultFired;
@property (nonatomic, assign) BOOL isDisplayedInterstitial;
@property (nonatomic, assign) BOOL isClosedInterstitial;

@property (nonatomic, assign) BOOL isLoadOnly;
@property (nonatomic, assign) BOOL hasInterstitialAd;

- (NSString *)adapterName;

- (CGSize)adapterSize;

- (id)initWithAdInfo:(AdMixerInfo *)adInfo adConfig:(NSDictionary *)adConfig;

- (BOOL)loadAd;

- (void)start;

- (void)stop;

- (NSObject *)adObject;

- (BOOL)supportSuccessiveLoading;

- (BOOL)successiveLoadResult;

- (void)fireSucceededToReceiveAd;
- (void)fireFailedToReceiveAdWithError:(AXError *)error;
- (void)firePopUpScreen;
- (void)fireDismissScreen;
- (void)fireDisplayedInterstitialAd;
- (void)fireOnClosedInterstitialAd;
- (void)fireOnClickedPopupButton;

- (BOOL)canLoadOnly:(BOOL)isInterstitial;
- (BOOL)canCloseInterstitial;
- (BOOL)canUseInterstitialPopupType:(BOOL)isInterstitial;
- (BOOL)displayInterstital;

@end
