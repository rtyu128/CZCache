//
//  CZKVStore.m
//  CZCache
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZKVStore.h"
#import "CZKVItem.h"
#import "CZKVDataBase.h"

static NSString *const kDataBaseDirectoryName = @"database";
static NSString *const kValueFileDirectoryName = @"value";
static NSString *const kValueFileTrashDirectoryName = @"asshole";

@implementation CZKVStore {
    CZKVDataBase *db;
    
    NSString *databaseDirectory;
    NSString *valueFileDirectory;
    NSString *valueFileTrashDirectory;
    
    dispatch_queue_t trashQueue;
}

- (instancetype)initWithDirectory:(NSString *)directory
{
    if (self = [super init]) {
        databaseDirectory = [directory stringByAppendingPathComponent:kDataBaseDirectoryName];
        valueFileDirectory = [directory stringByAppendingPathComponent:kValueFileDirectoryName];
        valueFileTrashDirectory = [directory stringByAppendingPathComponent:kValueFileTrashDirectoryName];
        
        trashQueue = dispatch_queue_create("com.netease.disk.trash", DISPATCH_QUEUE_SERIAL);
        
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:databaseDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error] ||
            ![[NSFileManager defaultManager] createDirectoryAtPath:valueFileDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error] ||
            ![[NSFileManager defaultManager] createDirectoryAtPath:valueFileTrashDirectory
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error]) {
                NSLog(@"CZKVStore directory create error:%@", error);
                return nil;
        }
        
        db = [[CZKVDataBase alloc] initWithDirectory:databaseDirectory];
        if (!db) {
            if ([self cacheMoveAllFileToTrash]) [self cacheEmptyTrashAsync];
        }
    }
    return self;
}


#pragma mark - File Support

- (BOOL)cacheWriteData:(NSData *)data toFile:(NSString *)filename
{
    NSString *path = [valueFileDirectory stringByAppendingPathComponent:filename];
    return [data writeToFile:path atomically:NO];
}

- (NSData *)cacheDataFromFile:(NSString *)filename
{
    NSString *path = [valueFileDirectory stringByAppendingPathComponent:filename];
    return [NSData dataWithContentsOfFile:path];
}

- (BOOL)cacheDeleteFile:(NSString *)filename
{
    NSString *path = [valueFileDirectory stringByAppendingPathComponent:filename];
    return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (BOOL)cacheMoveAllFileToTrash
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuid = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    
    NSString *tmpPath = [valueFileTrashDirectory stringByAppendingPathComponent:(__bridge NSString *)uuid];
    BOOL result = [[NSFileManager defaultManager] moveItemAtPath:valueFileDirectory toPath:tmpPath error:nil];
    if (result)
        result = [[NSFileManager defaultManager] createDirectoryAtPath:valueFileDirectory
                                           withIntermediateDirectories:YES attributes:nil error:nil];
    CFRelease(uuid); // 这个应该不用释放
    return result;
}

- (void)cacheEmptyTrashAsync
{
    NSString *trashPath = valueFileTrashDirectory;
    dispatch_async(trashQueue, ^{
        NSFileManager *manager = [[NSFileManager alloc] init];
        NSArray *contents = [manager contentsOfDirectoryAtPath:trashPath error:nil];
        for (NSString *filename in contents) {
            NSString *path = [trashPath stringByAppendingPathComponent:filename];
            [manager removeItemAtPath:path error:nil];
        }
    });
}


#pragma mark Public

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value
{
    return [self saveItemWithKey:key value:value filename:nil lifetime:CZ_LIVE_FOREVER extendedData:nil];
}

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename
{
    return [self saveItemWithKey:key value:value filename:filename lifetime:CZ_LIVE_FOREVER extendedData:nil];
}

- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(NSString *)filename
               lifetime:(NSTimeInterval)lifetime
           extendedData:(NSData *)extendedData
{
    if (0 == key.length || 0 == value.length) return NO;
    
    if (filename.length > 0) {
        if ([self cacheWriteData:value toFile:filename]) {
            if ([db dbSaveItemWithKey:key value:value filename:filename lifetime:lifetime extendedData:extendedData]) {
                return YES;
            } else {
                [self cacheDeleteFile:filename];
            }
        }
        return NO;
    } else {
        return [db dbSaveItemWithKey:key value:value filename:filename lifetime:lifetime extendedData:extendedData];
    }
}

- (NSData *)getItemValueForKey:(NSString *)key
{
    return [self getItemForKey:key].value;
}

- (CZKVItem *)getItemForKey:(NSString *)key
{
    if (0 == key.length) return nil;
    CZKVItem *item = [db dbGetItemForKey:key];
    if (item) {
        if (![item isValid]) {
            if (item.filename.length > 0) {
                [self cacheDeleteFile:item.filename];
            }
            [db dbDeleteItemWithKey:key];
            item = nil;
        }
        
        if (item.filename.length > 0) {
            item.value = [self cacheDataFromFile:item.filename];
            if (!item.value) {
                [db dbDeleteItemWithKey:key];
                item = nil;
            }
        }
    }
    return item;
}

- (BOOL)removeItemForKey:(NSString *)key
{
    if (0 == key.length) return NO;
    NSString *filename = [db dbGetFilenameWithKey:key];
    if (filename.length > 0) {
        [self cacheDeleteFile:filename];
    }
    return [db dbDeleteItemWithKey:key];
}

- (BOOL)removeItemsWithSizeLimit:(NSInteger)size
{
    if (NSIntegerMax == size) return YES;
    if (size <= 0) return [self removeAllItems];

    NSInteger total = [db dbGetTotalItemSize];
    if (total < 0) return NO;
    if (total <= size) return YES;
    
    int rowNum = 20;
    BOOL success = YES;
    NSArray<CZKVItem *> *items = [db dbGetItemsOrderByExpireDateAscWithLimit:rowNum];
    while (total > size && items.count > 0 && success) {
        for (CZKVItem *item in items) {
            if (total > size) {
                if (item.filename) {
                    [self cacheDeleteFile:item.filename];
                }
                success = [db dbDeleteItemWithKey:item.key];
                total -= item.size;
            } else {
                break;
            }
            if (!success) break;
        }
        items = [db dbGetItemsOrderByExpireDateAscWithLimit:rowNum];
    }
    if (success) [db dbCheckpoint];
    return success;
}

- (BOOL)removeItemsWithCountLimit:(NSInteger)count
{
    if (NSIntegerMax == count) return YES;
    if (count <= 0) return [self removeAllItems];
    
    NSInteger total = [db dbGetTotalItemCount];
    if (total < 0) return NO;
    if (total <= count) return YES;
    
    int rowNum = 20;
    BOOL success = YES;
    NSArray<CZKVItem *> *items = [db dbGetItemsOrderByExpireDateAscWithLimit:rowNum];
    while (total > count && items.count > 0 && success) {
        for (CZKVItem *item in items) {
            if (total > count) {
                if (item.filename) {
                    [self cacheDeleteFile:item.filename];
                }
                success = [db dbDeleteItemWithKey:item.key];
                total --;
            } else {
                break;
            }
            if (!success) break;
        }
        items = [db dbGetItemsOrderByExpireDateAscWithLimit:rowNum];
    }
    if (success) [db dbCheckpoint];
    return success;
}

- (BOOL)removeItemsEarlierThanDate:(NSInteger)date
{
    if (date <= 0) return YES;
    if (NSIntegerMax == date) return [self removeAllItems];
    
    NSArray<NSString *> *filenames = [db dbGetFilenamesWithExpireDateEarlierThan:date];
    for (NSString *name in filenames) {
        [self cacheDeleteFile:name];
    }
    
    if ([db dbDeleteItemsWithExpireDateEarlierThan:date]) {
        [db dbCheckpoint];
        return YES;
    }
    return NO;
}

- (BOOL)removeAllItems
{
    if ([db dbReset]) {
        if ([self cacheMoveAllFileToTrash]) {
            [self cacheEmptyTrashAsync];
            return YES;
        }
    }
    return NO;
}

- (NSInteger)totalItemsSize
{
    return [db dbGetTotalItemSize];
}

- (NSInteger)totalItemsCount
{
    return [db dbGetTotalItemCount];
}

@end
