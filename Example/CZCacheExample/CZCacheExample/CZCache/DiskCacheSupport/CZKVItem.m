//
//  CZKVItem.m
//  CZCache
//
//  Created by Anchor on 16/6/13.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CZKVItem.h"

@implementation CZKVItem

- (BOOL)isValid
{
    if (self.expireDate <= 0) return YES;
    return (time(NULL) <= self.expireDate);
}

- (NSTimeInterval)remainLife
{
    if (self.expireDate <= 0) {
        return 0;
    } else {
        NSTimeInterval remainTime = self.expireDate - time(NULL);
        return remainTime > 0 ? remainTime : -1;
    }
}

@end
