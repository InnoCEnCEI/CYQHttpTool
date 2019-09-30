//
//  CYQUrlTaskDelegate.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/21.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQMacroHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYQUrlTaskDelegate : NSObject

@property(nonatomic,copy,readonly,nullable) CYQUrlSessionSuccessBlock successBlk;

@property(nonatomic,copy,readonly,nullable) CYQUrlSessionDownloadSuccessBlock downloadSuccessBlk;

@property(nonatomic,copy,readonly,nullable) CYQUrlSessionFailBlock failBlk;

@property(nonatomic,copy,readonly,nullable) CYQUrlSessionProgressBlock progressBlk;

+(instancetype)dataTaskDelegateWithSucessBlk:(CYQUrlSessionSuccessBlock)successBlk
                                       progressBlk:(CYQUrlSessionProgressBlock)progressBlk
                                        andFailBlk:(CYQUrlSessionFailBlock)failBlk;

+(instancetype)downloadTaskDelegateWithDownloadSucessBlk:(CYQUrlSessionDownloadSuccessBlock)downloadSuccessBlk
                                 progressBlk:(CYQUrlSessionProgressBlock)progressBlk
                                  andFailBlk:(CYQUrlSessionFailBlock)failBlk;

-(void)appendReceiveData:(NSData *)data;

-(NSData*)getData;

@end

NS_ASSUME_NONNULL_END
