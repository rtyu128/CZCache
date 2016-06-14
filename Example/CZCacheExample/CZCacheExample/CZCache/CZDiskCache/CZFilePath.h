//
//  CZFilePath.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CZFilePath : NSObject

+ (NSString *)homeDirectory;

/* homeDirectory/Documents */
+ (NSString *)documentDirectory;

/* homeDirectory/Library */
+ (NSString *)libraryDirectory;

/* homeDirectory/Library/Caches */
+ (NSString *)cachesDirectory;

/* homeDirectory/tmp/ */
+ (NSString *)temporaryDirectory;

+ (NSString *)documentPathWithFilename:(NSString *)filename;

@end
