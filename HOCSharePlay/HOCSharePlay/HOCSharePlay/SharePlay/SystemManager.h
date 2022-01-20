//
//  SystemManager.h
//  MDMotionOrientation
//
//  Created by huangqun on 2021/11/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SystemManager : NSObject

+ (void)jumpToViewWihtUrl:(NSString *)url controller:(UIViewController * _Nullable)controller;

@end

NS_ASSUME_NONNULL_END
