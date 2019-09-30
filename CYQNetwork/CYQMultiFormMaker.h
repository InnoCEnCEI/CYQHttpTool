//
//  CYQMultiFormMaker.h
//  cyqnetworktool
//
//  Created by cyq on 2019/9/27.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYQMacroHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYQMultiFormMaker : NSObject<CYQMultiFormProtocol>

+(instancetype)makerWithRequest:(NSMutableURLRequest*)req;

-(NSMutableURLRequest*)getFinalRequestByMultiForm;

@end

NS_ASSUME_NONNULL_END
