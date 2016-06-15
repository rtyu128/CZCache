//
//  CZFilePath.m
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZFilePath.h"

@implementation CZFilePath

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


@end
