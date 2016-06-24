//
//  CZMemoryCache.h
//  CZCache
//
//  Created by Anchor on 16/5/20.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CZMemoryCache;
typedef void (^CZMemCacheCallBack)(CZMemoryCache *cache);

@interface CZMemoryCache <KeyType, ObjectType> : NSObject

@property (nullable, copy) NSString *name;

@property (readonly) NSInteger totalCount;

@property NSInteger countLimit;
@property NSTimeInterval autoTrimInterval;

@property BOOL enableExpireClean;
@property BOOL releaseOnMainThread;
@property BOOL releaseAsynchronously;

@property BOOL shouldRemoveAllObjectsWhenMemoryWarning;
@property BOOL shouldRemoveAllObjectsWhenEnteringBackground;
@property (copy, nullable) CZMemCacheCallBack didReceiveMemoryWarningBlock;
@property (copy, nullable) CZMemCacheCallBack didEnterBackgroundBlock;

- (nullable instancetype)initWithName:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;

- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;
- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key lifeTime:(NSTimeInterval)age;

- (nullable ObjectType)objectForKey:(KeyType)key;

- (void)removeObjectForKey:(KeyType)key;

- (void)removeAllObjects;

- (void)trimToCountLimit:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END