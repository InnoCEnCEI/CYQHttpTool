//
//  CYQEasyCache.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/22.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CYQEasyCache : NSObject

+(void)removeCacheWithCacheId:(NSString*)cacheId;

+(void)saveCacheWithCacheId:(NSString*)cacheId resumeData:(NSData*)resumeData;

+(NSData*)getResumeDataWithCacheId:(NSString*)cacheId;

@end

NS_ASSUME_NONNULL_END
