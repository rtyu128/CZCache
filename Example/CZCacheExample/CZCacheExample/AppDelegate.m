//
//  AppDelegate.m
//  CZCacheExample
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "AppDelegate.h"
#import "CZMemoryCache.h"
#import "CZDiskCache.h"
#import "CZFileSupport.h"
#import "CZKVDataBase.h"
#import "CZKVItem.h"
#import "CZCache.h"
#import "ViewController.h"
#import "CacheBenchmark.h"

@interface AppDelegate ()

@property (nonatomic, strong) CZKVDataBase *dataBase;
@property (nonatomic, strong) CZDiskCache *diskCache;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [[CZCache standardCache] setObject:@"Asshole" forKey:@"abc"];
    NSMutableData *dataValue = [NSMutableData new]; // 50KB
    for (int i = 0; i < 50 * 1024; i++) {
        [dataValue appendBytes:&i length:1];
    }
    [[CZCache standardCache] setObject:dataValue forKey:@"bigData"];

    
    
    ViewController *rootVC = [[ViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    
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
     /// CZFileSupport Test
     NSLog(@"%@", [CZFileSupport homeDirectory]);
     NSLog(@"%@", [CZFileSupport documentDirectory]);
     NSLog(@"%@", [CZFileSupport libraryDirectory]);
     NSLog(@"%@", [CZFileSupport cachesDirectory]);
     NSLog(@"%@", [CZFileSupport temporaryDirectory]);
     */
    
    
    /// CZKVDataBase Test
    NSLog(@"%@", [CZFileSupport documentDirectory]);
    //_dataBase = [[CZKVDataBase alloc] initWithDirectory:[CZFileSupport documentDirectory]];
    
    
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
    
    //    CZKVItem *zxmData = [_dataBase dbGetItemForKey:@"zxm"];
    //    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:zxmData.value];
    //    NSDictionary *zxmInfo = [unarchiver decodeObjectForKey:@"person"];

    /*
    float fileSize = [CZFileSupport fileSizeWithDirectory:[CZFileSupport cachesDirectory]];
    NSLog(@"%.3f MB", fileSize);
    [CZFileSupport cleanFilesInDirectory:[CZFileSupport cachesDirectory] completion:^(NSString *directory, BOOL result) {
        NSLog(@"\raaaa: %d", result);
    }];
    */
    
    NSDictionary *hosts = @{@"nickName" : @"Asshole", @"Company" : @"ABCD", @"age" : @88};
    _diskCache = [[CZDiskCache alloc] initWithDirectory:[[CZFileSupport documentDirectory] stringByAppendingPathComponent:@"userInfo"]
                                       dbStoreThreshold:500];
//    [_diskCache setObject:@"Asshole" forKey:@"nickName"];
//    [_diskCache setObject:@"ABCD" forKey:@"Company"];
    [_diskCache setObject:hosts forKey:@"Hosts"];
    
//    NSLog(@"%@", [_diskCache objectForKey:@"nickName"]);
//    NSLog(@"%@", [_diskCache objectForKey:@"Company"]);
    NSLog(@"%@", [_diskCache objectForKey:@"Hosts"]);
    
//    [_diskCache removeObjectForKey:@"nickName"];
//    [_diskCache removeObjectForKey:@"Company"];
    [_diskCache removeObjectForKey:@"Hosts"];
    
    //NSLog(@"%@", MD5String(@"DocumentCache"));
    //NSLog(@"%@", MD5String(@"CachesCache"));
    
    
//    NSUserDefaults *test = [[NSUserDefaults alloc] initWithSuiteName:@"zxm.netease.com"];
//    [test setObject:@1 forKey:@"key"];
    
//    CZCache *aaa = [CZCache standardCache];
//    aaa[@"Str"] = @"abc";
//    id<NSCoding> str = aaa[@"Str"];
//    NSLog(@"%@", str);
    
    
    //
    //[CacheBenchmark benchmarkSetup];
    
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
