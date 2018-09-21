//
//  WQPhotoZoomScrollView.m
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import "WQPhotoZoomScrollView.h"
#import "WQPhotoBrowserManager.h"
#import "WQPhotoModel.h"
#import <Photos/Photos.h>

static CGFloat const kShowAnimationDuration = 0.3f;

@interface WQPhotoZoomScrollView ()

@property (nonatomic, strong) WQPhotoModel  *photoModel;
@property (nonatomic, strong) UIImageView   *imageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) BOOL hasCommonView;

@end

@implementation WQPhotoZoomScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageState = ShowImageStateSmall;
        [self initView];
        [self addGestures];
    }
    return self;
}

- (void)initView {
    self.directionalLockEnabled = YES;
    self.minimumZoomScale = 1.f;
    self.maximumZoomScale = 3.f;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.delegate = self;
    
    CGFloat imageViewW = [UIScreen mainScreen].bounds.size.width - 2 * 60;
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageViewW, imageViewW)];
    _imageView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.clipsToBounds = YES;
    _imageView.userInteractionEnabled = YES;
    [self addSubview:_imageView];
}

- (void)addGestures {
    // 1 add double tap gesture
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleClick:)];
    doubleTap.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTap];
    
    // 2 add single tap gesture
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [tap requireGestureRecognizerToFail:doubleTap];
    [self addGestureRecognizer:tap];
    
    // 3 长按
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longAction:)];
    longPress.minimumPressDuration = 1.0;
    [self addGestureRecognizer:longPress];
}

//MARK: - 手势处理 && 事件处理
// 下载原图
- (void)downloadOriginImage {
    UIImage *placeholderImage = nil;
    if ([self.zoomDelegate respondsToSelector:@selector(photoZoomViewPlaceholderImage)]) {
        placeholderImage = [self.zoomDelegate photoZoomViewPlaceholderImage];
    }
    [self.activityIndicator startAnimating];
    __weak __typeof(self)weakSelf = self;
    [_imageView sd_setImageWithURL:[NSURL URLWithString:_photoModel.originURLString] placeholderImage:placeholderImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.activityIndicator stopAnimating];
    }];
}

//MARK: - 相册权限
- (BOOL)requestAlbumAuthorizationStatus {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusRestricted ||
        status == PHAuthorizationStatusDenied) {
        return NO;
    }
    return YES;
}

//MARK: - 点一次，消失
- (void)tapAction:(UIPanGestureRecognizer *)sender {
    [self dismissAnimation:YES];
}

//MARK: - 双击放大
- (void)didDoubleClick:(UITapGestureRecognizer *)sender {
    if (self.imageState > ShowImageStateSmall) {
        if (self.zoomScale != 1.0) {
            // 还原
            [self setZoomScale:1.f animated:YES];
        } else {
            // 放大
            CGPoint point = [sender locationInView:sender.view];
            CGFloat touchX = point.x;
            CGFloat touchY = point.y;
            touchX *= 1/self.zoomScale;
            touchY *= 1/self.zoomScale;
            touchX += self.contentOffset.x;
            touchY += self.contentOffset.y;
            CGRect zoomRect = [self zoomRectForScale:2.f withCenter:CGPointMake(touchX, touchY)];
            [self zoomToRect:zoomRect animated:YES];
        }
    }
}

//MARK: - 长按下载图片
- (void)longAction:(UITapGestureRecognizer *)sender {
    BOOL albumAuthorizationStatus = [self requestAlbumAuthorizationStatus];
    if (!albumAuthorizationStatus) {
        
    }else if (self.photoModel.thumbURLString && ([self.photoModel.thumbURLString containsString:@"png"] || [self.photoModel.thumbURLString containsString:@"jpg"])) {
        //gif暂时不做保存
        __weak __typeof(self)weakSelf = self;
        [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:self.photoModel.thumbURLString] options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            UIImageWriteToSavedPhotosAlbum(image, strongSelf, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }];
    } else if (self.photoModel.image || self.photoModel.imageData) {
        UIImage *image = self.photoModel.image;
        if (!image) {
            image = [UIImage imageWithData:self.photoModel.imageData];
        }
        if (image) {
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
        }
    }
}

//MARK: - 将相片存入相册, 只回调这个方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if(!error){
        [self creatPromptView:@"保存成功!"];
    }else{
        [self creatPromptView:@"保存失败!"];
    }
}

//MARK: - 弹窗提示
- (void)creatPromptView:(NSString *)title {
    if (self.hasCommonView && (![title isKindOfClass:[NSString class]] || !title || !title.length)) {
        return;
    }
    self.hasCommonView = YES;
    CGRect frame = [title boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 20, CGFLOAT_MAX) options:NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.0]} context:nil];
    frame.size.height = ceil(frame.size.height);
    frame.size.width = ceil(frame.size.width);
    UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width+28, frame.size.height+20)];
    promptLabel.center = CGPointMake( [UIScreen mainScreen].bounds.size.width/2,  [UIScreen mainScreen].bounds.size.height/2 + 40);
    promptLabel.textAlignment = NSTextAlignmentCenter;
    promptLabel.text = title;
    promptLabel.font = [UIFont systemFontOfSize:16.0];
    promptLabel.textColor = [UIColor whiteColor];
    promptLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
    promptLabel.layer.cornerRadius = 4;
    promptLabel.layer.masksToBounds = YES;
    promptLabel.alpha = 1;
    [self.photoWindow addSubview:promptLabel];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (promptLabel) {
            [UIView animateWithDuration:0.5 animations:^{
                promptLabel.alpha = 0.1;
            } completion:^(BOOL finished) {
                self.hasCommonView = NO;
                [promptLabel removeFromSuperview];
            }];
        }else{
            self.hasCommonView = NO;
        }
    });
}

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGFloat height = self.frame.size.height / scale;
    CGFloat width  = self.frame.size.width / scale;
    CGFloat x = center.x - width * 0.5;
    CGFloat y = center.y - height * 0.5;
    return CGRectMake(x, y, width, height);
}

//MARK: - API
- (void)resetScale {
    [self setZoomScale:1.f animated:NO];
}

- (void)showImageWithPhotoModel:(WQPhotoModel *)photoModel {
    _photoModel = photoModel;
    UIImage *placeholderImage = nil;
    if ([self.zoomDelegate respondsToSelector:@selector(photoZoomViewPlaceholderImage)]) {
        placeholderImage = [self.zoomDelegate photoZoomViewPlaceholderImage];
    }
    
    if (!photoModel) {
        if ([self.zoomDelegate respondsToSelector:@selector(photoZoomViewPlaceholderImage)]) {
            _imageView.image = placeholderImage;
        }
        return;
    }
    if (photoModel.thumbURLString && ([photoModel.thumbURLString containsString:@"png"] || [photoModel.thumbURLString containsString:@"jpg"] || [photoModel.thumbURLString containsString:@"gif"])) {
        __weak __typeof(self)weakSelf = self;
        [self.activityIndicator startAnimating];
        [_imageView sd_setImageWithURL:[NSURL URLWithString:photoModel.thumbURLString] placeholderImage:placeholderImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf.activityIndicator stopAnimating];
            if (image) {
                [strongSelf becomeBigStateImage:strongSelf.imageView.image animation:YES];
                self->_imageState = ShowImageStateOrigin;
            }else {
                // 处理大图加载失效情况                
            }
        }];
    } else if (photoModel.image || photoModel.imageData) {
        _imageView.image = photoModel.image ? photoModel.image : [UIImage imageWithData:photoModel.imageData];
        [self becomeBigStateImage:_imageView.image animation:YES];
        _imageState = ShowImageStateBig;
    } else {
        _imageView.image = placeholderImage;
        [self becomeBigStateImage:_imageView.image animation:YES];
        _imageState = ShowImageStateBig;
    }
}

//MARK: - 辅助函数
- (void)becomeBigStateImage:(UIImage *)image animation:(BOOL)animation {
    if (animation) {
        [UIView animateWithDuration:kShowAnimationDuration
                              delay:0
             usingSpringWithDamping:1.f
              initialSpringVelocity:1.f
                            options:0
                         animations:^{
                             [self setupImageView:image];
                         }
                         completion:^(BOOL finished) {
                             
                         }];
    } else {
        [self setupImageView:image];
    }
}

- (void)setupImageView:(UIImage *)image {
    if (!image) {
        return;
    }
    CGFloat scrW = [UIScreen mainScreen].bounds.size.width;
    CGFloat scale = scrW / image.size.width;
    CGSize size = CGSizeMake(scrW, image.size.height * scale);
    CGFloat y = MAX(0., (self.frame.size.height - size.height) / 2.f);
    CGFloat x = MAX(0., (self.frame.size.width - size.width) / 2.f);
    [self.imageView setFrame:CGRectMake(x, y, size.width, size.height)];
    [self.imageView setImage:image];
    self.contentSize = CGSizeMake(self.bounds.size.width, size.height);
}

- (void)dismissAnimation:(BOOL)animation {
    __block CGRect toFrame;
    if ([self.zoomDelegate respondsToSelector:@selector(dismissRect)]) {
        toFrame = [self.zoomDelegate dismissRect];
        if (CGRectEqualToRect(toFrame, CGRectZero) || CGRectEqualToRect(toFrame, CGRectNull)) {
            animation = NO;
        }
    }
    if (animation) {
        if (_imageView.image) {
            _imageView.contentMode = UIViewContentModeScaleAspectFill;
            __weak __typeof(self)weakSelf = self;
            [UIView animateWithDuration:kShowAnimationDuration
                                  delay:0
                 usingSpringWithDamping:1.f
                  initialSpringVelocity:1.f
                                options:0
                             animations:^{
                                 __strong __typeof(weakSelf)strongSelf = weakSelf;
                                 strongSelf.imageView.frame = CGRectMake(toFrame.origin.x+self.contentOffset.x, toFrame.origin.y+self.contentOffset.y, toFrame.size.width, toFrame.size.height);
                             } completion:^(BOOL finished) {
                             }];
        }
    }
    [[WQPhotoBrowserManager sharedManager] dismissWindow:YES];
}

//MARK: - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerScrollViewContents];
}

//MARK: - 缩放小于1的时候，始终让其在中心点位置进行缩放
- (void)centerScrollViewContents {
    CGSize boundsSize = self.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    } else {
        contentsFrame.origin.x = 0.0f;
    }
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    } else {
        contentsFrame.origin.y = 0.0f;
    }
    self.imageView.frame = contentsFrame;
}

//MARK: - setter / getter
- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.center = CGPointMake(self.frame.size.width*0.5, self.frame.size.height*0.5);
        [self addSubview:_activityIndicator];
        _activityIndicator.tintColor = [UIColor grayColor];
        _activityIndicator.hidesWhenStopped = YES;
    }
    return _activityIndicator;
}

@end
