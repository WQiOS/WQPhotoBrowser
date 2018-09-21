//
//  WQPhotoGestureHandle.h
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class WQPhotoZoomScrollView, WQPhotoGestureHandle;

@protocol WQPhotoGestureHandleDelegate <NSObject>

// 获取当前展示的图片对象
- (WQPhotoZoomScrollView *)currentDetailImageViewInPhotoPreview:(WQPhotoGestureHandle *)handle;
// 图片对象去移除的代理
- (void)detailImageViewGotoDismiss;
// 控制图片控制器中，照片墙，更多等小组件的隐藏/显示
- (void)photoPreviewComponmentHidden:(BOOL)hidden;

@end

@interface WQPhotoGestureHandle : NSObject

@property (nonatomic, weak) id <WQPhotoGestureHandleDelegate> delegate;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView coverView:(UIView *)coverView;

@end
