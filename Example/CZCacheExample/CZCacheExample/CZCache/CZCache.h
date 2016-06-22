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

@property (copy, readonly) NSString *name;

@property (strong, readonly) CZMemoryCache *memoryCache;

@property (strong, readonly) CZDiskCache *diskCache;


- (nullable instancetype)initWithName:(NSString *)name;
- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable ObjectType <NSCoding>)objectForKey:(KeyType)key;
- (void)setObject:(nullable ObjectType <NSCoding>)object forKey:(KeyType)key;
- (void)removeObjectForKey:(KeyType)key;
- (void)removeAllOnjects;

@end

NS_ASSUME_NONNULL_END
