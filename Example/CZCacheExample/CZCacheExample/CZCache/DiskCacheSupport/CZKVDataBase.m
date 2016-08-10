//
//  CZKVDataBase.m
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZKVDataBase.h"
#import "CZKVItem.h"
#import <UIKit/UIKit.h>
#import <time.h>

#if __has_include(<sqlite3.h>)
#import <sqlite3.h>
#else
#error "Please import libsqlite3.tbd"
#endif

static const NSUInteger kMaxOpenRetryCount = 8;
static const NSTimeInterval kMinOpenRetryTimeInterval = 1.0;
static NSString *const kDataBaseName = @"KeyValueDataBase.sqlite";
static NSString *const kDataBaseShmFileName = @"KeyValueDataBase.sqlite-shm";
static NSString *const kDataBaseWalFileName = @"KeyValueDataBase.sqlite-wal";


@implementation CZKVDataBase {
    NSString *dbDirectory;
    NSString *dbPath;
    
    sqlite3 *dataBase;
    CFMutableDictionaryRef dbStmtCache;
    NSTimeInterval dbLastOpenErrorTime;
    NSUInteger dbOpenErrorCount;
}

- (instancetype)initWithDirectory:(NSString *)directory
{
    if (self = [super init]) {
        dbDirectory = directory;
        dbPath = [dbDirectory stringByAppendingPathComponent:kDataBaseName];
        _errorLogsSwitch = YES;
        dbOpenErrorCount = 0;
        dbLastOpenErrorTime = 0;
        
        if (![self dbOpen] || ![self dbInitialize]) {
            if (![self dbReset]) {
                [self dbClose];
                [self dbCleanFiles];
                if (_errorLogsSwitch) NSLog(@"CZKVDataBase %s line %d: sqlite initialize error.", __func__, __LINE__);
                return nil;
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [self dbClose];
}

- (BOOL)dbReset
{
    if (![self dbClose]) return NO;
    
    [self dbCleanFiles];
    
    if ([self dbOpen] && [self dbInitialize]){
        return YES;
    } else {
        return NO;
    }
}

- (void)dbCleanFiles
{
    [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[dbDirectory stringByAppendingPathComponent:kDataBaseShmFileName]
                                               error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[dbDirectory stringByAppendingPathComponent:kDataBaseWalFileName]
                                               error:nil];
}

- (BOOL)dbOpen
{
    if (dataBase) return YES;
    
    int result = sqlite3_open(dbPath.UTF8String, &dataBase);
    if (result == SQLITE_OK) {
        CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
        CFDictionaryValueCallBacks valueCallbacks = {0};
        dbStmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
        dbOpenErrorCount = 0;
        dbLastOpenErrorTime = 0;
        return YES;
    } else {
        dataBase = NULL;
        if (dbStmtCache) CFRelease(dbStmtCache);
        dbStmtCache = NULL;
        dbOpenErrorCount ++;
        dbLastOpenErrorTime = CACurrentMediaTime();
        
        if (_errorLogsSwitch) NSLog(@"%s line %d: database open failed (%d).", __func__, __LINE__, result);
        return NO;
    }
}

- (BOOL)dbClose
{
    if (!dataBase) return YES;
    
    if (dbStmtCache) {
        CFRelease(dbStmtCache);
        dbStmtCache = NULL;
    }
    
    int result = 0;
    BOOL retry = NO;
    BOOL isStmtFinalized = NO;
    
    do {
        retry = NO;
        result = sqlite3_close(dataBase);
        if (SQLITE_BUSY == result || SQLITE_LOCKED == result) {
            if (!isStmtFinalized) {
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(dataBase, nil)) != 0) {
                    sqlite3_finalize(stmt);
                    retry = YES;
                }
                isStmtFinalized = YES;
            }
        } else if (SQLITE_OK != result) {
            if (_errorLogsSwitch) NSLog(@"%s line %d: database close faild (%d).", __func__, __LINE__, result);
        }
    } while (retry);
    
    dataBase = NULL;
    return YES;
}

- (BOOL)dbExecute:(NSString *)sqlStr
{
    if (sqlStr.length == 0) return NO;
    if (![self dbCheck]) return NO;
    
    char *errmsg = NULL;
    int result = sqlite3_exec(dataBase, sqlStr.UTF8String, NULL, NULL, &errmsg);
    if (errmsg) {
        if (_errorLogsSwitch) NSLog(@"%s line %d: database exec error (%d): %s", __func__, __LINE__, result, errmsg);
        sqlite3_free(errmsg);
    }
    
    return result == SQLITE_OK;
}

- (BOOL)dbInitialize
{
    NSString *initSql = @"pragma journal_mode = wal; pragma synchronous = normal; create table if not exists KeyValues (key text NOT NULL, value_data blob, filename text, size integer, expire_date integer default 0, extended_data blob, primary key(key)); create index if not exists expire_date_index on KeyValues(expire_date);";
    return [self dbExecute:initSql];
}

- (BOOL)dbCheck
{
    if (!dataBase) {
        if (dbOpenErrorCount <= kMaxOpenRetryCount &&
            (CACurrentMediaTime() - dbLastOpenErrorTime > kMinOpenRetryTimeInterval)) {
            return [self dbOpen] && [self dbInitialize];
        } else {
            return NO;
        }
    } else {
        return YES;
    }
}

- (void)dbCheckpoint
{
    if (![self dbCheck]) return;
    sqlite3_wal_checkpoint(dataBase, NULL);
}

- (sqlite3_stmt *)dbPrepareStmt:(NSString *)sqlStr
{
    if (![self dbCheck] || sqlStr.length == 0 || !dbStmtCache) return NULL;
    
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(dbStmtCache, (__bridge const void *)sqlStr);
    if (!stmt) {
        int result = sqlite3_prepare_v2(dataBase, sqlStr.UTF8String, -1, &stmt, NULL);
        if (result != SQLITE_OK) {
            if (_errorLogsSwitch)
                NSLog(@"%s line %d: sqlite stmt[%@] prepare error (%d): %s", __func__, __LINE__, sqlStr, result, sqlite3_errmsg(dataBase));
            return NULL;
        }
        CFDictionarySetValue(dbStmtCache, (__bridge const void *)sqlStr, stmt);
    } else {
        sqlite3_reset(stmt);
    }
    
    return stmt;
}

- (BOOL)dbSaveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename
{
    return [self dbSaveItemWithKey:key value:value filename:filename lifetime:CZ_LIVE_FOREVER extendedData:nil];
}

- (BOOL)dbSaveItemWithKey:(NSString *)key
                    value:(NSData *)value
                 filename:(NSString *)filename
                 lifetime:(NSTimeInterval)lifetime
             extendedData:(NSData *)extendedData
{
    NSString *sqlStr = @"insert or replace into KeyValues (key, value_data, filename, size, expire_date, extended_data) values (?1, ?2, ?3, ?4, ?5, ?6);";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return NO;
    
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    if (filename.length > 0) {
        sqlite3_bind_blob(stmt, 2, NULL, 0, NULL);
        sqlite3_bind_text(stmt, 3, filename.UTF8String, -1, NULL);
    } else {
        sqlite3_bind_blob(stmt, 2, value.bytes, (int)value.length, NULL);
        sqlite3_bind_text(stmt, 3, NULL, 0, NULL);
    }
    sqlite3_bind_int(stmt, 4, (int)value.length);
    
    long expireDate = lifetime > 0 ? time(NULL) + lifetime : 0;
    sqlite3_bind_int64(stmt, 5, expireDate);
    
    if (extendedData) {
        sqlite3_bind_blob(stmt, 6, extendedData.bytes, (int)extendedData.length, 0);
    } else {
        sqlite3_bind_blob(stmt, 6, NULL, 0, NULL);
    }
    
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database instert/replace error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return NO;
    }
    return YES;
}

- (CZKVItem *)dbGetItemForKey:(NSString *)key
{
    NSString *sqlStr = @"select key, value_data, filename, size, expire_date, extended_data from KeyValues where key = ?;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    CZKVItem *item = nil;
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        item = [self dbGetItemFromStmt:stmt];
    } else {
        if (result != SQLITE_DONE) {
            if (_errorLogsSwitch)
                NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        }
    }
    return item;
}

- (CZKVItem *)dbGetItemFromStmt:(sqlite3_stmt *)stmt
{
    int i = 0;
    char *key = (char *)sqlite3_column_text(stmt, i++);
    const void *valueData = sqlite3_column_blob(stmt, i);
    int valueDataSize = sqlite3_column_bytes(stmt, i++);
    char *filename = (char *)sqlite3_column_text(stmt, i++);
    int size = sqlite3_column_int(stmt, i++);
    long expireDate = sqlite3_column_int64(stmt, i++);
    const void *extendedData = sqlite3_column_blob(stmt, i);
    int extendedDataSize = sqlite3_column_bytes(stmt, i++);
    
    CZKVItem *item = [[CZKVItem alloc] init];
    if (key) item.key = [NSString stringWithUTF8String:key];
    if (valueData && valueDataSize > 0) item.value = [NSData dataWithBytes:valueData length:valueDataSize];
    if (filename && *filename != 0) item.filename = [NSString stringWithUTF8String:filename];
    item.size = size;
    item.expireDate = expireDate;
    if (extendedData && extendedDataSize > 0) item.extendedData = [NSData dataWithBytes:extendedData length:extendedDataSize];
    return item;
}

- (NSString *)dbGetFilenameWithKey:(NSString *)key
{
    NSString *sqlStr = @"select filename from KeyValues where key = ?;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        char *filename = (char *)sqlite3_column_text(stmt, 0);
        if (filename && *filename != 0)
            return [NSString stringWithUTF8String:filename];
    } else {
        if (result != SQLITE_DONE) {
            if (_errorLogsSwitch)
                NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        }
    }
    return nil;
}

- (NSArray<NSString *> *)dbGetFilenamesWithExpireDateEarlierThan:(NSInteger)date
{
    NSString *sqlStr = @"select filename from KeyValues where expire_date < ? and expire_date > 0 and filename is not null;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return nil;
    sqlite3_bind_int64(stmt, 1, date);
    
    int result = sqlite3_step(stmt);
    NSMutableArray<NSString *> *filenames = [NSMutableArray array];
    while (result == SQLITE_ROW) {
        char *name = (char *)sqlite3_column_text(stmt, 0);
        if (name && *name != 0) {
            NSString *filename = [NSString stringWithUTF8String:name];
            if (filename) [filenames addObject:filename];
        }
        result = sqlite3_step(stmt);
    }
    
    if (result != SQLITE_DONE) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        filenames = nil;
    }
    
    return filenames ? [filenames copy] : nil;
}

- (NSArray<CZKVItem *> *)dbGetItemsOrderByExpireDateAscWithLimit:(NSInteger)rowNum
{
    NSString *sqlStr = @"select key, filename, size from KeyValues order by expire_date asc limit ?;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return nil;
    sqlite3_bind_int64(stmt, 1, rowNum);
    
    int result = sqlite3_step(stmt);
    NSMutableArray *items = [NSMutableArray array];
    while (result == SQLITE_ROW) {
        char *key = (char *)sqlite3_column_text(stmt, 0);
        char *filename = (char *)sqlite3_column_text(stmt, 1);
        int size = sqlite3_column_int(stmt, 2);
        CZKVItem *item = [CZKVItem new];
        item.key = key ? [NSString stringWithUTF8String:key] : nil;
        item.filename = filename ? [NSString stringWithUTF8String:filename] : nil;
        item.size = size;
        [items addObject:item];
        result = sqlite3_step(stmt);
    }
    
    if (result != SQLITE_DONE) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        items = nil;
    }
    
    return items ? [items copy] : nil;
}

- (BOOL)dbDeleteItemWithKey:(NSString *)key
{
    NSString *sqlStr = @"delete from KeyValues where key = ?;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return NO;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database delete error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return NO;
    }
    return YES;
}

- (BOOL)dbDeleteItemsWithExpireDateEarlierThan:(NSInteger)date
{
    NSString *sqlStr = @"delete from KeyValues where expire_date < ? and expire_date > 0;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return NO;
    sqlite3_bind_int64(stmt, 1, date);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database delete error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return NO;
    }
    return YES;
}

- (NSInteger)dbGetTotalItemSize
{
    NSString *sqlStr = @"select sum(size) from KeyValues;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return -1;
    
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        return sqlite3_column_int(stmt, 0);
    } else {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return -1;
    }
}

- (NSInteger)dbGetTotalItemCount
{
    NSString *sqlStr = @"select count(*) from KeyValues;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return -1;
    
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        return sqlite3_column_int(stmt, 0);
    } else {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return -1;
    }
}

@end
