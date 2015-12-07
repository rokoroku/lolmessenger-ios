//
//  AdMixerCustomPopup.h
//  AdMixer
//
//  Created by 정건국 on 13. 6. 7..
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol AdMixerCustomPopupDelegate <NSObject>

@optional

- (void)onStartedCustomPopup;

- (void)onWillShowCustomPopup:(NSString *)pageName;

- (void)onShowCustomPopup:(NSString *)pageName;

- (void)onWillCloseCustomPopup:(NSString *)pageName;

- (void)onCloseCustomPopup:(NSString *)pageName;

- (void)onHasNoCustomPopup;

@end

@interface AdMixerCustomPopup : NSObject

@property (nonatomic, assign) id<AdMixerCustomPopupDelegate> delegate;

+ (AdMixerCustomPopup *)sharedInstance;

- (void)startCustomPopupWithAxKey:(NSString *)axKey viewController:(UIViewController *)viewController;
- (void)stopCustomPopup;
- (void)checkCustomPopupPage:(NSString *)pageName viewController:(UIViewController *)viewController;

@end
