//
//  ViewController.m
//  HOCSharePlay
//
//  Created by huangqun on 2021/11/11.
//

#import "ViewController.h"
#import "SystemManager.h"
#import "HOCSharePlay-Swift.h"

@interface ViewController ()
@property (nonatomic, strong) NSString *uuid;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    // 检索FaceTime会话(程序启动时需要调用，避免通过同播共享链接进入时无法正常加入会话)
    if (@available(iOS 15, *)) {
        [MDSharePlayMananger.shared startSession];
    } else {
        // Fallback on earlier versions
    }
    
    UIButton *sharePlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [sharePlayButton setTitle:@"startShare" forState:UIControlStateNormal];
    [sharePlayButton addTarget:self action:@selector(sharePlayButtonAction) forControlEvents:UIControlEventTouchUpInside];
    sharePlayButton.frame = CGRectMake(150, 150, 100, 40);
    [self.view addSubview:sharePlayButton];
    
    
    UIButton *sendMessageButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [sendMessageButton setTitle:@"sendMessage" forState:UIControlStateNormal];
    [sendMessageButton addTarget:self action:@selector(sendMessageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    sendMessageButton.frame = CGRectMake(150, 250, 100, 40);
    [self.view addSubview:sendMessageButton];
}

- (void)sharePlayButtonAction {
    if (@available(iOS 15, *)) {
        NSInteger random = arc4random() % 100;
        NSString *url = [NSString stringWithFormat:@"md://postPage?id=%@", @(random)];
        MDOCMessageModel *message = [MDOCMessageModel new];
        message.url = url;
        message.title = @"XXX详情页";
        message.type = MDOCActivityTypeSendActivity;
        NSLog(@"将要发送一个消息： %@   %@", message.url, message.uuid);
        MDSharePlayMananger.shared.messageCallBack = ^(NSString * _Nonnull text) {
            NSLog(@"Swift交消息回调");
            if (self.uuid && [self.uuid isEqualToString:text]) {
//                [SystemManager];
            }
        };
        [MDSharePlayMananger.shared prepareToPlay:message];
    } else {
        // Fallback on earlier versions
    }
}

- (void)sendMessageButtonAction {
    if (@available(iOS 15, *)) {
        MDOCMessageModel *message = [MDOCMessageModel new];
        message.url = @"www.com";
        message.title = @"一个详情页";
        message.type = MDOCActivityTypeSendMessage;
        NSLog(@"将要发送一个消息： %@   %@", message.url, message.uuid);
        [MDSharePlayMananger.shared sendMessage:message];
    } else {
        // Fallback on earlier versions
    }
}


@end
