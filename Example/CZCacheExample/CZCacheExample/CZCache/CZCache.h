//
//  CZCache.h
//  CZCacheExample
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZMemoryCache.h"
#import "CZDiskCache.h"


NS_ASSUME_NONNULL_BEGIN

@interface CZCache : NSObject

@property (copy, readonly) NSString *name;

@property (strong, readonly) CZMemoryCache *memoryCache;

@property (strong, readonly) CZDiskCache *diskCache;


- (nullable instancetype)initWithName:(NSString *)name;
- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;


- (BOOL)containsObjectForKey:(NSString *)key;
- (nullable id<NSCoding>)objectForKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllOnjects;

@end

NS_ASSUME_NONNULL_END
