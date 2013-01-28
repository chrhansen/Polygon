//
//  AppDelegate.m
//  Polygon
//
//  Created by Christian Hansen on 14/12/12.
//  Copyright (c) 2012 Calcul8.it. All rights reserved.
//

#import "PGAppDelegate.h"
#import <DropboxSDK/DropboxSDK.h>

#import "MSNavigationPaneViewController.h"
#import "PGMasterViewController.h"

@implementation PGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"f146de881ca21798ccf25e64e544d6a0_MTAyNjExMjAxMi0wNi0yNyAwNDozNTozNC4wOTMwNTk"];
    DBSession.sharedSession = [DBSession.alloc initWithAppKey:@"zys929yd5i93w1u"
                                                    appSecret:@"46uevc5lcz77wat"
                                                         root:kDBRootDropbox];
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"Polygon.sqlite"];
    
    
    self.navigationPaneViewController = (MSNavigationPaneViewController *)self.window.rootViewController;
    
    PGMasterViewController *masterViewController = (PGMasterViewController *)[self.navigationPaneViewController.storyboard instantiateViewControllerWithIdentifier:@"masterViewController"];
    masterViewController.navigationPaneViewController = self.navigationPaneViewController;
    
    self.navigationPaneViewController.masterViewController = masterViewController;
    
    [masterViewController transitionToViewController:PGPaneViewControllerTypeModels];
    
    
    
    
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
//    // E-mail import URL's
//    if (url != nil && [url isFileURL]) {
//        NSDictionary *fileDic = [NSDictionary dictionaryWithObject:[url path] forKey:@"filePath"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:FileOpenFromEmailNotification object:nil userInfo:fileDic];
//        NSString *hudMessage = [NSString stringWithFormat:@"\"%@\" added", [[url path] lastPathComponent]];
//        [self showProgressHUDWithText:hudMessage
//                      detailLabelText:nil];
//    }
    
    // Dropbox access URL's
    if ([url.absoluteString hasPrefix:@"db-"]
        && [[DBSession sharedSession] handleOpenURL:url])
    {
        if ([[DBSession sharedSession] isLinked])
        {
            [NSNotificationCenter.defaultCenter postNotificationName:DropboxLinkStateChangedNotification object:nil];
            NSLog(@"App linked successfully!");
        }
        return YES;
    }
    
    // Add whatever other url handling code your app requires here
    return NO;
}

@end
