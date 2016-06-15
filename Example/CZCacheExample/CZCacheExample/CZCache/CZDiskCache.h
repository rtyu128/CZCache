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

@property BOOL errorLogsSwitch;

- (nullable instancetype)initWithPath:(NSString *)path;
- (nullable instancetype)initWithPath:(NSString *)path dbStoreThreshold:(NSUInteger) threshold;

- (nullable id<NSCoding>)objectForKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;
- (BOOL)constainObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

- (NSInteger)totalCount;
- (NSInteger)totalSize;

@end

NS_ASSUME_NONNULL_END