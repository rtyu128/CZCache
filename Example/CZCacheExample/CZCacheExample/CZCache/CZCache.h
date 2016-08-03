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

NS_ASSUME_NONNULL_BEGIN

/**
 Thanks for ibireme and his powerful YYCache:
 https://github.com/ibireme/YYCache
 */
@interface CZCache <KeyType:NSString *, ObjectType> : NSObject

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


- (nullable ObjectType<NSCoding>)objectForKey:(KeyType)key;
- (nullable ObjectType<NSCoding>)objectForKeyedSubscript:(KeyType)key;

- (void)setObject:(nullable ObjectType<NSCoding>)object forKey:(KeyType)key;
- (void)setObject:(nullable ObjectType<NSCoding>)object forKey:(KeyType)key age:(NSTimeInterval)age;
- (void)setObject:(nullable ObjectType<NSCoding>)object forKeyedSubscript:(KeyType)key;

- (void)removeObjectForKey:(KeyType)key;
- (void)removeAllObjects;

@end


@interface CZCache <KeyType:NSString *, ObjectType> (AsyncAccess)

typedef void (^CZCacheObjectBlock)(CZCache *cache, NSString *key, _Nullable ObjectType<NSCoding> object);

- (void)objectForKey:(KeyType)key completion:(CZCacheObjectBlock)completion;
- (void)setObject:(nullable ObjectType<NSCoding>)object
           forKey:(KeyType)key
              age:(NSTimeInterval)age
       completion:(nullable CZCacheObjectBlock)completion;
- (void)removeObjectForKey:(KeyType)key completion:(nullable void (^)(NSString * key))completion;
- (void)removeAllObjectsAsync:(nullable CZCacheNoParamsBlock)completion;

@end

NS_ASSUME_NONNULL_END
