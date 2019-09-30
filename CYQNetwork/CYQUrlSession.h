//
//  CYQUrlSession.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQMacroHeader.h"

@class CYQUrlTaskDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface CYQUrlSession : NSObject

@property(nonatomic,readonly,nonnull,strong) NSURLSession *session;

@property(nonatomic,readonly,nonnull,strong) NSURLSessionConfiguration *config;

-(instancetype)initWithConfiguration:(NSURLSessionConfiguration * _Nullable)config;

@end

@interface CYQUrlSession (CYQSessionAsynchronousConvenience)

+(instancetype)defaultSession;

+(instancetype)backgroundSession;

-(NSURLSessionDataTask*)dataTaskWithReq:(NSURLRequest*)req
                               progress:(CYQUrlSessionProgressBlock)progressBlk
                                success:(CYQUrlSessionSuccessBlock)successBlk
                                   fail:(CYQUrlSessionFailBlock)failBlk;

-(NSURLSessionUploadTask*)uploadTaskWithReq:(NSURLRequest*)req
                                   progress:(CYQUrlSessionProgressBlock)progressBlk
                                    success:(CYQUrlSessionSuccessBlock)successBlk
                                       fail:(CYQUrlSessionFailBlock)failBlk;

-(NSURLSessionDownloadTask*)downloadTaskWithReq:(NSURLRequest*)req
                                       progress:(CYQUrlSessionProgressBlock)progressBlk
                                        success:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                                           fail:(CYQUrlSessionFailBlock)failBlk;

-(NSURLSessionDownloadTask*)resumeTaskWithData:(NSData*)resumeData
                                      progress:(CYQUrlSessionProgressBlock)progressBlk
                                       success:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                                          fail:(CYQUrlSessionFailBlock)failBlk;
@end

@interface NSURLSessionTask (CYQSessionTaskDelegate)

@property(nonatomic,strong) CYQUrlTaskDelegate *cyq_delegate;

@property(nonatomic,copy) NSString *cyq_cacheIdentifier;

@end

NS_ASSUME_NONNULL_END
