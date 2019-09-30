//
//  CYQResponseSerializer.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/16.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQResponseSerializer.h"

NSErrorDomain const CYQResponseSerializerDomain = @"com.cyqnetwork.response.json.format.error";

@implementation CYQResponseSerializer
-(NSDictionary *)dictByData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)err{
    *err = [NSError errorWithDomain:CYQResponseSerializerDomain code:2001 userInfo:@{@"msg":@"you need a valid response serializer"}];
    return nil;
}
@end

@implementation CYQResponseJsonSerializer

-(NSDictionary *)dictByData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)err{
    return [self jsonByData:data error:err];
}

-(NSDictionary*)jsonByData:(NSData*)data error:(NSError * _Nullable __autoreleasing *)err{
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:err];
    if (*err) {
        return nil;
    }
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        *err = [NSError errorWithDomain:CYQResponseSerializerDomain code:2003 userInfo:@{@"origin data":data}];
        return nil;
    }
    return (NSDictionary*)responseObject;
}

@end
