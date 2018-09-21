//
//  WQPhotoBrowserController.h
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WQPhotoModel.h"

@protocol WQPhotoBrowserControllerDelegate <NSObject>

@optional
// 动画消失的目标frame
- (UIImageView *)sourceImageViewForIndex:(NSInteger)index;
// 获取图片展示占位图
- (UIImage *)photoBrowserPlaceholderImage;

@end

@interface WQPhotoBrowserController : UIViewController

@property (nonatomic, weak) id <WQPhotoBrowserControllerDelegate> delegate;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UILabel *pageLabel;

/**
 *  当前显示的图片位置索引 , 默认是0
 */
@property (nonatomic, assign) NSInteger currentImageIndex;

/**
 *  浏览的图片数量,大于0
 */
@property (nonatomic, assign) NSInteger imageCount;


/**
 图片数据 数组内可以是WQPhotoModel、UIImage、NSString、NSData
 */
@property (nonatomic, strong) NSArray *imagesArray;


/**
 初始化的方法
 
 @param imagesArray 图片数据 数组内可以是WQPhotoModel、UIImage、NSString、NSData
 @param index 当前显示的位置
 */
+ (instancetype)showPhotoBrowserWithImages:(NSArray *)imagesArray currentImageIndex:(NSInteger)index;

/**
 移除方法
 
 @param animation 动画
 */
- (void)dismissAnimation:(BOOL)animation;

@end
