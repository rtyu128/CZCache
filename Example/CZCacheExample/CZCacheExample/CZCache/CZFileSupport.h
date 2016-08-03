//
//  CZFileSupport.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface CZFileSupport : NSObject

#pragma mark - File Path

// Return home directory of sandbox.
+ (NSString *)homeDirectory;

// e.g. homeDirectory/Documents
+ (NSString *)documentDirectory;

// e.g. homeDirectory/Library
+ (NSString *)libraryDirectory;

// e.g. homeDirectory/Library/Caches
+ (NSString *)cachesDirectory;

// e.g. homeDirectory/tmp/
+ (NSString *)temporaryDirectory;

/**
 Return fullPath in document directory with filename, return nil if filename is nil.
 */
+ (nullable NSString *)documentPathWithFilename:(NSString *)filename;

#pragma mark - File Size & Clean

/**
 Calculate total size of files in specified directory. Reault is in MB.
 
 @param directory: the directory you want to get size.
 @return the total size of files in directory, if the directory is not exist, return 0.0.
 */
+ (CGFloat)fileSizeWithDirectory:(NSString *)directory;

/**
 Async clean(delete) all files in specified directory.
 If the directory is nil, the completion block will be execute immediately.
 
 @param directory: the directory you want to clean.
 @param completion: will be execute after clean operation complete.
 */
+ (void)cleanFilesInDirectory:(NSString *)directory completion:(void (^)(NSString *directory, BOOL result))completion;

@end

NS_ASSUME_NONNULL_END