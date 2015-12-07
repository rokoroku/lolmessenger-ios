//
//  AdMixerInterstitial.h
//  AdMixer
//
//  Created by 정건국 on 12. 6. 13..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AdMixer.h"
#import "AdMixerInfo.h"

@class AdMixerInterstitial;

@protocol AdMixerInterstitialDelegate <NSObject>

- (void)onSucceededToReceiveInterstitalAd:(AdMixerInterstitial *)intersitial;
- (void)onFailedToReceiveInterstitialAd:(AdMixerInterstitial *)intersitial error:(AXError *)error;
- (void)onClosedInterstitialAd:(AdMixerInterstitial *)intersitial;

@optional
- (void)onDisplayedInterstitialAd:(AdMixerInterstitial *)intersitial;
- (void)onClickedPopupButton:(AdMixerInterstitial *)interstitial;
@end


@interface AdMixerInterstitial : NSObject

@property (nonatomic, assign) id<AdMixerInterstitialDelegate> delegate;
@property (nonatomic, assign) BOOL autoClose;

- (void)startWithAdInfo:(AdMixerInfo *)adInfo baseViewController:(UIViewController *)viewController;
- (void)loadWithAdInfo:(AdMixerInfo *)adInfo baseViewController:(UIViewController *)viewController;
- (BOOL)displayAd;
- (void)stop;
- (void)close;

@end
