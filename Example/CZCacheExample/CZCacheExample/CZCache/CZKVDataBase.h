//
//  CZKVDataBase.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CZKeyValueItem;
@interface CZKVDataBase : NSObject

@property (nonatomic, assign) BOOL errorLogsSwitch; // Default is YES.


- (instancetype)initWithDirectory:(NSString *)directory;

- (BOOL)dbReset;

- (BOOL)dbExecute:(NSString *)sqlStr;

- (BOOL)dbCheck;

- (void)dbCheckpoint;

- (BOOL)dbSaveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename;

- (BOOL)dbDeleteItemWithKey:(NSString *)key;

- (CZKeyValueItem *)dbGetItemForKey:(NSString *)key;

- (NSData *)dbGetValueForKey:(NSString *)key;

- (NSString *)dbGetFilenameWithKey:(NSString *)key;

- (int)dbGetTotalItemSize;

- (int)dbGetTotalItemCount;

@end
