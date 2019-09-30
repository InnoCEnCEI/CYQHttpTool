//
//  CYQNetworkTool.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CYQRequestSerializer,CYQResponseSerializer;
@protocol CYQRequestSerialization,CYQResponseSerialization,CYQMultiFormProtocol;

NS_ASSUME_NONNULL_BEGIN

typedef void(^CYQNetworkSuccessBlock)(NSURLSessionTask * _Nullable task, id _Nullable data);

typedef void(^CYQNetworkDownloadSuccessBlock)(NSURLSessionTask * _Nullable task, NSURL * _Nullable location);

typedef void(^CYQNetworkProgressBlock)( NSProgress * _Nullable progress);

typedef void(^CYQNetworkFailBlock)(NSURLSessionTask * _Nullable task, NSError * _Nullable error);

typedef void(^CYQMultiFormMakerBlock)(id <CYQMultiFormProtocol> _Nonnull uploadDataMaker);

@interface CYQNetworkTool : NSObject

@property(nonatomic,strong) CYQRequestSerializer <CYQRequestSerialization> * requestSerializer;

@property(nonatomic,strong) CYQResponseSerializer <CYQResponseSerialization> * responseSerializer;

+(instancetype)sharedTool;

/*
 *
 */
+(void)suspendDownloadTask:(NSURLSessionDownloadTask *)task withResumeHandller:(void(^)(void))resumeHandller;

+(void)resumeDownloadTaskWithCacheId:(NSString*)cacheId;

+(NSURLSessionTask *_Nullable)GetUrl:(NSString *_Nonnull)url
                          withParams:(NSDictionary *_Nullable)param
                             success:(CYQNetworkSuccessBlock _Nullable)successBlk
                                fail:(CYQNetworkFailBlock _Nullable)failBlk;

+(NSURLSessionTask *_Nullable)PostUrl:(NSString* _Nonnull)url
                 withParams:(NSDictionary* _Nullable)param
                   progress:(CYQNetworkProgressBlock _Nullable)progressBlk
                    success:(CYQNetworkSuccessBlock _Nullable)successBlk
                       fail:(CYQNetworkFailBlock _Nullable)failBlk;

+(NSURLSessionUploadTask *_Nullable)uploadUrl:(NSString* _Nonnull)url
      withParams:(NSDictionary* _Nullable)param
            data:(CYQMultiFormMakerBlock _Nullable)dataMake
        progress:(CYQNetworkProgressBlock _Nullable)progressBlk
         success:(CYQNetworkSuccessBlock _Nullable)successBlk
            fail:(CYQNetworkFailBlock _Nullable)failBlk;

+(NSURLSessionDownloadTask *_Nullable)downloadUrl:(NSString* _Nonnull)url
                              resumable:(BOOL)resumable
                     urlCacheIdentifier:(NSString* _Nullable)cacheId
                               progress:(CYQNetworkProgressBlock _Nullable)progressBlk
                                success:(CYQNetworkDownloadSuccessBlock _Nullable)downloadSuccessBlk
                                   fail:(CYQNetworkFailBlock _Nullable)failBlk;

+(NSURLSessionDownloadTask *_Nullable)backgroundDownloadUrl:(NSString* _Nonnull)url
                                        resumable:(BOOL)resumable
                               urlCacheIdentifier:(NSString* _Nullable)cacheId
                                         progress:(CYQNetworkProgressBlock _Nullable)progressBlk
                                          success:(CYQNetworkDownloadSuccessBlock _Nullable)downloadSuccessBlk
                                                       fail:(CYQNetworkFailBlock _Nullable)failBlk;
@end

NS_ASSUME_NONNULL_END
