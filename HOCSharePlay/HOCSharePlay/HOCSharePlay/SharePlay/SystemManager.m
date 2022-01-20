//
//  SystemManager.m
//  MDMotionOrientation
//
//  Created by huangqun on 2021/11/11.
//

#import "SystemManager.h"
#import "SceneDelegate.h"
#import "SubViewController.h"

@implementation SystemManager

+ (void)jumpToViewWihtUrl:(NSString *)url controller:(UIViewController *_Nullable)controller {
    NSLog(@"页面路由  %@", url);
    dispatch_async(dispatch_get_main_queue(), ^{
        SubViewController *vc = [SubViewController new];
        UIWindowScene *scene = [UIApplication sharedApplication].openSessions.allObjects.lastObject.scene;
        [((SceneDelegate *)scene.delegate).window.rootViewController presentViewController:vc animated:YES completion:nil];
    });
}

@end
