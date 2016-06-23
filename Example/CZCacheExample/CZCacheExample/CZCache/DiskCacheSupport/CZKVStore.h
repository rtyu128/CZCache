//
//  CZKVStore.h
//  CZCache
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CZKVItem;
@interface CZKVStore : NSObject

- (instancetype)initWithDirectory:(NSString *)directory;

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename lifetime:(NSTimeInterval)lifetime;

- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeAllItems;

- (CZKVItem *)getItemForKey:(NSString *)key;
//- (NSData *)getItemValueForKey:(NSString *)key; // 暂时注调 因为加了lifeTime后用此方法无法判断有效性


- (int)totalItemsCount;
- (int)totalItemsSize;

@end
