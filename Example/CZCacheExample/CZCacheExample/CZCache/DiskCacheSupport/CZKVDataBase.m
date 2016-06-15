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
static NSString *const kDataBaseDirectory = @"CZCaches/DataBase";
static NSString *const kDataBaseName = @"cacheDataBase.sqlite";
static NSString *const kDataBaseShmFileName = @"cacheDataBase.sqlite-shm";
static NSString *const kDataBaseWalFileName = @"cacheDataBase.sqlite-wal";


@implementation CZKVDataBase {
    NSString *storePath;
    NSString *storeDirectory;
    
    sqlite3 *dataBase;
    CFMutableDictionaryRef dbStmtCache;
    NSTimeInterval dbLastOpenErrorTime;
    NSUInteger dbOpenErrorCount;
}

- (instancetype)initWithDirectory:(NSString *)directory
{
    if (0 == directory.length) {
        NSLog(@"CZKVDataBase init error: invalid directory (nil).");
        return nil;
    }
    
    if (self = [super init]) {
        storeDirectory = [directory stringByAppendingPathComponent:kDataBaseDirectory];
        [[NSFileManager defaultManager] createDirectoryAtPath:storeDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        storePath = [storeDirectory stringByAppendingPathComponent:kDataBaseName];
        _errorLogsSwitch = YES;
        dbOpenErrorCount = 0;
        dbLastOpenErrorTime = 0;
        
        //warning 先不考虑文件损坏数据库打开失败的情况
        [self dbOpen];
        [self dbInitialize];
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
    [[NSFileManager defaultManager] removeItemAtPath:storePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[storeDirectory stringByAppendingPathComponent:kDataBaseShmFileName]
                                               error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[storeDirectory stringByAppendingPathComponent:kDataBaseWalFileName]
                                               error:nil];
    
    if ([self dbOpen] && [self dbInitialize]){
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)dbOpen
{
    if (dataBase) return YES;
    
    int result = sqlite3_open(storePath.UTF8String, &dataBase);
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
    BOOL stmtFinalized = NO;
    
    do {
        retry = NO;
        result = sqlite3_close(dataBase);
        if (result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            if (!stmtFinalized) {
                sqlite3_stmt *stmt;
                while ((stmt = sqlite3_next_stmt(dataBase, nil)) != 0) {
                    sqlite3_finalize(stmt);
                    retry = YES;
                }
                stmtFinalized = YES;
            }
        } else if (result != SQLITE_OK) {
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
    NSString *initSql = @"pragma journal_mode = wal; pragma synchronous = normal; create table if not exists KVTable (key text, value_data blob, filename text, size integer, last_modified_time, primary key(key));";
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
                NSLog(@"%s line %d: sqlite stmt prepare error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
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
    NSString *sqlStr = @"insert or replace into KVTable (key, value_data, filename, size, last_modified_time) values (?1, ?2, ?3, ?4, ?5);";
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
    
    int timeStamp = (int)time(NULL);
    sqlite3_bind_int(stmt, 5, timeStamp);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database instert/replace error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return NO;
    }
    return YES;
}

- (BOOL)dbDeleteItemWithKey:(NSString *)key
{
    NSString *sqlStr = @"delete from KVTable where key = ?;";
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

- (CZKVItem *)dbGetItemForKey:(NSString *)key
{
    NSString *sqlStr = @"select key, value_data, filename, size, last_modified_time from KVTable where key = ?;";
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
    int lastModifiedTime = sqlite3_column_int(stmt, i++);
    
    CZKVItem *item = [[CZKVItem alloc] init];
    if (key) item.key = [NSString stringWithUTF8String:key];
    if (valueData && valueDataSize > 0) item.value = [NSData dataWithBytes:valueData length:valueDataSize];
    if (filename && *filename != 0) item.filename = [NSString stringWithUTF8String:filename];
    item.size = size;
    item.lastModifiedTime = lastModifiedTime;
    return item;
}

- (NSData *)dbGetValueForKey:(NSString *)key
{
    NSString *sqlStr = @"select value_data from KVTable where key = ?;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return nil;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);

    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        const void *valueData = sqlite3_column_blob(stmt, 0);
        int valueDataSize = sqlite3_column_bytes(stmt, 0);
        return (valueData && valueDataSize > 0) ? [NSData dataWithBytes:valueData length:valueDataSize] : nil;
    } else {
        if (result != SQLITE_DONE)
            NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return nil;
    }
}

- (NSString *)dbGetFilenameWithKey:(NSString *)key
{
    NSString *sqlStr = @"select filename form KVTable where key = ?;";
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

- (int)dbGetItemCountForKey:(NSString *)key
{
    NSString *sqlStr = @"select count(key) from KVTable where key = ?;";
    sqlite3_stmt *stmt = [self dbPrepareStmt:sqlStr];
    if (!stmt) return -1;
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW) {
        if (_errorLogsSwitch)
            NSLog(@"%s line %d: database query error (%d): %s", __func__, __LINE__, result, sqlite3_errmsg(dataBase));
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

- (int)dbGetTotalItemSize
{
    NSString *sqlStr = @"select sum(size) from KVTable;";
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

- (int)dbGetTotalItemCount
{
    NSString *sqlStr = @"select count(*) from KVTable;";
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
