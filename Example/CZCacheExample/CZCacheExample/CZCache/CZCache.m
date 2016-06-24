//
//  CZCache.m
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZCache.h"
#import "CZFileSupport.h"

@implementation CZCache

- (instancetype)initWithName:(NSString *)name directory:(NSString *)directory
{
    if (0 == name.length) return nil;
    NSString *fileDirectory = 0 == directory.length ? [CZFileSupport cachesDirectory] : directory;
    if (self = [super init]) {
        _name = name;
        _diskCache = [[CZDiskCache alloc] initWithDirectory:[fileDirectory stringByAppendingPathComponent:name]];
        if (!_diskCache) return nil;
        _memoryCache = [[CZMemoryCache alloc] initWithName:name];
    }
    return self;
}

- (id<NSCoding>)objectForKey:(NSString *)key
{
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (!object) {
        NSTimeInterval remainLife = 0;
        object = [_diskCache objectForKey:key remainLife:&remainLife];
        if (object) [_memoryCache setObject:object forKey:key lifeTime:remainLife];
    }
    return object;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key age:(NSTimeInterval)age
{
    [_memoryCache setObject:object forKey:key lifeTime:age];
    [_diskCache setObject:object forKey:key lifetime:age];
}

- (void)removeObjectForKey:(NSString *)key
{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}


#pragma mark - AsyncAccess

- (void)removeAllObjects
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key age:(NSTimeInterval)age completion:(CZCacheObjectBlock)completion
{
    [_memoryCache setObject:object forKey:key lifeTime:age];
    __weak typeof (&*self) weakSelf = self;
    [_diskCache
     setObject:object forKey:key lifetime:age
     completion:^(CZDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
         __strong typeof (&*weakSelf) strongSelf = weakSelf;
         if (!strongSelf) return;
         if (completion) completion(strongSelf, key, object);
     }];
}

- (void)objectForKey:(NSString *)key completion:(CZCacheObjectBlock)completion
{
    if (!completion) return;
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (object) {
        
    } else {
        __weak typeof (&*self) weakSelf = self;
        [_diskCache
         objectForKey:key
         completion:^(CZDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
             __strong typeof (&*weakSelf) strongSelf = weakSelf;
             if (!strongSelf) return;
             completion(strongSelf, key, object);
         }];
    }
}

- (void)removeObjectForKey:(NSString *)key completion:(void (^)(NSString *))completion
{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key completion:completion];
}

- (void)removeAllObjectsAsync:(void (^)(void))completion
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsAsync:completion];
}

@end
