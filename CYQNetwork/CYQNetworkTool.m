//
//  CYQNetworkTool.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQNetworkTool.h"
#import "CYQRequestSerializer.h"
#import "CYQResponseSerializer.h"
#import "CYQUrlSession.h"
#import "CYQEasyCache.h"
#import "CYQMultiFormMaker.h"

static CYQNetworkTool *_httpDataTool = nil;

@interface  CYQNetworkTool()

@property(nonatomic,strong) CYQUrlSession *session;

@property(nonatomic,strong) NSMutableDictionary <NSString*,dispatch_block_t>*resumeTaskBlocks;

@property(nonatomic,strong) NSLock *lock;

@end

@implementation CYQNetworkTool

@synthesize responseSerializer = _responseSerializer;

@synthesize requestSerializer = _requestSerializer;

+(instancetype)sharedTool{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _httpDataTool = [[CYQNetworkTool alloc] init];
    });
    return _httpDataTool;
}

-(instancetype)init{
    if (self = [super init]) {
        _resumeTaskBlocks = [NSMutableDictionary dictionaryWithCapacity:0];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

-(CYQUrlSession *)session{
    if (!_session) {
        _session = [CYQUrlSession defaultSession];
    }
    return _session;
}

-(CYQResponseSerializer<CYQResponseSerialization> *)responseSerializer{
    if (!_responseSerializer) {
        _responseSerializer = [CYQResponseJsonSerializer new];
    }
    return _responseSerializer;
}

-(void)setResponseSerializer:(CYQResponseSerializer<CYQResponseSerialization> *)responseSerializer{
    _responseSerializer = responseSerializer;
}

-(CYQRequestSerializer<CYQRequestSerialization> *)requestSerializer{
    if (!_requestSerializer) {
        _requestSerializer = [CYQRequestFormSerializer new];
    }
    return _requestSerializer;
}

-(void)setRequestSerializer:(CYQRequestSerializer<CYQRequestSerialization> *)requestSerializer{
    _requestSerializer = requestSerializer;
}

+(NSURLSessionTask*)taskUrl:(NSString*)url
                      method:(NSString*)method
                withParams:(NSDictionary*)param
                  progress:(CYQNetworkProgressBlock)progressBlk
                   success:(CYQNetworkSuccessBlock)successBlk
                      fail:(CYQNetworkFailBlock)failBlk{
    CYQNetworkTool *tool = [CYQNetworkTool sharedTool];
    NSURLRequest * req = [tool.requestSerializer requestWithUrl:[NSURL URLWithString:url] method:method parameters:param];
    NSURLSessionDataTask *task = [[tool session] dataTaskWithReq:req progress:^(NSProgress * _Nullable progress) {
        if (progressBlk) {
            progressBlk(progress);
        }
    } success:^(NSURLSessionTask * _Nullable task, NSData * _Nullable data) {
        if (successBlk) {
            NSError *error = nil;
            NSDictionary *dic = [tool.responseSerializer dictByData:data error:&error];
            if (!error) {
                successBlk(task,dic);
            }else{
                if (failBlk) {
                    failBlk(task,error);
                }
            }
        }
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        if (failBlk) {
            failBlk(task,error);
        }
    }];
    [task resume];
    return task;
}

+(NSURLSessionDownloadTask*)downloadTaskUrl:(NSString*)url
                                 background:(BOOL)isBackground
                                        resumable:(BOOL)resumable
                               urlCacheIdentifier:(NSString*)cacheId
                                         progress:(CYQNetworkProgressBlock)progressBlk
                                          success:(CYQNetworkDownloadSuccessBlock)downloadSuccessBlk
                                             fail:(CYQNetworkFailBlock)failBlk{
    CYQUrlSession *session = nil;
    if (isBackground) {
        session = [CYQUrlSession backgroundSession];
    }else{
        session = [[CYQNetworkTool sharedTool] session];
    }
    NSURLSessionDownloadTask *task = nil;
    
    if (resumable) {
        NSData* resumeData = [CYQEasyCache getResumeDataWithCacheId:cacheId];
        if (resumeData) {
            //NSLog(@"++++++++++++++++++++++++++++");
            task = [session resumeTaskWithData:resumeData progress:^(NSProgress * _Nullable progress) {
                if (progressBlk) {
                    progressBlk(progress);
                }
            } success:^(NSURLSessionTask * _Nullable task, NSURL * _Nullable location) {
                if (resumable) {
                    [CYQEasyCache removeCacheWithCacheId:cacheId];
                }
                if (downloadSuccessBlk) {
                    downloadSuccessBlk(task,location);
                }
            } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
                if (resumable) {
                    [CYQEasyCache removeCacheWithCacheId:cacheId];
                }
                if (failBlk) {
                    failBlk(task,error);
                }
            }];
        }
    }
    if(!task){
        //NSLog(@"-----------------------------------");
        NSURLRequest * req = [[CYQNetworkTool sharedTool].requestSerializer requestWithUrl:[NSURL URLWithString:url] method:@"GET" parameters:nil];
        if (!req) {
            return nil;
        }
        task = [session downloadTaskWithReq:req progress:^(NSProgress * _Nullable progress) {
            if (progressBlk) {
                progressBlk(progress);
            }
        } success:^(NSURLSessionTask * _Nullable task, NSURL * _Nullable location) {
            if (resumable) {
                [CYQEasyCache removeCacheWithCacheId:cacheId];
            }
            if (downloadSuccessBlk) {
                downloadSuccessBlk(task,location);
            }
        } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
            if (resumable) {
                [CYQEasyCache removeCacheWithCacheId:cacheId];
            }
            if (failBlk) {
                failBlk(task,error);
            }
        }];
    }
    if (resumable) {
        task.cyq_cacheIdentifier = cacheId;
    }
    
    [task resume];
    
    return task;
}

#pragma mark - public method

+(void)suspendDownloadTask:(NSURLSessionDownloadTask *)task withResumeHandller:(void (^)(void))resumeHandller{
    NSString * taskCacheId = task.cyq_cacheIdentifier;
    if (resumeHandller && taskCacheId) {
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            if (resumeData) {
                CYQNetworkTool *tool = [self sharedTool];
                if (tool.resumeTaskBlocks && [tool.resumeTaskBlocks objectForKey:taskCacheId]) {
                    [tool.resumeTaskBlocks removeObjectForKey:taskCacheId];
                }
                [tool.lock lock];
                [tool.resumeTaskBlocks setObject:resumeHandller forKey:taskCacheId];
                [tool.lock unlock];
                [CYQEasyCache saveCacheWithCacheId:task.cyq_cacheIdentifier resumeData:resumeData];
            }
        }];
        
    }else{
        [task suspend];
    }
}

+(void)resumeDownloadTaskWithCacheId:(NSString *)cacheId{
    CYQNetworkTool *tool = [self sharedTool];
    if (tool.resumeTaskBlocks) {
        [tool.lock lock];
        dispatch_block_t handller = [tool.resumeTaskBlocks objectForKey:cacheId];
        [tool.resumeTaskBlocks removeObjectForKey:cacheId];
        [tool.lock unlock];
        if (handller) {
            handller();
        }
    }
}

+(NSURLSessionTask*)GetUrl:(NSString*)url
                    withParams:(NSDictionary*)param
                   success:(CYQNetworkSuccessBlock)successBlk
                      fail:(CYQNetworkFailBlock)failBlk{
    
    return [self taskUrl:url method:@"GET" withParams:param progress:nil success:successBlk fail:failBlk];
}

+(NSURLSessionTask*)PostUrl:(NSString*)url
                     withParams:(NSDictionary*)param
                      progress:(CYQNetworkProgressBlock)progressBlk
                       success:(CYQNetworkSuccessBlock)successBlk
                          fail:(CYQNetworkFailBlock)failBlk{
    return [self taskUrl:url method:@"POST" withParams:param progress:progressBlk success:successBlk fail:failBlk];
}

+(NSURLSessionUploadTask*)uploadUrl:(NSString*)url
      withParams:(NSDictionary* _Nullable)param
            data:(CYQMultiFormMakerBlock)dataMake
        progress:(CYQNetworkProgressBlock)progressBlk
         success:(CYQNetworkSuccessBlock)successBlk
            fail:(CYQNetworkFailBlock)failBlk{
    if (!dataMake) {
        return (NSURLSessionUploadTask*)[self PostUrl:url withParams:param progress:progressBlk success:successBlk fail:failBlk];
    }
    CYQNetworkTool *tool = [CYQNetworkTool sharedTool];
    NSMutableURLRequest * req = [tool.requestSerializer requestWithUrl:[NSURL URLWithString:url] method:@"POST" parameters:param];
    if (!req) {
        return  nil;
    }
    CYQMultiFormMaker *maker = [CYQMultiFormMaker makerWithRequest:req];
    dataMake(maker);
    NSURLSessionUploadTask *task = [tool.session uploadTaskWithReq:[maker getFinalRequestByMultiForm] progress:^(NSProgress * _Nullable progress) {
        if (progressBlk) {
            progressBlk(progress);
        }
    } success:^(NSURLSessionTask * _Nullable task, NSData * _Nullable data) {
        if (successBlk) {
            NSError *error = nil;
            NSDictionary *dic = [tool.responseSerializer dictByData:data error:&error];
            if (!error) {
                successBlk(task,dic);
            }else{
                if (failBlk) {
                    failBlk(task,error);
                }
            }
        }
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        if (failBlk) {
            failBlk(task,error);
        }
    }];
    if (!task) {
        return nil;
    }
    [task resume];
    return task;
}

+(NSURLSessionDownloadTask*)downloadUrl:(NSString*)url
                              resumable:(BOOL)resumable
                     urlCacheIdentifier:(NSString*)cacheId
                               progress:(CYQNetworkProgressBlock)progressBlk
                                success:(CYQNetworkDownloadSuccessBlock)downloadSuccessBlk
                                   fail:(CYQNetworkFailBlock)failBlk{
    
    return [self downloadTaskUrl:url background:NO resumable:resumable urlCacheIdentifier:cacheId progress:progressBlk success:downloadSuccessBlk fail:failBlk];
    
}


+(NSURLSessionDownloadTask*)backgroundDownloadUrl:(NSString*)url
                              resumable:(BOOL)resumable
                     urlCacheIdentifier:(NSString*)cacheId
                               progress:(CYQNetworkProgressBlock)progressBlk
                                success:(CYQNetworkDownloadSuccessBlock)downloadSuccessBlk
                                   fail:(CYQNetworkFailBlock)failBlk{
    
    return [self downloadTaskUrl:url background:YES resumable:resumable urlCacheIdentifier:cacheId progress:progressBlk success:downloadSuccessBlk fail:failBlk];
}


@end

