//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STAppDelegate.h"

#import "STWebPViewController.h"


@implementation STAppDelegate

- (void)setWindow:(UIWindow *)window {
	_window = window;
	[_window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.backgroundColor = [UIColor blackColor];

	STWebPViewController *viewController = [STWebPViewController viewController];
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
	window.rootViewController = navController;

	self.window = window;

    return YES;
}

@end
