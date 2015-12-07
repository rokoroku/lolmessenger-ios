//
//  AdMixerView.h
//  AdMixer
//
//  Created by 정건국 on 12. 6. 13..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdMixer.h"
#import "AdMixerInfo.h"
#import "AXError.h"

@class AdMixerView;

@protocol AdMixerViewDelegate <NSObject>

- (void)onSucceededToReceiveAd:(AdMixerView *)adView;
- (void)onFailedToReceiveAd:(AdMixerView *)adView error:(AXError *)error;

@optional
- (void)onClickedAd:(AdMixerView *)adView adapterName:(NSString *)adapterName;

@end

@interface AdMixerView : UIView

@property (nonatomic, assign) id<AdMixerViewDelegate> delegate;
@property (nonatomic, assign) AXBannerSize adSize;

- (void)startWithAdInfo:(AdMixerInfo *)adInfo baseViewController:(UIViewController *)viewController;
- (void)stop;
- (NSString *)currentAdapterName;
- (CGSize)currentAdapterSize;

@end
