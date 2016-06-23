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
    if (0 == self.expireDate) return YES;
    return (time(NULL) <= self.expireDate);
}

@end
