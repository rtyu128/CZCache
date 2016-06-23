//
//  CZDiskCache.h
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key lifetime:(NSTimeInterval)lifetime;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

- (NSInteger)totalCount;
- (NSInteger)totalSize;

@end

NS_ASSUME_NONNULL_END