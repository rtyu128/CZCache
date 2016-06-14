//
//  AppDelegate.m
//  CZCacheExample
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "AppDelegate.h"
#import "CZMemoryCache.h"
#import "CZFilePath.h"
#import "CZKVDataBase.h"
#import "CZKeyValueItem.h"

@interface AppDelegate ()

@property (nonatomic, strong) CZKVDataBase *dataBase;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    /**
     /// CZMemoryCache Test
     CZMemoryCache *cache = [[CZMemoryCache alloc] initWithName:@"TestCache"];
     [cache setObject:@"abcdefg" forKey:@"string"];
     NSString *str = [cache objectForKey:@"string"];
     NSLog(@"%@", str);
     BOOL test = [cache containsObjectForKey:@"string"];
     if (test) {
     [cache removeAllObjects];
     }
     
     
     NSDictionary *dict = @{@"A" : @1, @"B" : @"fgh"};
     [cache setObject:@123 forKey:@"num"];
     [cache setObject:dict forKey:@"dict"];
     
     NSDictionary *diction = [cache objectForKey:@"dict"];
     NSInteger ASD = [[cache objectForKey:@"num"] integerValue];
     NSInteger numbe = cache.totalCount;
     [cache removeObjectForKey:@"num"];
     numbe = cache.totalCount;
     */
    
    CFTimeInterval time = CACurrentMediaTime();
    NSLog(@"%f", time);
    
    /**
     /// CZFilePath Test
     NSLog(@"%@", [CZFilePath homeDirectory]);
     NSLog(@"%@", [CZFilePath documentDirectory]);
     NSLog(@"%@", [CZFilePath libraryDirectory]);
     NSLog(@"%@", [CZFilePath cachesDirectory]);
     NSLog(@"%@", [CZFilePath temporaryDirectory]);
     */
    
    
    /// CZKVDataBase Test
    NSLog(@"%@", [CZFilePath documentDirectory]);
    _dataBase = [[CZKVDataBase alloc] initWithDirectory:[CZFilePath documentDirectory]];
    
    
    //NSData *data = [NSData data];
    //[_dataBase dbSaveItemWithKey:@"test" value:data filename:nil];
    
    /*
     NSDictionary *dict = @{@"name" : @"张旭明", @"age" : @24};
     NSMutableData *archiverData = [NSMutableData data];
     NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiverData];
     [archiver encodeObject:dict forKey:@"person"];
     [archiver finishEncoding];
     
     [_dataBase dbSaveItemWithKey:@"zxm" value:archiverData filename:nil];
     */
    
    //[_dataBase dbDeleteItemWithKey:@"test"];
    
    //    CZKeyValueItem *zxmData = [_dataBase dbGetItemForKey:@"zxm"];
    //    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:zxmData.value];
    //    NSDictionary *zxmInfo = [unarchiver decodeObjectForKey:@"person"];
    
    
    

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
