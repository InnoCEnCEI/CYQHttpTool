//
//  CYQRequestSerializer.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/16.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQRequestSerializer.h"

@implementation CYQRequestSerializer

//抽象类，不提供解析功能，直接返回nil
-(NSMutableURLRequest *)requestWithUrl:(NSURL * )url method:(NSString * )method  parameters:(NSDictionary * )data{
    return nil;
}

-(NSMutableURLRequest*)requestWithUrl:(NSURL*)url method:(NSString*)method{
    NSMutableURLRequest *req = nil;
    if ([[method uppercaseString] isEqualToString:@"POST"]) {
        req = [self postMethodRequestWithUrl:url];
    }else if ([[method uppercaseString] isEqualToString:@"GET"]) {
        req = [self getMethodRequestWithUrl:url];
    }else{
        req = [self getMethodRequestWithUrl:url];
    }
    return req;
}

-(NSMutableURLRequest*)postMethodRequestWithUrl:(NSURL*)url{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"POST"];
    return req;
}

-(NSMutableURLRequest*)getMethodRequestWithUrl:(NSURL*)url{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setHTTPMethod:@"GET"];
    return req;
}

-(NSString*)queryStringByDictionary:(NSDictionary*)dict{
    NSMutableArray *queryArr = [NSMutableArray array];
    for (NSString* key in dict.allKeys) {
        [queryArr addObject:[NSString stringWithFormat:@"%@=%@",key,dict[key]]];
    }
    return [queryArr componentsJoinedByString:@"&"];
}
@end

@implementation CYQRequestFormSerializer

-(NSMutableURLRequest *)requestWithUrl:(NSURL *)url method:(NSString*)method parameters:(NSDictionary *)data{
    return [self formRequestWithUrl:url method:method parameters:data];
}

-(NSMutableURLRequest*)formRequestWithUrl:(NSURL*)url method:(NSString*)method  parameters:(NSDictionary*)data{
    NSMutableURLRequest *req = [self requestWithUrl:url method:method];
    
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    if (data) {
        NSString *query = [self queryStringByDictionary:data];
        [req setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    return req;
}

@end

@implementation CYQRequestJsonSerializer

-(NSMutableURLRequest *)requestWithUrl:(NSURL *)url method:(NSString*)method parameters:(NSDictionary *)data{
    return [self jsonRequestWithUrl:url method:method parameters:data];
}

-(NSMutableURLRequest*)jsonRequestWithUrl:(NSURL*)url method:(NSString*)method  parameters:(NSDictionary*)data{
    
    NSMutableURLRequest *req = [self requestWithUrl:url method:method];
    
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (data) {
        if (![NSJSONSerialization isValidJSONObject:data]) {
            return nil;
        }
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
        if (!jsonData) {
            return nil;
        }
        [req setHTTPBody:jsonData];
    }
    return req;
    
}

@end
