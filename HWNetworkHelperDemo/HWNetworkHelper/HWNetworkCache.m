//
//  HWNetworkCache.m
//  HWNetworkHelperDemo
//
//  Created by Junn on 2017/12/22.
//  Copyright © 2017年 Junn. All rights reserved.
//

#import "HWNetworkCache.h"
#import "YYCache.h"

@implementation HWNetworkCache
static NSString *const NetworkResponseCache = @"NetworkResponseCache";
static YYCache *_dataCache;

#pragma mark - 初始化 YYCache
+ (void)initialize {
    
    _dataCache = [YYCache cacheWithName:NetworkResponseCache];
}

+ (void)saveHttpCache:(id)httpCache forKey:(NSString *)key {
    
    //一部缓存, 不会阻塞主线程
    [_dataCache setObject:httpCache forKey:key withBlock:nil];
}

+ (id)getHttpCacheForKey:(NSString *)key {
    
    return [_dataCache objectForKey:key];
}

+ (NSInteger)getAllHttpCacheSize {
    
    return [_dataCache.diskCache totalCost];
}

+ (void)removeAllHttpCache {
    
    [_dataCache.diskCache removeAllObjects];
}

@end
