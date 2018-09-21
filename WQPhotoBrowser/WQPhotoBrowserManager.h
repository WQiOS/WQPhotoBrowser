//
//  WQPhotoBrowserManager.h
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 图片浏览管理类
 */
@interface WQPhotoBrowserManager : NSObject

@property (nonatomic, strong) UIWindow *photoWindow;

+ (instancetype)sharedManager;
- (void)presentWindowWithController:(UIViewController *)controller;
- (void)dismissWindow:(BOOL)animation;

@end
