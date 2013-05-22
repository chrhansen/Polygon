//
//  AppDelegate.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGAppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>
#import "PGStyleController.h"
#import "MSNavigationPaneViewController.h"
#import "PGMasterViewController.h"
#import "ATConnect.h"
#import "PGFirstLaunchTasks.h"
#import <Crashlytics/Crashlytics.h>

@implementation PGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DBSession.sharedSession = [DBSession.alloc initWithAppKey:@"zys929yd5i93w1u" appSecret:@"46uevc5lcz77wat" root:kDBRootDropbox];
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Polygon.sqlite"];
    
    ATConnect *connection = [ATConnect sharedConnection];
    connection.apiKey = kApptentiveAPIKey;
    
    MSNavigationPaneViewController *navigationPaneViewController = (MSNavigationPaneViewController *)self.window.rootViewController;
    PGMasterViewController *masterViewController = (PGMasterViewController *)[navigationPaneViewController.storyboard instantiateViewControllerWithIdentifier:@"masterViewController"];
    masterViewController.navigationPaneViewController = navigationPaneViewController;
    navigationPaneViewController.masterViewController = masterViewController;
    [masterViewController transitionToViewController:PGPaneViewControllerTypeModels];
    
    [PGStyleController applyAppearance];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL firstLaunch = ![userDefaults boolForKey:PGFirstLaunch];
    if (firstLaunch) {
        [userDefaults setBool:YES forKey:PGFirstLaunch];
        [userDefaults synchronize];
        [PGFirstLaunchTasks performFirstLaunchTasksWithCompletion:nil];
    }
    
    // Chrashlytics
    [Crashlytics startWithAPIKey:kCrashlyticsAPIKey];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    // E-mail import URL's
    if ([url isFileURL]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FileOpenFromEmailNotification object:nil userInfo:@{@"fileURL": url}];
        return YES;
    }
    
    // Dropbox access URL's
    if ([url.absoluteString hasPrefix:@"db-"]
        && [[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxLinkStateChangedNotification object:nil];
        }
        return YES;
    }
    
    // Add whatever other url handling code your app requires here
    return NO;
}

@end
