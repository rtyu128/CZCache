//
//  CZDiskCache.h
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CZDiskCache;
typedef void  (^CZDiskCacheObjectBlock)(CZDiskCache *cache, NSString *key, _Nullable id<NSCoding> object);

@interface CZDiskCache : NSObject

@property (copy, nullable) NSString *name;

@property (readonly) NSString *path;

@property (assign, readonly) NSUInteger dbStoreThreshold;

@property NSUInteger countLimit;

@property NSUInteger sizeLimit;

//@property BOOL errorLogsSwitch;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (nullable instancetype)initWithDirectory:(NSString *)directory;
- (nullable instancetype)initWithDirectory:(NSString *)directory dbStoreThreshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;


- (nullable id<NSCoding>)objectForKey:(NSString *)key;
- (nullable id<NSCoding>)objectForKey:(NSString *)key remainLife:(nullable NSTimeInterval *)remainLife;
- (void)objectForKey:(NSString *)key completion:(CZDiskCacheObjectBlock)completion;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key lifetime:(NSTimeInterval)lifetime;
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key lifetime:(NSTimeInterval)lifetime completion:(nullable CZDiskCacheObjectBlock)completion;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key completion:(nullable void (^)(NSString *key))completion;
- (void)removeAllObjects;
- (void)removeAllObjectsAsync:(nullable void (^)(void))completion;

- (NSInteger)totalCount;
- (NSInteger)totalSize;

@end

NS_ASSUME_NONNULL_END