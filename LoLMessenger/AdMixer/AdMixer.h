//
//  AdMixer.h
//  AdMixer
//
//  Created by 정건국 on 12. 6. 11..
//  Copyright (c) 2012년 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AXError.h"

#define AMA_DEFAULT_AD				(@"ax_default")
#define AMA_HOUSE_AD				(@"admixer")
#define AMA_ADMIXER_RTB				(@"admixerrtb")
#define AMA_ADAM					(@"adam")
#define AMA_ADMOB					(@"admob")
#define AMA_CAULY					(@"cauly")
#define AMA_TAD						(@"tad")
#define AMA_SHALLWE					(@"shallwe")
#define AMA_IAD						(@"iad")
#define AMA_INMOBI					(@"inmobi")
#define AMA_FACEBOOK                (@"facebook")
#define AMA_MAN                     (@"man")

#define AX_ERR_SUCCESS			(0x00000000)

#define AX_ERR_HTTP_ERROR		(0x68000001)
#define AX_ERR_TIMEOUT			(0x68000002)
#define AX_ERR_NO_FILL			(0x68000003)
#define AX_ERR_NO_ADAPTER		(0x68000004)
#define AX_ERR_ADAPTER_ERROR	(0x68000005)
#define AX_ERR_SERVER_CONFIG_FAIL	(0x68000006)
#define AX_ERR_NO_DEFAULT_IMAGE	(0x68000007)

typedef enum {
	AXLogLevelNone,
	AXLogLevelRelease,
	AXLogLevelDebug,
	AXLogLevelAll
} AXLogLevel;

typedef enum {
	AXBannerSize_Default,		// Old Implementation(iphone, admob - smart banner, cauly - iphone/ipad)
	AXBannerSize_IPhone,		// 320 * 48
	AXBannerSize_IPad_Small,	// 468 * 60
	AXBannerSize_IPad_Large		// 728 * 90
} AXBannerSize;

@interface AdMixer : NSObject

+ (void)setLogLevel:(AXLogLevel)logLevl;
+ (AXLogLevel)logLevel;

+ (BOOL)registerUserAdAdapterNameWithAppCode:(NSString *)adapterName cls:(Class)cls appCode:(NSString*)appCode;
+ (BOOL)registerUserAdAdapterName:(NSString *)adapterName cls:(Class)cls;
@end

