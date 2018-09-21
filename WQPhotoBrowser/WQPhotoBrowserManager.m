//
//  WQPhotoBrowserManager.m
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import "WQPhotoBrowserManager.h"

static CGFloat const kDismissAnimationDuration = 0.3f;

static NSTimer *_userInteractionEnableTimer = nil;

@implementation WQPhotoBrowserManager

+ (instancetype)sharedManager {
    static WQPhotoBrowserManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WQPhotoBrowserManager alloc] init];
    });
    return manager;
}

- (void)presentWindowWithController:(UIViewController *)controller {
    [[self class] disableUserInteractionDuration:kDismissAnimationDuration];
    UIWindow *photoWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _photoWindow = photoWindow;
    _photoWindow.windowLevel = UIWindowLevelStatusBar + 0.1;
    _photoWindow.rootViewController = controller;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.photoWindow setHidden:NO];
    });
}

- (void)dismissWindow:(BOOL)animation {
    if (!animation) {
        [self _dismissWindow];
        return;
    }
    
    [[self class] disableUserInteractionDuration:kDismissAnimationDuration];
    __weak __typeof(self)weakSelf = self;
    [UIView animateWithDuration:kDismissAnimationDuration delay:0 options:0 animations:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.photoWindow.alpha = 0.f;
    } completion:^(BOOL finished) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf _dismissWindow];
    }];
}

- (void)_dismissWindow {
    _photoWindow.hidden = YES;
    _photoWindow.rootViewController = nil;
    _photoWindow = nil;
}

#pragma mark - 禁止屏幕点击响应
+ (void)disableUserInteractionDuration:(NSTimeInterval)timeInterval {
    if (_userInteractionEnableTimer != nil) {
        if ([_userInteractionEnableTimer isValid]) {
            [_userInteractionEnableTimer invalidate];
            if ([UIApplication sharedApplication].isIgnoringInteractionEvents) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            }
        }
        _userInteractionEnableTimer = nil;
    }
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    _userInteractionEnableTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:timeInterval] interval:0 target:self selector:@selector(userInteractionEnable) userInfo:nil repeats:false];
    [[NSRunLoop mainRunLoop] addTimer:_userInteractionEnableTimer forMode:NSRunLoopCommonModes];
}

+ (void)userInteractionEnable {
    [_userInteractionEnableTimer invalidate];
    _userInteractionEnableTimer = nil;
    if ([UIApplication sharedApplication].isIgnoringInteractionEvents) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

@end
