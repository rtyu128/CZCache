//
//  CZCache.m
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZCache.h"
#import "CZFileSupport.h"

static NSString *const kStandardCacheName = @"StandardCache";
static NSString *const kDocumentStorageFolderName = @"DocumentStorage";
static NSString *const kCachesStorageFolderName = @"CachesStorage";

@implementation CZCache

+ (instancetype)standardCache
{
    static CZCache *standardCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        standardCache = [[CZCache alloc]
                         initWithName:kStandardCacheName
                         directory:[[CZFileSupport cachesDirectory] stringByAppendingPathComponent:kCachesStorageFolderName]];
        standardCache.memoryCache.countLimit = 40;
    });
    return standardCache;
}

+ (instancetype)cacheInDocumentDirectoryWithName:(NSString *)name
{
    return [[CZCache alloc]
            initWithName:name
            directory:[[CZFileSupport documentDirectory] stringByAppendingPathComponent:kDocumentStorageFolderName]];
}

+ (instancetype)cacheInCachesDirectoryWithName:(NSString *)name
{
    return [[CZCache alloc]
            initWithName:name
            directory:[[CZFileSupport cachesDirectory] stringByAppendingPathComponent:kCachesStorageFolderName]];
}


- (instancetype)initWithName:(NSString *)name directory:(NSString *)directory
{
    if (!name || 0 == name.length) return nil;
    NSString *fileDirectory = directory.length > 0 ? directory :
                              [[CZFileSupport cachesDirectory] stringByAppendingPathComponent:kCachesStorageFolderName];
    if (self = [super init]) {
        _name = name;
        _storagePath = [fileDirectory stringByAppendingPathComponent:name];
        _diskCache = [[CZDiskCache alloc] initWithDirectory:_storagePath];
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

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key lifeTime:(NSTimeInterval)lifetime
{
    [_memoryCache setObject:object forKey:key lifeTime:lifetime];
    [_diskCache setObject:object forKey:key lifetime:lifetime];
}

- (void)removeObjectForKey:(NSString *)key
{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}


#pragma mark - Keyed Subscript Index

- (id<NSCoding>)objectForKeyedSubscript:(NSString *)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id<NSCoding>)object forKeyedSubscript:(NSString *)key
{
    [self setObject:object forKey:key];
}

#pragma mark - AsyncAccess

- (void)removeAllObjects
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}

- (void)setObject:(id<NSCoding>)object
           forKey:(NSString *)key
         lifeTime:(NSTimeInterval)lifetime
       completion:(CZCacheObjectBlock)completion
{
    [_memoryCache setObject:object forKey:key lifeTime:lifetime];
    __weak typeof (&*self) weakSelf = self;
    [_diskCache
     setObject:object forKey:key lifetime:lifetime
     completion:^(CZDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object, NSTimeInterval remainLife) {
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(self, key, object);
        });
    } else {
        __weak typeof (&*self) weakSelf = self;
        [_diskCache
         objectForKey:key
         completion:^(CZDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object, NSTimeInterval remainLife) {
             __strong typeof (&*weakSelf) strongSelf = weakSelf;
             if (!strongSelf) return;
             if (object) [_memoryCache setObject:object forKey:key lifeTime:remainLife];
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

- (NSString *)description
{
    if (_name) {
        return [NSString stringWithFormat:@"<%@: %p> [%@, %@]", [self class], self, _name, _storagePath];
    } else {
        return [NSString stringWithFormat:@"<%@: %p> [%@]", [self class], self, _storagePath];
    }
}

@end
