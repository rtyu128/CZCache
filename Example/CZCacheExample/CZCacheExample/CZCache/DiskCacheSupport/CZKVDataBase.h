//
//  CZKVDataBase.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CZKVItem;
/**
 CZKVDataBase is only a single SQLite database. Used for storing CZKVItem.
 If you need to handle complex task with database, maybe FMDB or CoreData is the best choice.
 
 Thanks for sqlite3's authors and their great works.
 */
@interface CZKVDataBase : NSObject

@property (nonatomic, assign) BOOL errorLogsSwitch; // Default is YES.

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Designated initializer for CZKVDATABase.
 After initialized, files in the directory will as follow:
    directory
             /KeyValueDataBase.sqlite
             /KeyValueDataBase.sqlite-shm
             /KeyValueDataBase.sqlite-wal
 @Improtant: Directory must exist.
 */
- (instancetype)initWithDirectory:(NSString *)directory NS_DESIGNATED_INITIALIZER;

- (BOOL)dbReset;

- (BOOL)dbExecute:(NSString *)sqlStr;

- (BOOL)dbCheck;

- (void)dbCheckpoint;

- (nullable CZKVItem *)dbGetItemForKey:(NSString *)key;

- (BOOL)dbSaveItemWithKey:(NSString *)key value:(NSData *)value filename:(nullable NSString *)filename;
- (BOOL)dbSaveItemWithKey:(NSString *)key
                    value:(NSData *)value
                 filename:(nullable NSString *)filename
                 lifetime:(NSTimeInterval)lifetime
             extendedData:(nullable NSData *)extendedData;

- (nullable NSString *)dbGetFilenameWithKey:(NSString *)key;
- (nullable NSArray<NSString *> *)dbGetFilenamesWithExpireDateEarlierThan:(NSInteger)date;
- (nullable NSArray<CZKVItem *> *)dbGetItemsOrderByExpireDateAscWithLimit:(NSInteger)rowNum;

- (BOOL)dbDeleteItemWithKey:(NSString *)key;
- (BOOL)dbDeleteItemsWithExpireDateEarlierThan:(NSInteger)time;

- (NSInteger)dbGetTotalItemSize;
- (NSInteger)dbGetTotalItemCount;

@end

NS_ASSUME_NONNULL_END
