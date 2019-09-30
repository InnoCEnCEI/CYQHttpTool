//
//  ViewController.m
//  cyqnetworktool
//
//  Created by 钱程远 on 2019/9/13.
//  Copyright © 2019年 钱程远. All rights reserved.
//

#import "ViewController.h"
#import "CYQNetworkTool.h"
#import "AFNetworking.h"

@interface ViewController ()

@property(nonatomic,weak) NSURLSessionDownloadTask *task;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //[self cyqhttpdownload];
    //[self cyqhttp];
    //[self afhttp];
    //CYQHttpTool *tool = [CYQHttpTool sharedTool];
    //[tool setRequestSerializer:[CYQRequestJsonSerializer new]];
    
    
    
}

-(IBAction)cyuploadFileData:(id)btn{
    /*CYQHttpTool *tool = [CYQHttpTool sharedTool];
    NSData* data = [@"data=11111111jk1hjk1hjk1hjk1gik1gik1gi1gi1g" dataUsingEncoding:NSUTF8StringEncoding];
    [tool uploadDataWithUrlStr:@"http://localhost/" parameters:@{@"data":@"sdsd"} uploadData:data uploadProgress:^(NSProgress * _Nullable uploadDownloadProgress) {
        NSLog(@"%.0f%%",uploadDownloadProgress.completedUnitCount*100.f/uploadDownloadProgress.totalUnitCount);
    } success:^(id  _Nullable data, NSURLSessionTask * _Nullable task) {
        NSLog(@"data:%@",data);
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"error occur:%@",error);
    }];*/
}

-(IBAction)cyqhttpdownloadbackground:(id)btn{
    /*[CYQHttpTool  backgroundDownloadWithUrlStr:@"http://fastsoft.onlinedown.net/down/QQ9.1.7.25980.exe" downloadProgress:^(NSProgress * _Nullable uploadDownloadProgress) {
        NSLog(@"%.0f%%",uploadDownloadProgress.completedUnitCount*100.f/uploadDownloadProgress.totalUnitCount);
    } success:^(NSURL * _Nullable location, NSURLSessionTask * _Nullable task) {
        NSLog(@"did finished with file:%@",location.absoluteString);
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"error occur:%@",error);
    }];*/
    _task = [CYQNetworkTool backgroundDownloadUrl:@"http://fastsoft.onlinedown.net/down/QQ9.1.7.25980.exe" resumable:YES urlCacheIdentifier:@"78-447" progress:^(NSProgress * _Nullable progress) {
        //printf("%.0f%% ",progress.completedUnitCount*100.f/progress.totalUnitCount);
        NSLog(@"%.0f%%",progress.completedUnitCount*100.f/progress.totalUnitCount);
    } success:^(NSURLSessionTask * _Nullable task, NSURL * _Nullable location) {
        NSLog(@"did finished with file:%@",location.absoluteString);
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        //NSLog(@"error occur:%@",error);
    }];
    
}

-(IBAction)resume:(id)btn{
    [CYQNetworkTool resumeDownloadTaskWithCacheId:@"78-447"];
}

-(IBAction)suspend:(id)btn{
    [CYQNetworkTool suspendDownloadTask:_task withResumeHandller:^{
        [self cyqhttpdownloadbackground:nil];
    }];
}

-(IBAction)cyqhttpdownload:(id)btn{
    /*
    CYQHttpTool *tool = [CYQHttpTool sharedTool];
    _task =  [tool downloadWithUrlStr:@"http://localhost/data/zip/README.zip" downloadProgress:^(NSProgress * _Nullable uploadDownloadProgress) {
        NSLog(@"%.0f%%",uploadDownloadProgress.completedUnitCount*100.f/uploadDownloadProgress.totalUnitCount);
    } success:^(NSURL * _Nullable location, NSURLSessionTask * _Nullable task) {
        NSLog(@"did finished with file:%@",location.absoluteString);
        
        [tool uploadFileWithUrlStr:@"http://localhost/" parameters:@{@"data":@"s"} fileUrl:location uploadProgress:^(NSProgress * _Nullable uploadDownloadProgress) {
            NSLog(@"%.0f%%",uploadDownloadProgress.completedUnitCount*100.f/uploadDownloadProgress.totalUnitCount);
        } success:^(id  _Nullable data, NSURLSessionTask * _Nullable task) {
            NSLog(@"data:%@",data);
        } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
            NSLog(@"error occur:%@",error);
        }];
        
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"error occur:%@",error);
    }];*/
    
    NSURLSessionDownloadTask *task1 = [CYQNetworkTool downloadUrl:@"http://fastsoft.onlinedown.net/down/QQ9.1.7.25980.exe" resumable:NO urlCacheIdentifier:nil progress:^(NSProgress * _Nullable progress) {
        NSLog(@"%.0f%%",progress.completedUnitCount*100.f/progress.totalUnitCount);
    } success:^(NSURLSessionTask * _Nullable task, NSURL * _Nullable location) {
        NSLog(@"did finished with file:%@",location.absoluteString);
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"error occur:%@",error);
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [task1 cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            //NSLog(@"%@",resumeData);
            
        }];
    });
}

-(IBAction)cyqhttppost:(id)btn{
     /*
    CYQHttpTool *tool = [CYQHttpTool sharedTool];
    NSURLSessionDataTask* task = [tool postWithUrlStr:@"http://localhost/" parameters:@{@"data":@15821} success:^(id  _Nullable data, NSURLSessionTask * _Nullable task) {
        
        NSLog(@"data:%@",data);
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"error:%@",error);
    }];
    [task addObserver:self forKeyPath:@"countOfBytesSent" options:NSKeyValueObservingOptionNew context:nil];*/
    
}

-(IBAction)cyqhttpget:(id)btn{
     /*
    CYQHttpTool *tool = [CYQHttpTool sharedTool];
    [tool getWithUrlStr:@"http://localhost/" success:^(id  _Nullable data, NSURLSessionTask * _Nullable task) {
        NSLog(@"data:%@",data);
    } fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"error:%@",error);
    }];
    //[task addObserver:self forKeyPath:@"countOfBytesSent" options:NSKeyValueObservingOptionNew context:nil];*/
    
    [CYQNetworkTool PostUrl:@"http://localhost/" withParams:@{@"data":@"1234"} progress:^(NSProgress * _Nullable progress) {
        NSLog(@"%@",progress);
    } success:^(NSURLSessionTask * _Nullable task, id  _Nullable data) {
        NSLog(@"%@",data);
    }  fail:^(NSURLSessionTask * _Nullable task, NSError * _Nullable error) {
        NSLog(@"%@",error);
    }];
}

-(IBAction)afhttp:(id)btn{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager POST:@"http://localhost/" parameters:@{@"data":@15822} headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"data:%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error:%@",error);
    }];
}
@end
