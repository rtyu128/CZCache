//
//  CZKeyValueItem.h
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CZKeyValueItem : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSData *value;
@property (nonatomic, strong, nullable) NSString *filename;

@property (nonatomic, assign) int size;
@property (nonatomic, assign) int lastModifiedTime;

@end

NS_ASSUME_NONNULL_END