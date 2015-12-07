//
//  AdamManager.h
//  AdMixerTest
//
//  Created by Eric Yeohoon Yoon on 12. 8. 28..
//
//

#import <Foundation/Foundation.h>
#import "AXDate.h"
#import "AdamAdView.h"
#import "AdamInterstitial.h"
#import "AdamAdapter.h"

@interface AdamManager : NSObject <AdamAdViewDelegate, AdamInterstitialDelegate>
{
    AdamAdapter * _adapter;
    
	int _lastErrorCode;
	NSString * _lastErrorMsg;
	AXDate * _lastResultDate;
}

+ (AdamManager *)sharedInstance;

- (int)lastErrorCode;
- (NSString *)lastErrorMsg;
- (BOOL)hasAvailableLastResult;
- (void)clearLastResult;

@property (nonatomic, retain) AdamAdapter * adapter;
@end
