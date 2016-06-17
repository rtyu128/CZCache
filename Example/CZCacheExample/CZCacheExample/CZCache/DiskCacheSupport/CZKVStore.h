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

- (instancetype)initWithPath:(NSString *)path;

- (BOOL)saveItem:(CZKVItem *)item;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename;

- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeAllItems;

- (CZKVItem *)getItemForKey:(NSString *)key;
- (NSData *)getItemValueForKey:(NSString *)key;

- (BOOL)containsItemForKey:(NSString *)key;

- (int)totalItemsCount;
- (int)totalItemsSize;

@end
