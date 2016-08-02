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
@interface CZKVStore : NSObject

- (instancetype)initWithDirectory:(NSString *)directory;

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(nullable NSString *)filename;
- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(nullable NSString *)filename
               lifetime:(NSTimeInterval)lifetime;

- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeAllItems;

- (nullable NSData *)getItemValueForKey:(NSString *)key;
- (nullable CZKVItem *)getItemForKey:(NSString *)key;

- (int)totalItemsCount;
- (int)totalItemsSize;

@end

NS_ASSUME_NONNULL_END