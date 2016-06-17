//
//  CZDiskCache.m
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZDiskCache.h"
#import "CZKVItem.h"
#import "CZKVStore.h"
#import <CommonCrypto/CommonCrypto.h>

static NSString *MD5String (NSString *string) {
    if (!string) return nil;
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]];
}

@implementation CZDiskCache {
    CZKVStore *kvStore;
    dispatch_semaphore_t lockSignal;
    
}

- (instancetype)initWithPath:(NSString *)path
{
    return [self initWithPath:path dbStoreThreshold:16 * 1024];
}

- (instancetype)initWithPath:(NSString *)path dbStoreThreshold:(NSUInteger)threshold
{
    if (self = [super init]) {
        kvStore = [[CZKVStore alloc] initWithPath:path];
        if (!kvStore) return nil;
        
        _path = path;
        lockSignal = dispatch_semaphore_create(1);
        _dbStoreThreshold = threshold;
        _countLimit = NSUIntegerMax;
        _sizeLimit = NSUIntegerMax;
    }
    return self;
}

- (void)lock
{
    dispatch_semaphore_wait(lockSignal, DISPATCH_TIME_FOREVER);
}

- (void)unlock
{
    dispatch_semaphore_signal(lockSignal);
}

- (nullable id<NSCoding>)objectForKey:(NSString *)key
{
    if (!key) return nil;
    [self lock];
    CZKVItem *item = [kvStore getItemForKey:key];
    [self unlock];
    if (!item.value) return nil;
    
    id object = nil;
    object = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
    return object;
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key
{
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    
    NSData *valueData = [NSKeyedArchiver archivedDataWithRootObject:object];
    if (!valueData) return;
    
    NSString *filename = nil;
    if (valueData.length > _dbStoreThreshold){
        filename = [self filenameForKey:key];
    }
    
    [self lock];
    [kvStore saveItemWithKey:key value:valueData filename:filename];
    [self unlock];
}

- (BOOL)containsObjectForKey:(NSString *)key
{
    if (!key) return NO;
    [self lock];
    BOOL result = [kvStore containsItemForKey:key];
    [self unlock];
    return result;
}

- (void)removeObjectForKey:(NSString *)key
{
    if (!key) return;
    [self lock];
    [kvStore removeItemForKey:key];
    [self unlock];
}

- (void)removeAllObjects
{
    [self lock];
    [kvStore removeAllItems];
    [self unlock];
}

- (NSInteger)totalCount
{
    [self lock];
    int count = [kvStore totalItemsCount];
    [self unlock];
    return count;
}

- (NSInteger)totalSize
{
    [self lock];
    int size = [kvStore totalItemsSize];
    [self unlock];
    return size;
}

- (NSString *)filenameForKey:(NSString *)key
{
    return MD5String(key);
}


@end