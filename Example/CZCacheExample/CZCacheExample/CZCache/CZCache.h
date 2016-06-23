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

@interface CZCache <KeyType:NSString *, ObjectType> : NSObject

typedef void (^CZCacheObjectBlock)(CZCache *cache, NSString *key, _Nullable ObjectType<NSCoding> object);

@property (copy, readonly) NSString *name;

@property (strong, readonly) CZMemoryCache *memoryCache;

@property (strong, readonly) CZDiskCache *diskCache;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithName:(NSString *)name directory:(nullable NSString *)directory NS_DESIGNATED_INITIALIZER;


- (nullable ObjectType<NSCoding>)objectForKey:(KeyType)key;
- (void)objectForKey:(NSString *)key completion:(CZCacheObjectBlock)completion;
- (void)setObject:(nullable ObjectType<NSCoding>)object forKey:(KeyType)key;
- (void)setObject:(nullable ObjectType<NSCoding>)object forKey:(KeyType)key age:(NSTimeInterval)age;
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key age:(NSTimeInterval)age completion:(nullable CZCacheObjectBlock)completion;
- (void)removeObjectForKey:(KeyType)key;
- (void)removeObjectForKey:(NSString *)key completion:(nullable void (^)(NSString *))completion;
- (void)removeAllObjects;
- (void)removeAllObjectsAsync:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
