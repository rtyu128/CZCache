//
//  CacheBenchmark.m
//  CZCacheExample
//
//  Created by Anchor on 16/7/5.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "CacheBenchmark.h"
#import <QuartzCore/QuartzCore.h>
#import <Security/Security.h>


@implementation CacheBenchmark

+ (void)benchmarkSetup
{
//    @autoreleasepool {
//        [self UserDefaultsWriteSmallData];
//    }
    
    @autoreleasepool {
        [self UserDefaultsReadSmallData];
    }
    
    NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
    SecItemAdd((CFDictionaryRef)keychainQuery, NULL);
    SecItemDelete((CFDictionaryRef)keychainQuery);
    
    
    
}

+ (void)UserDefaultsWriteSmallData
{
    // [NSUserDefaults resetStandardUserDefaults]; // 这句没效果
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    NSUserDefaults *standard = [NSUserDefaults standardUserDefaults];
    
    NSInteger count = 1000, step = 100;
    NSMutableArray *keys = [NSMutableArray new];
    NSMutableArray *values = [NSMutableArray new];
    for (NSInteger i = 0; i < count; i++) {
        NSString *key = @(i).description;
        NSNumber *value = @(i);
        [keys addObject:key];
        [values addObject:value];
    }
    
    NSTimeInterval begin, end, time;
    
    printf("\n------------------------------------------\n");
    printf("NSUserDefaults set 1000 key-value pairs (value is NSNumber)\n");
    
    printf("ZeroTime: %f\n", CACurrentMediaTime());
    @autoreleasepool {
        for (NSInteger i = 0; i < count/step; i++) {
            begin = CACurrentMediaTime();
            for (NSInteger j = i*step; j < (i+1)*step; j++) {
                [standard setObject:values[j] forKey:keys[j]];
            }
            [standard synchronize];
            end = CACurrentMediaTime();
            time = end - begin;
            printf("NSUserDefaults, %ld, time: %8.2fms\n", (long)i, time * 1000);
        }
    }
    printf("TerminalTime: %f\n", CACurrentMediaTime());
}

+ (void)UserDefaultsReadSmallData
{
    NSUserDefaults *standard = [NSUserDefaults standardUserDefaults];
    
    NSInteger count = 1000;
    NSMutableArray *keys = [NSMutableArray new];
    for (NSInteger i = 0; i < count; i++) {
        NSString *key = @(i).description;
        [keys addObject:key];
    }
    
    for (NSUInteger i = keys.count; i > 1; i--) {
        [keys exchangeObjectAtIndex:(i - 1) withObjectAtIndex:arc4random_uniform((u_int32_t)i)];
    }
    
    NSTimeInterval begin, end, time;
    
    printf("\n------------------------------------------\n");
    printf("NSUserDefaults read 1000 key-value pairs (value is NSNumber)\n");
    
    printf("ZeroTime: %f\n", CACurrentMediaTime());
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (NSInteger i = 0; i < count; i++) {
            NSNumber *value = [standard objectForKey:keys[i]];
            if (!value) printf("NSUserDefaults read error!\n");
        }
    }
    end = CACurrentMediaTime();
    time = end - begin;
    printf("NSUserDefaults: %8.2fms\n", time * 1000);
    printf("TerminalTime: %f\n", CACurrentMediaTime());
}

@end
