//
//  CYQRequestSerializer.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/16.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CYQRequestSerialization <NSObject>
@required
//解析方式交给子类实现
-(NSMutableURLRequest*)requestWithUrl:(NSURL* _Nonnull)url method:(NSString* _Nonnull)method parameters:(NSDictionary* _Nullable)data;

@end

@interface CYQRequestSerializer : NSObject<CYQRequestSerialization>
@end

@interface CYQRequestFormSerializer : CYQRequestSerializer
@end

@interface CYQRequestJsonSerializer : CYQRequestSerializer
@end


NS_ASSUME_NONNULL_END
