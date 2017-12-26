//
//  HWNetworkHelper.m
//  HWNetworkHelperDemo
//
//  Created by Junn on 2017/12/21.
//  Copyright © 2017年 Junn. All rights reserved.
//

#import "HWNetworkHelper.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

#ifdef DEBUG
#define HWLog(...) NSLog(@"%s 第%d行 \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define HWLog(...)
#endif
@implementation HWNetworkHelper

static NetworkStatus _status;//网络状态
static BOOL _isNetwork;//是否有网络

#pragma mark - 开始监听网络状态
/**
 开始监听网络状态(此方法在整个项目中只需要调用一次)
 */
+ (void)startMonitoringNetwork {
    
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                _status ? _status(HWNetworkStatusUnknown) : nil;
                _isNetwork = NO;
                HWLog(@"未知网络");
                break;
            case AFNetworkReachabilityStatusNotReachable:
                _status ? _status(HWNetworkStatusNotReachable) : nil;
                _isNetwork = NO;
                HWLog(@"无网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                _status ? _status(HWNetworkStatusReachableViaWWAN) : nil;
                _isNetwork = YES;
                HWLog(@"移动蜂窝网络");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                _status ? _status(HWNetworkStatusReachableViaWiFi) : nil;
                _isNetwork = YES;
                HWLog(@"WiFi网络");
                break;
                
            default:
                break;
        }
    }];
    [manager startMonitoring];
}

/**
 通过Block 回调实时监测网络状态的改变
 */
+ (void)cheskNetworkStatusWithBlock:(NetworkStatus)status {
    
    status ? _status = status : nil;
}

/**
 获取当前网络状态, 有网 YES, 无网 NO
 */
+ (BOOL)currentNetworkStatus {
    
    return _isNetwork;
}

#pragma mark - GET 请求,无缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    
    return [self GET:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - GET 请求, 自动缓存
+ (NSURLSessionTask *)GET:(NSString *)URL
               parameters:(NSDictionary *)parameters
            responseCache:(HttpRequestCache)responseCache
                  success:(HttpRequestSuccess)success
                  failure:(HttpRequestFailed)failure {
    
    //读取缓存
    responseCache ? responseCache([HWNetworkCache getHttpCacheForKey:URL]) : nil;
    
    //请求数据
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    return [manager GET:URL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
        
        //对数据进行缓存
        responseCache ? [HWNetworkCache saveHttpCache:responseObject forKey:URL] : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
    }];
}

#pragma mark - POST 请求, 无缓存
+ (NSURLSessionTask *)POST:(NSString *)URL
                parameters:(NSDictionary *)parameters
                   success:(HttpRequestSuccess)success
                   failure:(HttpRequestFailed)failure {
    
    return [self POST:URL parameters:parameters responseCache:nil success:success failure:failure];
}

#pragma mark - POST 请求, 自动缓存
+ (NSURLSessionTask *)POST:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                      responseCache:(HttpRequestCache)responseCache
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure {
    
    //读取缓存
    responseCache ? responseCache([HWNetworkCache getHttpCacheForKey:URL]) : nil;
    
    //请求数据
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];

    return [manager POST:URL parameters:parameters progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
        
        //对数据进行异步缓存
        responseCache ? [HWNetworkCache saveHttpCache:responseObject forKey:URL] : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
    }];
}

#pragma mark - 上传图片文件
+ (NSURLSessionTask *)uploadWithURL:(NSString *)URL
                         parameters:(NSDictionary *)parameters
                             images:(NSArray<UIImage *> *)images
                               name:(NSString *)name
                           fileName:(NSString *)fileName
                           mimeType:(NSString *)mimeType
                           progress:(HttpProgress)progress
                            success:(HttpRequestSuccess)success
                            failure:(HttpRequestFailed)failure {
    
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    return [manager POST:URL parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //压缩 - 添加 - 上传
        [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSData *imagedata = UIImageJPEGRepresentation(obj, 0.5);
            [formData appendPartWithFileData:imagedata
                                        name:name
                                    fileName:[NSString stringWithFormat:@"%@%lu",fileName,idx]
                                    mimeType:[NSString stringWithFormat:@"image/%@",mimeType?mimeType:@"jpeg"]];
        }];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        //上传进度
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        success ? success(responseObject) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        failure ? failure(error) : nil;
    }];
}

#pragma mark - 下载文件
+ (NSURLSessionTask *)downloadWithURL:(NSString *)URL
                              fileDir:(NSString *)fileDir
                             progress:(HttpProgress)progress
                              success:(void (^)(NSString *))success
                              failure:(HttpRequestFailed)failure {
    
    AFHTTPSessionManager *manager = [self createAFHTTPSessionManager];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URL]];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        //下载进度
        progress ? progress(downloadProgress) : nil;
        HWLog(@"下载进度: %.2f",100.0 *downloadProgress.completedUnitCount/downloadProgress.totalUnitCount);
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //拼接缓存目录
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        //打开文件管理器
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //创建 Download 目录
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        //拼接文件路径
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        
        HWLog(@"文件下载目录 downloadDir : %@",downloadDir);
        
        //返回文件位置的 URL 路径
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        success ? success(filePath.absoluteString /** NSURL -> NSString*/) : nil;
        failure && error ? failure(error) : nil;
    }];
    
    //开始下载
    [downloadTask resume];
    
    return downloadTask;
}

#pragma mark - 配置 AFHTTPSessionManager
+ (AFHTTPSessionManager *)createAFHTTPSessionManager {
    
    //打开状态栏的等待菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //设置请求的超时时间
    manager.requestSerializer.timeoutInterval = -1;
    
    //设置请求参数的类型: (AFJSONRequestSerializer,AFHTTPRequestSerializer)
    //需要你和后台约定好，不然会出现后台无法获取到你上传的参数问题
    manager.requestSerializer = [AFJSONRequestSerializer serializer];// 上传普通格式
    //manager.requestSerializer = [AFJSONRequestSerializer serializer]; // 上传JSON格式
    
    //设置服务器返回结果的类型: (AFJSONResponseSerializer,AFHTTPResponseSerializer)
    //个人建议还是自己解析的比较好，有时接口返回的数据不合格会报3840错误，大致是AFN无法解析返回来的数据
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];// AFN不会解析,数据是data，需要自己解析
    //manager.responseSerializer = [AFJSONResponseSerializer serializer]; // AFN会JSON解析返回的数据
   
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[
                                                                              @"application/json",
                                                                              @"text/html",@"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*"]];
    
// 加上这行代码，https ssl 验证。
    //[manager setSecurityPolicy:[self customSecurityPolicy]];
    return manager;
}

#pragma mark - https ssl 验证
//如果如果服务端 验证的话, app中就不需要了
+ (AFSecurityPolicy*)customSecurityPolicy {
    
    // 先导入证书
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"证书的名称" ofType:@"cer"];//证书的路径
    NSData *certData = [NSData dataWithContentsOfFile:cerPath];
    
    // AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    // 如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.validatesDomainName = NO;
    
    securityPolicy.pinnedCertificates = [NSSet setWithArray:@[certData]];
    
    return securityPolicy;
}

@end
