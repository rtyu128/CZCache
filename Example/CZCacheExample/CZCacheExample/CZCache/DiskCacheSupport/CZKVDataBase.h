//
//  CZKVDataBase.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CZKVItem;
@interface CZKVDataBase : NSObject

@property (nonatomic, assign) BOOL errorLogsSwitch; // Default is YES.

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithDirectory:(NSString *)directory NS_DESIGNATED_INITIALIZER;


- (BOOL)dbReset;

- (BOOL)dbExecute:(NSString *)sqlStr;

- (BOOL)dbCheck;

- (void)dbCheckpoint;


- (BOOL)dbSaveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename;
- (BOOL)dbSaveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename lifetime:(NSTimeInterval)lifetime;


- (BOOL)dbDeleteItemWithKey:(NSString *)key;

- (CZKVItem *)dbGetItemForKey:(NSString *)key;

- (NSString *)dbGetFilenameWithKey:(NSString *)key;

- (int)dbGetTotalItemSize;
- (int)dbGetTotalItemCount;

@end
