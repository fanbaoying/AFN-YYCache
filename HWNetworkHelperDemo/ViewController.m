//
//  ViewController.m
//  HWNetworkHelperDemo
//
//  Created by Junn on 2017/12/21.
//  Copyright © 2017年 Junn. All rights reserved.
//

#import "ViewController.h"
#import "HWNetworkHelper.h"

static NSString *const dataUrl = @"https://api.thinkpage.cn/v3/weather/daily.json?key=osoydf7ademn8ybv&location=chongqing&language=zh-Hans&start=0&days=3";
static NSString *const downloadUrl = @"http://wvideo.spriteapp.cn/video/2016/0328/56f8ec01d9bfe_wpd.mp4";

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextView *networkData;
@property (weak, nonatomic) IBOutlet UITextView *cacheData;
@property (weak, nonatomic) IBOutlet UILabel *cacheStatus;
@property (weak, nonatomic) IBOutlet UISwitch *cacheSwitch;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

/** 是否开启缓存*/
@property (nonatomic, assign, getter=isCache) BOOL cache;

/** 是否开始下载*/
@property (nonatomic, assign, getter=isDownload) BOOL download;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"网络缓存大小: %.2fMB",[HWNetworkCache getAllHttpCacheSize]/1024/1024.f);
    [self cheskNetworkStatus];
}
#pragma mark - 检测网络状态
- (void)cheskNetworkStatus {
    
    //检测网络状态
    [HWNetworkHelper cheskNetworkStatusWithBlock:^(HWNetworkStatus status) {
        
        switch (status) {
            case HWNetworkStatusUnknown:
            case HWNetworkStatusNotReachable:
                
                self.networkData.text = @"没有网络";
                [self getData:YES url:dataUrl];
                NSLog(@"-- 无网络, 加载缓存 -- ");
                break;
            case HWNetworkStatusReachableViaWWAN:
            case HWNetworkStatusReachableViaWiFi:
                
                [self getData:[[NSUserDefaults standardUserDefaults] boolForKey:@"isOn"] url:dataUrl];
                NSLog(@"-- 有网络, 获取最新数据 --");
            default:
                break;
        }
    }];
}
#pragma  mark - 获取数据
- (void)getData:(BOOL)isOn url:(NSString *)url {
    
    //自动缓存
    if (isOn) {
        
        self.cacheStatus.text = @"缓存已打开";
        self.cacheSwitch.on = YES;
        
        //
        [HWNetworkHelper GET:url parameters:nil responseCache:^(id responseCache) {
            
            self.cacheData.text = [self jsonToData:responseCache];
        } success:^(id responseObject) {
            
            self.networkData.text = [self jsonToData:responseObject];
        } failure:^(NSError *error) {
            
            NSLog(@"error1 = %@",error);
        }];
    }else{
        
        self.cacheStatus.text = @"缓存已关闭";
        self.cacheSwitch.on = NO;
        self.cacheData.text = @"";
        //
        [HWNetworkHelper GET:url parameters:nil success:^(id responseObject) {
            
            
            self.networkData.text = [self jsonToData:responseObject];
        } failure:^(NSError *error) {
            
            NSLog(@"error2 = %@",error);
        }];
    }
}

#pragma mark - 下载
- (IBAction)download:(UIButton *)sender {
    
    static NSURLSessionTask *task = nil;
    
    //开始下载
    if (!self.isDownload) {
        
        self.download = YES;
        [self.downloadBtn setTitle:@"取消下载" forState:UIControlStateNormal];
        
        //
        task = [HWNetworkHelper downloadWithURL:downloadUrl fileDir:@"Download" progress:^(NSProgress *progress) {
            
            CGFloat stauts = 100.f * progress.completedUnitCount/progress.totalUnitCount;
            
            //在主线程更新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progress.progress = stauts/100.f;
            });
            
            NSLog(@"下载进度 :%.2f%%,,%@",stauts,[NSThread currentThread]);
        } success:^(NSString *filePath) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"下载完成!" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
            [self.downloadBtn setTitle:@"重新下载" forState:UIControlStateNormal];
            NSLog(@"filePath = %@",filePath);
        } failure:^(NSError *error) {
            
            NSLog(@"error3 = %@",error);
        }];
    }else{ //暂停下载
        
        self.download = NO;
        [task suspend];
        self.progress.progress = 0;
        [self.downloadBtn setTitle:@"开始下载" forState:UIControlStateNormal];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self.view endEditing:YES];
    
}

#pragma mark - 缓存开关
- (IBAction)isCache:(UISwitch *)sender {
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setBool:sender.isOn forKey:@"isOn"];
    [userDefault synchronize];
    
    //
    [self getData:sender.isOn url:dataUrl];
}

/**
 *  json转字符串
 */
- (NSString *)jsonToData:(NSData *)data {
    if(!data){
        return nil;
    }
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
