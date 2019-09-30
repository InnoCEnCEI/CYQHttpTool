//
//  CYQMultiFormMaker.m
//  cyqnetworktool
//
//  Created by cyq on 2019/9/27.
//  Copyright © 2019 钱程远. All rights reserved.
//

#import "CYQMultiFormMaker.h"
#import <CoreServices/CoreServices.h>

NSErrorDomain const CYQMultiFormMakerDomain = @"com.cyqnetwork.multiform.maker.error";

static NSString * CYQCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary=%08X%08X", arc4random(), arc4random()];
}

static NSString * const kCYQMultipartFormCRLF = @"\r\n";

static inline NSString * CYQMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kCYQMultipartFormCRLF];
}

static inline NSString * CYQMultipartFormEncapsulationBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@%@", kCYQMultipartFormCRLF, boundary, kCYQMultipartFormCRLF];
}

static inline NSString * CYQMultipartFormFinalBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@--%@", kCYQMultipartFormCRLF, boundary, kCYQMultipartFormCRLF];
}

static inline NSString * CYQContentTypeForPathExtension(NSString *extension) {
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    } else {
        return contentType;
    }
}

@interface CYQMultiFormField : NSObject
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, copy) NSString *boundary;
@property (nonatomic,strong) id body;
@property (nonatomic,assign,readonly) unsigned long long bodyContentLength;
@property (nonatomic, assign) NSStringEncoding stringEncoding;

@property (nonatomic, assign) BOOL hasInitialBoundary;
@property (nonatomic, assign) BOOL hasFinalBoundary;
@property (nonatomic, strong) NSInputStream *inputStream;

@end

@implementation CYQMultiFormField
-(instancetype)init{
    if (self = [super init]) {
        _stringEncoding = NSUTF8StringEncoding;
    }
    return self;
}

- (unsigned long long)contentLength {
    unsigned long long length = 0;
    
    NSData *encapsulationBoundaryData = [([self hasInitialBoundary] ? AFMultipartFormInitialBoundary(self.boundary) : AFMultipartFormEncapsulationBoundary(self.boundary)) dataUsingEncoding:self.stringEncoding];
    length += [encapsulationBoundaryData length];
    
    NSData *headersData = [[self stringForHeaders] dataUsingEncoding:self.stringEncoding];
    length += [headersData length];
    
    length += _bodyContentLength;
    
    NSData *closingBoundaryData = ([self hasFinalBoundary] ? [AFMultipartFormFinalBoundary(self.boundary) dataUsingEncoding:self.stringEncoding] : [NSData data]);
    length += [closingBoundaryData length];
    
    return length;
}

-(NSInputStream *)inputStream{
    if (!_inputStream) {
        if (!self.body) {
            return nil;
        }
        if ([self.body isKindOfClass:[NSData class]]) {
            _inputStream = [NSInputStream inputStreamWithData:self.body];
        } else if ([self.body isKindOfClass:[NSURL class]]) {
            _inputStream = [NSInputStream inputStreamWithURL:self.body];
        } else if ([self.body isKindOfClass:[NSInputStream class]]) {
            _inputStream = self.body;
        } else {
            _inputStream = [NSInputStream inputStreamWithData:[NSData data]];
        }
    }
    return _inputStream;
}

@end

@interface CYQInputStream : NSInputStream
@property (readonly, nonatomic, assign) unsigned long long contentLength;
@property (readwrite, nonatomic, strong) NSMutableArray <CYQMultiFormField*>*HTTPBodyParts;
- (void)setInitialAndFinalBoundaries;
@end

@implementation CYQInputStream
- (void)setInitialAndFinalBoundaries {
    if ([self.HTTPBodyParts count] > 0) {
        for (CYQMultiFormField *bodyPart in self.HTTPBodyParts) {
            bodyPart.hasInitialBoundary = NO;
            bodyPart.hasFinalBoundary = NO;
        }
        
        [[self.HTTPBodyParts firstObject] setHasInitialBoundary:YES];
        [[self.HTTPBodyParts lastObject] setHasFinalBoundary:YES];
    }
}
@end

@interface CYQMultiFormMaker ()
@property(nonatomic,nonnull,strong) NSMutableURLRequest *request;
@property(nonatomic,copy) NSString* boundary;
@property(nonatomic,strong) CYQInputStream *inputStream;
@end

@implementation CYQMultiFormMaker

-(instancetype)initWithRequest:(NSMutableURLRequest*)req{
    if (self = [super init]) {
        _request = req;
        _boundary = CYQCreateMultipartFormBoundary();
        _inputStream = [[CYQInputStream alloc] init];
    }
    return self;
}

+(instancetype)makerWithRequest:(NSMutableURLRequest *)req{
    return [[CYQMultiFormMaker alloc] initWithRequest:req];
}

-(NSMutableURLRequest*)getFinalRequestByMultiForm{
    if (!self.inputStream.HTTPBodyParts || [self.inputStream.HTTPBodyParts count] == 0) {
        return self.request;
    }
    [self.inputStream setInitialAndFinalBoundaries];
    [self.request setHTTPBodyStream:self.inputStream];
    
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", self.boundary] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%llu", [self.inputStream contentLength]] forHTTPHeaderField:@"Content-Length"];
    return self.request;
}

#pragma mark - CYQMultiFormProtocol

-(BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError *__autoreleasing  _Nullable *)error{
    NSString *fileName = [fileURL lastPathComponent];
    NSString *mimeType = CYQContentTypeForPathExtension([fileURL pathExtension]);
    return [self appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
}

-(BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType error:(NSError *__autoreleasing  _Nullable *)error{
    if (![fileURL isFileURL]) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: @"Expected URL to be a file URL"};
        if (error) {
            *error = [[NSError alloc] initWithDomain:CYQMultiFormMakerDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    } else if ([fileURL checkResourceIsReachableAndReturnError:error] == NO) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: @"File URL not reachable"};
        if (error) {
            *error = [[NSError alloc] initWithDomain:CYQMultiFormMakerDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:error];
    if (!fileAttributes) {
        return NO;
    }
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    CYQMultiFormField *bodyPart = [[CYQMultiFormField alloc] init];
    bodyPart.headers = mutableHeaders;
    bodyPart.boundary = self.boundary;
    bodyPart.body = fileURL;
    bodyPart.bodyContentLength = [fileAttributes[NSFileSize] unsignedLongLongValue];
    [self.inputStream.HTTPBodyParts addObject:bodyPart];
    
    return YES;
}

-(void)appendPartWithFormData:(NSData *)data name:(NSString *)name{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

-(void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    [self appendPartWithHeaders:mutableHeaders body:data];
}

-(void)appendPartWithInputStream:(NSInputStream *)inputStream name:(NSString *)name fileName:(NSString *)fileName length:(int64_t)length mimeType:(NSString *)mimeType{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    CYQMultiFormField *bodyPart = [[CYQMultiFormField alloc] init];
    bodyPart.headers = mutableHeaders;
    bodyPart.boundary = self.boundary;
    bodyPart.body = inputStream;
    bodyPart.bodyContentLength = (unsigned long long)length;
    
    [self.inputStream.HTTPBodyParts addObject:bodyPart];
}

- (void)appendPartWithHeaders:(NSDictionary *)headers body:(NSData *)body{
    CYQMultiFormField *bodyPart = [[CYQMultiFormField alloc] init];
    bodyPart.headers = headers;
    bodyPart.boundary = self.boundary;
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;
    
    [self.inputStream.HTTPBodyParts addObject:bodyPart];
}

@end
