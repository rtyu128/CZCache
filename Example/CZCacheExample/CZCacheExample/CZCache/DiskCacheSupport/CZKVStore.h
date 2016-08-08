//
//  CZKVStore.h
//  CZCache
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CZKVItem;

/**
 CZKVStore is a key-value storage based on sqlite and file system.
 Generally, there is no need to use this class directly.
 */
@interface CZKVStore : NSObject

/**
 Designated initializer for CZKVStore.
 After initialized, folders in the directory will as follow:
    directory
             /database(store sqlite files)
             /value(store value files)
             /asshole(store trash files temporarily)
 */
- (instancetype)initWithDirectory:(NSString *)directory;

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(nullable NSString *)filename;
- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(nullable NSString *)filename
               lifetime:(NSTimeInterval)lifetime
           extendedData:(nullable NSData *)extendedData;

- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeAllItems;

- (nullable NSData *)getItemValueForKey:(NSString *)key;
- (nullable CZKVItem *)getItemForKey:(NSString *)key;

- (int)totalItemsCount;
- (int)totalItemsSize;

@end

NS_ASSUME_NONNULL_END