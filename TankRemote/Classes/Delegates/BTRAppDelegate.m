//
//  BTRAppDelegate.m
//  TankRemote
//
//  Created by Taylan Pince on 2013-10-14.
//  Copyright (c) 2013 Hipo. All rights reserved.
//

#import "BTRAppDelegate.h"
#import "BTRRootViewController.h"


@interface BTRAppDelegate ()

@end


@implementation BTRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BTRRootViewController *controller = [[BTRRootViewController alloc] init];
    UIWindow *mainWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [mainWindow setBackgroundColor:[UIColor whiteColor]];
    [mainWindow setRootViewController:controller];
    
    [self setWindow:mainWindow];
    
    [mainWindow makeKeyAndVisible];
    
    [application setStatusBarHidden:YES];

    return YES;
}

@end
