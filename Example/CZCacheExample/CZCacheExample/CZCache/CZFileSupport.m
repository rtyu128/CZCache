//
//  CZFileSupport.m
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZFileSupport.h"

@implementation CZFileSupport

+ (NSString *)homeDirectory
{
    return NSHomeDirectory();
}

+ (NSString *)documentDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
}

+ (NSString *)libraryDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
}

+ (NSString *)cachesDirectory
{
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

+ (NSString *)temporaryDirectory
{
    return NSTemporaryDirectory();
}

+ (NSString *)documentPathWithFilename:(NSString *)filename
{
    if (filename.length > 0) {
        return [[self documentDirectory] stringByAppendingPathComponent:filename];
    } else {
        return nil;
    }
}

+ (float)fileSizeWithDirectory:(NSString *)directory
{
    if (!directory) return 0.0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *subpaths = [fileManager subpathsAtPath:directory];
    
    unsigned long long totalSize = 0;
    NSString *fullPath = nil;
    BOOL isDirectory = NO, isExist = YES;
    for (NSString *subpath in subpaths) {
        fullPath = [directory stringByAppendingPathComponent:subpath];
        isDirectory = NO;
        isExist = [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        
        if (isExist && !isDirectory && ![fullPath containsString:@".DS"]) {
            NSDictionary *dict = [fileManager attributesOfItemAtPath:fullPath error:nil];
            totalSize += dict.fileSize;
        }
    }
    return totalSize / 1024.0 / 1024.0;
}

+ (BOOL)cleanFilesInDirectory:(NSString *)directory
{
    if (!directory) return NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:directory error:nil];
    
    BOOL result = YES;
    NSError *error = nil;
    NSString *fullPath = nil;
    
    for (NSString *subpath in contents) {
        fullPath = [directory stringByAppendingPathComponent:subpath];
        [fileManager removeItemAtPath:fullPath error:&error];
        if (error) result = NO;
    }
    return result;
}


@end
