//
//  WQPhotoZoomScrollView.h
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
@class WQPhotoModel;

typedef NS_ENUM(NSInteger, ShowImageState) {
    ShowImageStateSmall,    // 初始化默认是小图
    ShowImageStateBig,   // 全屏的正常图片
    ShowImageStateOrigin    // 原图
};

@class WQPhotoZoomView;

@protocol WQPhotoZoomViewDelegate <NSObject>

- (CGRect)dismissRect;
- (UIImage *)photoZoomViewPlaceholderImage;

@end

@interface WQPhotoZoomScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, weak) id <WQPhotoZoomViewDelegate> zoomDelegate;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, assign, readonly) ShowImageState imageState;
@property (nonatomic, assign) CGFloat process;
@property (nonatomic, strong) UIWindow *photoWindow;

- (void)resetScale;
- (void)showImageWithPhotoModel:(WQPhotoModel *)photoModel;
- (void)dismissAnimation:(BOOL)animation;

@end
