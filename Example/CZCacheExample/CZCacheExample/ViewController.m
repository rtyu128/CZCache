//
//  ViewController.m
//  CZCacheExample
//
//  Created by Anchor on 16/6/14.
//  Copyright © 2016年 Anchor. All rights reserved.
//

#import "ViewController.h"
#import "CZFileSupport.h"
#import "CZCache.h"


@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor greenColor];
    
    NSLog(@"%@", [[CZCache standardCache] objectForKey:@"abc"]);
    //NSLog(@"%@", [[CZCache standardCache] objectForKey:@"bigData"]);
    NSLog(@"%@", [CZCache standardCache][@"number"]);
    NSLog(@"%@", [[CZCache standardCache] objectForKey:@"hosts"]);
    
    NSLog(@"%d, %lu, %lu", INT_MAX, NSUIntegerMax, NSIntegerMax);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
