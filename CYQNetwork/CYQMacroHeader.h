//
//  CYQMacroHeader.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#ifndef CYQMacroHeader_h
#define CYQMacroHeader_h

#import <Foundation/Foundation.h>

typedef void(^CYQUrlSessionSuccessBlock)(NSURLSessionTask * _Nullable task, NSData * _Nullable data);
typedef void(^CYQUrlSessionDownloadSuccessBlock)(NSURLSessionTask * _Nullable task, NSURL * _Nullable location);
typedef void(^CYQUrlSessionFailBlock)(NSURLSessionTask * _Nullable task, NSError * _Nullable error);
typedef void(^CYQUrlSessionProgressBlock)(NSProgress * _Nullable progress);

@protocol CYQMultiFormProtocol <NSObject>

- (BOOL)appendPartWithFileURL:(nullable NSURL *)fileURL
                         name:(nullable NSString *)name
                        error:(NSError * _Nullable __autoreleasing *_Nullable)error;


- (BOOL)appendPartWithFileURL:(nullable NSURL *)fileURL
                         name:(nullable NSString *)name
                     fileName:(nullable NSString *)fileName
                     mimeType:(nullable NSString *)mimeType
                        error:(NSError * _Nullable __autoreleasing *_Nullable)error;


- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                             name:(nullable NSString *)name
                         fileName:(nullable NSString *)fileName
                           length:(int64_t)length
                         mimeType:(nullable NSString *)mimeType;


- (void)appendPartWithFileData:(nullable NSData *)data
                          name:(nullable NSString *)name
                      fileName:(nullable NSString *)fileName
                      mimeType:(nullable NSString *)mimeType;


- (void)appendPartWithFormData:(nullable NSData *)data
                          name:(nullable NSString *)name;

@end

#endif /* CYQMacroHeader_h */
