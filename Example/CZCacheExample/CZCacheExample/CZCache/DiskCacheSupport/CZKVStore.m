//
//  CZKVStore.m
//  CZCache
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZKVStore.h"

static NSString *const kValueFileDirectoryName = @"value";
static NSString *const kValueFileTrashDirectoryName = @"value_trash";

@implementation CZKVStore {
    NSString *valueFileDirectory;
    NSString *valueFileTrashDirectory;
    
    dispatch_queue_t trashQueue;
}

- (instancetype)initWithPath:(NSString *)path
{
    if (path.length == 0) {
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




@end
