//
//  CYQUrlSession.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQUrlSession.h"
#import <objc/runtime.h>
#import "CYQUrlTaskDelegate.h"

static CYQUrlSession *_cyqBackgroundSession = nil;

NSString * const kCYQUrlBackgroundSessionConfigurationIdentifier = @"com.cyqnetwork.CYQUrlSession.bgsscfgid";

@interface CYQUrlSessionDelegate : NSObject<NSURLSessionDelegate,NSURLSessionTaskDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate>

@end

@interface CYQUrlSession ()

@property(nonatomic,nonnull,strong) NSURLSession *session;

@property(nonatomic,assign) BOOL isBackgroundMode;

@end

@implementation CYQUrlSession

-(instancetype)initWithConfiguration:(NSURLSessionConfiguration *)config useDelegate:(id<NSURLSessionDelegate>)sessionDelegate{
    if (self = [super init]) {
        _config = config;
        if (sessionDelegate) {
            _session = [NSURLSession sessionWithConfiguration:config delegate:sessionDelegate delegateQueue:[[NSOperationQueue alloc] init]];
            _isBackgroundMode = NO;
        }
    }
    return self;
}

-(instancetype)initWithConfiguration:(NSURLSessionConfiguration *)config{
    CYQUrlSessionDelegate *sessionDelegate = [[CYQUrlSessionDelegate alloc] init];
    return [self initWithConfiguration:config useDelegate:sessionDelegate];
}

//不允许使用基本初始化
-(instancetype)init{
    return nil;
}

@end

@implementation CYQUrlSession (CYQSessionAsynchronousConvenience)

+(instancetype)defaultSession{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    CYQUrlSessionDelegate *sessionDelegate = [[CYQUrlSessionDelegate alloc] init];
    return [[[self class] alloc] initWithConfiguration:config useDelegate:sessionDelegate];
}

+(instancetype)backgroundSession{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kCYQUrlBackgroundSessionConfigurationIdentifier];
        CYQUrlSessionDelegate *sessionDelegate = [[CYQUrlSessionDelegate alloc] init];
        _cyqBackgroundSession = [[CYQUrlSession alloc] initWithConfiguration:config useDelegate:sessionDelegate];
        _cyqBackgroundSession.isBackgroundMode = YES;
    });
    return _cyqBackgroundSession;
}

-(NSURLSessionDataTask*)dataTaskWithReq:(NSURLRequest*)req
                               progress:(CYQUrlSessionProgressBlock)progressBlk
                                success:(CYQUrlSessionSuccessBlock)successBlk
                                   fail:(CYQUrlSessionFailBlock)failBlk{
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:req];
    if (task) {
        task.cyq_delegate = [CYQUrlTaskDelegate dataTaskDelegateWithSucessBlk:successBlk progressBlk:progressBlk andFailBlk:failBlk];
    }
    return task;
}

-(NSURLSessionUploadTask*)uploadTaskWithReq:(NSURLRequest*)req
                                   progress:(CYQUrlSessionProgressBlock)progressBlk
                                    success:(CYQUrlSessionSuccessBlock)successBlk
                                       fail:(CYQUrlSessionFailBlock)failBlk{
    NSURLSessionUploadTask *task = [self.session uploadTaskWithStreamedRequest:req];
    if (task) {
        task.cyq_delegate = [CYQUrlTaskDelegate dataTaskDelegateWithSucessBlk:successBlk progressBlk:progressBlk andFailBlk:failBlk];
    }
    return task;
}

-(NSURLSessionDownloadTask*)downloadTaskWithReq:(NSURLRequest*)req
                                       progress:(CYQUrlSessionProgressBlock)progressBlk
                                        success:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                                           fail:(CYQUrlSessionFailBlock)failBlk{
 
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:req];
    if (task) {
        task.cyq_delegate = [CYQUrlTaskDelegate downloadTaskDelegateWithDownloadSucessBlk:downloadSuccessBlk progressBlk:progressBlk andFailBlk:failBlk];
    }
    return task;
}

-(NSURLSessionDownloadTask*)resumeTaskWithData:(NSData*)resumeData
                                       progress:(CYQUrlSessionProgressBlock)progressBlk
                                        success:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                                           fail:(CYQUrlSessionFailBlock)failBlk{
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithResumeData:resumeData];
    if (task) {
        task.cyq_delegate = [CYQUrlTaskDelegate downloadTaskDelegateWithDownloadSucessBlk:downloadSuccessBlk progressBlk:progressBlk andFailBlk:failBlk];
    }
    return task;
}

@end

@implementation CYQUrlSessionDelegate

#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    //NSLog(@"%s,session:%@",__func__,session);
    //[session invalidateAndCancel];
    
}

#pragma mark - NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error{
    CYQUrlTaskDelegate *taskdelegate = task.cyq_delegate;
    if (error) {
        if (taskdelegate && taskdelegate.failBlk) {
            taskdelegate.failBlk(task,error);
        }
    }else{
        if (taskdelegate && taskdelegate.successBlk) {
            taskdelegate.successBlk(task, [taskdelegate getData]);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
    CYQUrlTaskDelegate *taskdelegate = task.cyq_delegate;
    if (taskdelegate && taskdelegate.progressBlk) {
        NSProgress * progress = [[NSProgress alloc] init];
        progress.totalUnitCount = totalBytesExpectedToSend;
        progress.completedUnitCount = totalBytesSent;
        taskdelegate.progressBlk(progress);
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream * _Nullable))completionHandler{
    
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    CYQUrlTaskDelegate *taskdelegate = dataTask.cyq_delegate;
    if (taskdelegate ) {
        [taskdelegate appendReceiveData:data];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location{
    CYQUrlTaskDelegate *taskdelegate = downloadTask.cyq_delegate;
    if (taskdelegate && taskdelegate.downloadSuccessBlk) {
        taskdelegate.downloadSuccessBlk(downloadTask,location);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    CYQUrlTaskDelegate *taskdelegate = downloadTask.cyq_delegate;
    if (taskdelegate && taskdelegate.progressBlk) {
        NSProgress * progress = [[NSProgress alloc] init];
        progress.totalUnitCount = totalBytesExpectedToWrite;
        progress.completedUnitCount = totalBytesWritten;
        taskdelegate.progressBlk(progress);
    }
}

@end

@implementation NSURLSessionTask (CYQSessionTaskDelegate)

-(CYQUrlTaskDelegate *)cyq_delegate{
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setCyq_delegate:(CYQUrlTaskDelegate *)cyq_delegate{
    objc_setAssociatedObject(self, @selector(cyq_delegate), cyq_delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)cyq_cacheIdentifier{
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setCyq_cacheIdentifier:(NSString *)cyq_cacheIdentifier{
    objc_setAssociatedObject(self, @selector(cyq_cacheIdentifier), cyq_cacheIdentifier, OBJC_ASSOCIATION_COPY);
}

@end
