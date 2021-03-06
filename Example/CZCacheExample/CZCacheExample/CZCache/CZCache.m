//
//  CZCache.m
//  CZCache
//  https://github.com/rtyu128/CZCache
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZCache.h"
#import "CZFileSupport.h"

static NSString *const kStandardCacheName = @"StandardCache";
static NSString *const kDocumentStorageFolderName = @"DocumentStorage";
static NSString *const kCachesStorageFolderName = @"CachesStorage";

@implementation CZCache


#pragma mark - Life Cycle

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

+ (instancetype)cacheInCachesDirectoryWithName:(NSString *)name
{
    return [[CZCache alloc]
            initWithName:name
            directory:[[CZFileSupport cachesDirectory] stringByAppendingPathComponent:kCachesStorageFolderName]];
}

+ (instancetype)cacheInDocumentDirectoryWithName:(NSString *)name
{
    return [[CZCache alloc]
            initWithName:name
            directory:[[CZFileSupport documentDirectory] stringByAppendingPathComponent:kDocumentStorageFolderName]];
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


#pragma mark - Public
#pragma mark - Access Methods

- (id<NSCoding>)objectForKey:(NSString *)aKey
{
    id<NSCoding> object = [_memoryCache objectForKey:aKey];
    if (!object) {
        NSTimeInterval remainLife = 0;
        object = [_diskCache objectForKey:aKey remainLife:&remainLife];
        if (object) [_memoryCache setObject:object forKey:aKey lifeTime:remainLife];
    }
    return object;
}

- (NSString *)descriptionForKeyValue:(NSString *)aKey
{
    NSData *data = [CZDiskCache extendedDataForObject:[self objectForKey:aKey]];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

- (NSData *)extendedDataForKeyValue:(NSString *)aKey
{
    return [CZDiskCache extendedDataForObject:[self objectForKey:aKey]];
}

- (BOOL)containsObjectForKey:(NSString *)aKey
{
    return [_memoryCache containsObjectForKey:aKey] || [_diskCache containsObjectForKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString *)aKey
{
    [_memoryCache setObject:anObject forKey:aKey];
    [_diskCache setObject:anObject forKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString *)aKey description:(NSString *)desc
{
    if (desc && desc.length > 0) {
        [CZDiskCache setExtendedData:[desc dataUsingEncoding:NSUTF8StringEncoding] forObject:anObject];
    }
    [_memoryCache setObject:anObject forKey:aKey];
    [_diskCache setObject:anObject forKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKey:(NSString *)aKey lifeTime:(NSTimeInterval)lifetime
{
    [_memoryCache setObject:anObject forKey:aKey lifeTime:lifetime];
    [_diskCache setObject:anObject forKey:aKey lifetime:lifetime];
}

- (void)setObject:(id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
     extendedData:(NSData *)extendedData
{
    if (extendedData) [CZDiskCache setExtendedData:extendedData forObject:anObject];
    [_memoryCache setObject:anObject forKey:aKey lifeTime:lifetime];
    [_diskCache setObject:anObject forKey:aKey lifetime:lifetime];
}

- (void)removeObjectForKey:(NSString *)aKey
{
    [_memoryCache removeObjectForKey:aKey];
    [_diskCache removeObjectForKey:aKey];
}

- (void)removeAllObjects
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}


#pragma mark - Keyed Subscript Index

- (id<NSCoding>)objectForKeyedSubscript:(NSString *)aKey
{
    return [self objectForKey:aKey];
}

- (void)setObject:(id<NSCoding>)anObject forKeyedSubscript:(NSString *)aKey
{
    [self setObject:anObject forKey:aKey];
}


#pragma mark - Async Access Methods

- (void)setObject:(id<NSCoding>)anObject
           forKey:(NSString *)aKey
         lifeTime:(NSTimeInterval)lifetime
       completion:(CZCacheObjectBlock)completion
{
    [_memoryCache setObject:anObject forKey:aKey lifeTime:lifetime];
    __weak typeof (&*self) weakSelf = self;
    [_diskCache
     setObject:anObject forKey:aKey lifetime:lifetime
     completion:^(CZDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object, NSTimeInterval remainLife) {
         __strong typeof (&*weakSelf) strongSelf = weakSelf;
         if (!strongSelf) return;
         if (completion) completion(strongSelf, aKey, anObject);
     }];
}

- (void)objectForKey:(NSString *)aKey completion:(CZCacheObjectBlock)completion
{
    if (!completion) return;
    id<NSCoding> object = [_memoryCache objectForKey:aKey];
    if (object) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(self, aKey, object);
        });
    } else {
        __weak typeof (&*self) weakSelf = self;
        [_diskCache
         objectForKey:aKey
         completion:^(CZDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object, NSTimeInterval remainLife) {
             __strong typeof (&*weakSelf) strongSelf = weakSelf;
             if (!strongSelf) return;
             if (object) [_memoryCache setObject:object forKey:aKey lifeTime:remainLife];
             completion(strongSelf, aKey, object);
         }];
    }
}

- (void)containsObjectForKey:(NSString *)aKey completion:(void(^)(NSString *key, BOOL contains))completion
{
    if (!completion) return;
    
    if ([_memoryCache containsObjectForKey:aKey]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(aKey, YES);
        });
    } else {
        [_diskCache containsObjectForKey:aKey completion:completion];
    }
}

- (void)removeObjectForKey:(NSString *)aKey completion:(void (^)(NSString *))completion
{
    [_memoryCache removeObjectForKey:aKey];
    [_diskCache removeObjectForKey:aKey completion:completion];
}

- (void)removeAllObjectsAsync:(void (^)(void))completion
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsAsync:completion];
}


#pragma mark - Description

- (NSString *)description
{
    if (_name) {
        return [NSString stringWithFormat:@"<%@: %p> [%@, %@]", [self class], self, _name, _storagePath];
    } else {
        return [NSString stringWithFormat:@"<%@: %p> [%@]", [self class], self, _storagePath];
    }
}

@end
