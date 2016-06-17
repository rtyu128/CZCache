//
//  CZMemoryCache.h
//  CZCache
//
//  Created by Anchor on 16/5/20.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CZMemoryCache : NSObject

@property (nullable, copy) NSString *name;

@property (readonly) NSInteger totalCount;

//@property (readonly) NSInteger totalSize;

@property NSInteger countLimit;

//@property NSInteger sizeLimit;

@property NSTimeInterval timeLimit;

@property NSTimeInterval autoTrimInterval;

@property BOOL releaseOnMainThread;

@property BOOL releaseAsynchronously;

@property BOOL shouldRemoveAllObjectsWhenMemoryWarning;

@property BOOL shouldRemoveAllObjectsWhenEnteringBackground;

- (instancetype)initWithName:(nullable NSString *)name NS_DESIGNATED_INITIALIZER;

- (void)setObject:(nullable id)object forKey:(id)key;

- (nullable id)objectForKey:(id)key;

- (void)removeObjectForKey:(id)key;

- (void)removeAllObjects;

- (BOOL)containsObjectForKey:(id)key;


- (void)trimToCountLimit:(NSUInteger)count;

- (void)trimToTimeLimit:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END