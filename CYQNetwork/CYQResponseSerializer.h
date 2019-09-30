//
//  CYQResponseSerializer.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/16.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CYQResponseSerialization <NSObject>
@required
-(NSDictionary*)dictByData:(NSData*)data error:(NSError * _Nullable __autoreleasing *)err;

@end

@interface CYQResponseSerializer : NSObject<CYQResponseSerialization>
@end

@interface CYQResponseJsonSerializer : CYQResponseSerializer
@end

NS_ASSUME_NONNULL_END
