//
//  CYQUrlTaskDelegate.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQUrlTaskDelegate.h"

@interface CYQUrlTaskDelegate()

@property(nonatomic,strong) NSMutableData *multiData;

@end

@implementation CYQUrlTaskDelegate

-(instancetype)init{
    return nil;
}

-(instancetype)initWithSucessBlk:(CYQUrlSessionSuccessBlock)successBlk
               DownloadSucessBlk:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                     progressBlk:(CYQUrlSessionProgressBlock)progressBlk
                      andFailBlk:(CYQUrlSessionFailBlock)failBlk{
    if (self = [super init]) {
        _successBlk = successBlk;
        _downloadSuccessBlk = downloadSuccessBlk;
        _failBlk = failBlk;
        _progressBlk = progressBlk;
    }
    return self;
}

-(NSMutableData *)multiData{
    if (!_multiData) {
        _multiData = [NSMutableData data];
    }
    return _multiData;
}

+(instancetype)dataTaskDelegateWithSucessBlk:(CYQUrlSessionSuccessBlock)successBlk
                                 progressBlk:(CYQUrlSessionProgressBlock)progressBlk
                                  andFailBlk:(CYQUrlSessionFailBlock)failBlk{
    return [[CYQUrlTaskDelegate alloc] initWithSucessBlk:successBlk
                                       DownloadSucessBlk:nil
                                             progressBlk:progressBlk
                                              andFailBlk:failBlk];
}

+(instancetype)downloadTaskDelegateWithDownloadSucessBlk:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                                             progressBlk:(CYQUrlSessionProgressBlock)progressBlk
                                              andFailBlk:(CYQUrlSessionFailBlock)failBlk{
    return [[CYQUrlTaskDelegate alloc] initWithSucessBlk:nil
                                       DownloadSucessBlk:downloadSuccessBlk
                                             progressBlk:progressBlk
                                              andFailBlk:failBlk];
}

-(void)appendReceiveData:(NSData *)data{
    if (data) {
        [self.multiData appendData:data];
    }
}

-(NSData *)getData{
    return _multiData;
}

@end
