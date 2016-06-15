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


static NSString *const kValueFileDirectoryName = @"value";
static NSString *const kValueFileTrashDirectoryName = @"value_trash";

@implementation CZKVStore {
    CZKVDataBase *db;
    
    NSString *valueFileDirectory;
    NSString *valueFileTrashDirectory;
    
    dispatch_queue_t trashQueue;
}

- (instancetype)initWithPath:(NSString *)path
{
    if (0 == path.length) {
        return nil;
    }

    if (self = [super init]) {
        valueFileDirectory = [path stringByAppendingPathComponent:kValueFileDirectoryName];
        valueFileTrashDirectory = [path stringByAppendingPathComponent:kValueFileTrashDirectoryName];
        
        trashQueue = dispatch_queue_create("com.netease.disk.trash", DISPATCH_QUEUE_SERIAL);
        
        // 暂未处理目录创建失败
        [[NSFileManager defaultManager] createDirectoryAtPath:valueFileDirectory
                                  withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:valueFileTrashDirectory
                                  withIntermediateDirectories:YES attributes:nil error:nil];
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
    CFRelease(uuid);// 这个应该不用释放
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

- (BOOL)saveItem:(CZKVItem *)item
{
    return [self saveItemWithKey:item.key value:item.value filename:item.filename];
}

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value
{
    return [self saveItemWithKey:key value:value filename:nil];
}

- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value filename:(NSString *)filename
{
    if (0 == key.length || 0 == value.length) return NO;
    
    if (filename.length > 0) {
        if ([self cacheWriteData:value toFile:filename]) {
            if ([db dbSaveItemWithKey:key value:value filename:filename]) {
                return YES;
            } else {
                [self cacheDeleteFile:filename];
            }
        }
        return NO;
    } else {
        return [db dbSaveItemWithKey:key value:value filename:filename];
    }
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

- (CZKVItem *)getItemForKey:(NSString *)key
{
    if (0 == key.length) return nil;
    CZKVItem *item = [db dbGetItemForKey:key];
    if (item) {
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

- (NSData *)getItemValueForKey:(NSString *)key
{
    if (0 == key.length) return nil;
    NSData *value = nil;
    NSString *filename = [db dbGetFilenameWithKey:key];
    if (filename.length > 0) {
        value = [self cacheDataFromFile:filename];
        if (!value) {
            [db dbDeleteItemWithKey:key];
            value = nil;
        }
    } else {
        value = [db dbGetValueForKey:key];
    }
    return value;
}

- (BOOL)containsItemForKey:(NSString *)key
{
    return key.length > 0 ? [db dbGetItemCountForKey:key] > 0 : NO;
}

- (int)totalItemsCount
{
    return [db dbGetTotalItemCount];
}

- (int)totalItemsSize
{
    return [db dbGetTotalItemSize];
}

@end
