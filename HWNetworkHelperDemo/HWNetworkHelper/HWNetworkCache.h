//
//  HWNetworkCache.h
//  HWNetworkHelperDemo
//
//  Created by Junn on 2017/12/22.
//  Copyright © 2017年 Junn. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - 网络数据缓存类

@interface HWNetworkCache : NSObject

/**
 缓存网络数据

 @param httpCache 服务器返回的数据
 @param key 缓存数据对应的 key 值, 推荐填入请求的 URL
 */
+ (void)saveHttpCache:(id)httpCache forKey:(NSString *)key;

/**
 读取缓存的数据

 @param key 根据存入时填入的 key 值来读取对应的数据
 @return 缓存的数据  
 */
+ (id)getHttpCacheForKey:(NSString *)key;

/**
 获取网络缓存的总大小 bytes(字节)
 */
+ (NSInteger)getAllHttpCacheSize;

/**
 删除所有网络缓存
 */
+ (void)removeAllHttpCache;

@end
