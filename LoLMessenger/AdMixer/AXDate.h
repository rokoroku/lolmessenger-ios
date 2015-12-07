//
//  AXDate.h
//  sosi
//
//  Created by FSN on 11. 2. 1..
//  Copyright 2011 FutureStreamNetworks. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AXDate : NSObject {
    
	NSDate * _date;
	
}

+ (AXDate *)dateWithDevString:(NSString *)str;
+ (AXDate *)dateWithNSDate:(NSDate *)date;
+ (AXDate *)now;

- (id)initWithDevString:(NSString *)str;
- (id)initWithNSDate:(NSDate *)date;

- (NSDate *)date;
- (double)timeInterval;
- (NSString *)devString;
- (AXDate *)gmDate;
- (AXDate *)localDate;

- (int)year;
- (int)month;
- (int)day;
- (int)hour;
- (int)minute;
- (int)second;
- (int)millisecond;

- (void)addTime:(NSTimeInterval)seconds;
- (NSTimeInterval)diffTimeWithDate:(AXDate *)date;


@end
