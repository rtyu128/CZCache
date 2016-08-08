//
//  CZCache.h
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZMemoryCache.h"
#import "CZDiskCache.h"
#import "CZCacheDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Thanks for ibireme and his powerful YYCache:
 https://github.com/ibireme/YYCache
 */
@interface CZCache : NSObject

@property (copy, readonly) NSString *name;
@property (readonly) NSString *storagePath;

@property (strong, readonly) CZMemoryCache *memoryCache;

@property (strong, readonly) CZDiskCache *diskCache;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
+ (nullable instancetype)standardCache;
+ (nullable instancetype)cacheInDocumentDirectoryWithName:(NSString *)name;
+ (nullable instancetype)cacheInCachesDirectoryWithName:(NSString *)name;
- (nullable instancetype)initWithName:(NSString *)name directory:(nullable NSString *)directory NS_DESIGNATED_INITIALIZER;


- (nullable id<NSCoding>)objectForKey:(NSString *)key;
- (nullable NSString *)descriptionForKeyValue:(NSString *)aKey;
- (nullable NSData *)extendedDataForKeyValue:(NSString *)aKey;

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key description:(NSString *)desc;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key lifeTime:(NSTimeInterval)lifetime;
- (void)setObject:(nullable id<NSCoding>)object
           forKey:(NSString *)key
         lifeTime:(NSTimeInterval)lifetime
     extendedData:(NSData *)extendedData;

- (nullable id<NSCoding>)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKeyedSubscript:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end


@interface CZCache (CZCacheAsyncAccess)

typedef void (^CZCacheObjectBlock)(CZCache *cache, NSString *key, _Nullable id<NSCoding> object);

- (void)objectForKey:(NSString *)key completion:(CZCacheObjectBlock)completion;
- (void)setObject:(nullable id<NSCoding>)object
           forKey:(NSString *)key
         lifeTime:(NSTimeInterval)lifetime
       completion:(nullable CZCacheObjectBlock)completion;
- (void)removeObjectForKey:(NSString *)key completion:(nullable void (^)(NSString * key))completion;
- (void)removeAllObjectsAsync:(nullable CZCacheNoParamsBlock)completion;

@end

NS_ASSUME_NONNULL_END
