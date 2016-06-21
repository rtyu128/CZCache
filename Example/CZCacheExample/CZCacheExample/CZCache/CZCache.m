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

- (instancetype)initWithName:(NSString *)name
{
    if (0 == name.length) return nil;
    NSString *path = [[CZFileSupport documentDirectory] stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path
{
    if (0 == path.length) return nil;
    if (self = [super init]) {
        CZDiskCache *diskCache = [[CZDiskCache alloc] initWithPath:path];
        if (!diskCache) return nil;
        NSString *name = [path lastPathComponent];
        CZMemoryCache *memoryCache = [[CZMemoryCache alloc] initWithName:name];
        
        _name = name;
        _diskCache = diskCache;
        _memoryCache = memoryCache;
    }
    return self;
}

- (BOOL)containsObjectForKey:(NSString *)key
{
    return [_memoryCache containsObjectForKey:key] || [_diskCache containsObjectForKey:key];
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
