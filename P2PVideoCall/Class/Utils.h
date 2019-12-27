//
//  Utils.h
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/18.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (NSString *)removeSpaceAndNewline:(NSString *)str;
+ (NSString *)addSpaceAndNewline:(NSString *)str;
+ (NSString *)getMyIPAddress;
+ (NSString *)getIPAddress:(BOOL)preferIPv4;
+ (NSData *)convertDataFrom:(NSDictionary *)dict;
+ (NSDictionary *)convertDictFrom:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
