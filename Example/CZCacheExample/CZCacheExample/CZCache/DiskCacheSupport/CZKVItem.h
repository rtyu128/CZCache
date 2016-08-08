//
//  CZKVItem.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CZCacheDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 CZKVItem is a kind of metadata used to store key-value pairs infos.
 */
@interface CZKVItem : NSObject

// The key of key-value pair.
@property (nonatomic, strong) NSString *key;

// The key's associated object value.
@property (nonatomic, strong) NSData *value;

// If needed, the value may be store as a file. This value represent the value's associated filename.
@property (nonatomic, strong, nullable) NSString *filename;

// The size of the value (in bytes).
@property (nonatomic, assign) int size;

// The expireDate of key-value pair. Equal to secends from 1970-01-01 8:00 to deadline(UTC).
@property (nonatomic, assign) long expireDate;

// The extended date of key-value pair(e.g.Description).
@property (nonatomic, strong, nullable) NSData *extendedData;

// Returns a boolean value indicates whether the key-value pair is valid.
- (BOOL)isValid;

// Calculates the remain lifetime of key-valus pair, if the key-value pair is invalid, just return -1.0. 
- (NSTimeInterval)remainLife;

@end

NS_ASSUME_NONNULL_END