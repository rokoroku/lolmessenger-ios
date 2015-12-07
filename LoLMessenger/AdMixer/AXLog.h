//
//  s.h
//  AdMixer
//
//  Created by FutureStreamNetworks on 12. 4. 11..
//  Copyright (c) 2012년 FutureStreamNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdMixer.h"

void axSetLogLevel(AXLogLevel logLevel);
AXLogLevel axGetLogLevel();
BOOL axCanLog(AXLogLevel logLevel);

void AX_LOG(AXLogLevel logLevel, NSString* format, ...);
void AX_SECURE_LOG(AXLogLevel logLevel, NSString* format, ...);
void AX_TEST_LOG(AXLogLevel logLevel, NSString* format, ...);
