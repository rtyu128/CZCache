//
//  CZCache.m
//  CZCache
//
//  Created by Anchor on 16/6/15.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZCache.h"
#import "CZFileSupport.h"

@implementation CZCache

- (instancetype)initWithName:(NSString *)name directory:(NSString *)directory
{
    if (0 == name.length) return nil;
    NSString *fileDirectory = 0 == directory.length ? [CZFileSupport cachesDirectory] : directory;
    if (self = [super init]) {
        _name = name;
        _diskCache = [[CZDiskCache alloc] initWithDirectory:[fileDirectory stringByAppendingPathComponent:name]];
        if (!_diskCache) return nil;
        _memoryCache = [[CZMemoryCache alloc] initWithName:name];
    }
    return self;
}

- (id<NSCoding>)objectForKey:(NSString *)key
{
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (!object) {
        object = [_diskCache objectForKey:key];
        if (object) [_memoryCache setObject:object forKey:key];
    }
    return object;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}

- (void)removeAllOnjects
{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}

@end
