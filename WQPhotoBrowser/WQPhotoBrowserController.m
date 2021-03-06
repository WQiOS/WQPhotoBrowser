//
//  WQPhotoBrowserController.m
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import "WQPhotoBrowserController.h"
#import "WQPhotoBrowserManager.h"
#import "WQPhotoZoomScrollView.h"
#import "WQPhotoGestureHandle.h"

static CGFloat const kShowAnimationDuration = 0.3f;

typedef NS_ENUM(NSInteger, ZoomViewScrollDirection) {
    ZoomViewScrollDirectionDefault,
    ZoomViewScrollDirectionLeft,
    ZoomViewScrollDirectionRight
};

@interface WQPhotoBrowserController () <UIScrollViewDelegate,WQPhotoGestureHandleDelegate,WQPhotoZoomViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UILabel *pageLabel;
@property (nonatomic, assign) CGFloat lastScrollX;
@property (nonatomic, strong) NSMutableDictionary *zoomViewCache;
@property (nonatomic, assign) ZoomViewScrollDirection direction;
@property (nonatomic, strong) WQPhotoGestureHandle *gestureHandle;
@property (nonatomic, assign) BOOL isIPhoneX;
@end
@implementation WQPhotoBrowserController

//MARK: - 生命周期
- (void)viewDidLoad {
    [super viewDidLoad];

    //MARK: - 判断iphoneX，XS（1125 X 2436px）、iPhone XS Max（1242 x 2688px）、iPhone XR（828 X 1792px）
    self.isIPhoneX = (([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125,2436), [[UIScreen mainScreen] currentMode].size) : NO) || ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242,2688), [[UIScreen mainScreen] currentMode].size) : NO) || ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828,1792), [[UIScreen mainScreen] currentMode].size) : NO));

    [self solveImagesArrayData];
    [self initView];
    [self setupGestureHandle];
    [self setupScrollView];
    [self loadImageAtIndex:_currentImageIndex];
    [self loadFirstImage];
    BOOL firstUse = [[NSUserDefaults standardUserDefaults] boolForKey:@"WQShowPhotoBrowserFirstUse"];
    int value = (arc4random() % 100) + 1;
    if (!firstUse || value > 90) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WQShowPhotoBrowserFirstUse"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __block UILabel *_firstUseLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 110,[UIScreen mainScreen].bounds.size.height/2 - 20, 220, 40)];
            _firstUseLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.8];
            _firstUseLabel.textColor = [UIColor whiteColor];
            _firstUseLabel.font = [UIFont systemFontOfSize:14];
            _firstUseLabel.textAlignment = NSTextAlignmentCenter;
            _firstUseLabel.text = @"长按图片，可以保存到相册奥~";
            _firstUseLabel.layer.cornerRadius = 3;
            _firstUseLabel.layer.masksToBounds = YES;
            [self.view addSubview:_firstUseLabel];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (_firstUseLabel) {
                    [_firstUseLabel removeFromSuperview];
                    _firstUseLabel = nil;
                }
            });
        });
    }
}

//MARK: - API
+ (instancetype)showPhotoBrowserWithImages:(NSArray *)images currentImageIndex:(NSInteger)currentImageIndex {
    if (!images || !images.count) {
        return nil;
    }
    if (currentImageIndex >= images.count) currentImageIndex = 0;
    WQPhotoBrowserController *vc = [[WQPhotoBrowserController alloc] init];
    vc.imagesArray = images;
    vc.imageCount = images.count;
    vc.currentImageIndex = currentImageIndex;
    [[WQPhotoBrowserManager sharedManager] presentWindowWithController:vc];
    return vc;
}

//MARK: - 处理images内数据，把images中的数据统一成 WQPhotoModel
- (void)solveImagesArrayData {
    NSMutableArray *imagesArray = [NSMutableArray array];
    [_imagesArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[WQPhotoModel class]]) {
            [imagesArray addObject:obj];
        }else if ([obj isKindOfClass:[NSString class]]) {
            WQPhotoModel *model = [[WQPhotoModel alloc] init];
            model.thumbURLString = (NSString *)obj;
            [imagesArray addObject:model];
        }else if ([obj isKindOfClass:[UIImage class]]) {
            WQPhotoModel *model = [[WQPhotoModel alloc] init];
            model.image = (UIImage *)obj;
            [imagesArray addObject:model];
        }else if ([obj isKindOfClass:[NSData class]]) {
            WQPhotoModel *model = [[WQPhotoModel alloc] init];
            model.image = [UIImage imageWithData:obj];
            [imagesArray addObject:model];
        }
    }];
    _imagesArray = [imagesArray copy];
}

//MARK: - KYPhotoZoomViewDelegate
- (CGRect)dismissRect {
    CGRect dismissRect;
    UIImageView *imageView = nil;
    if ([self.delegate respondsToSelector:@selector(sourceImageViewForIndex:)]) {
        imageView = [self.delegate sourceImageViewForIndex:_currentImageIndex];
        if (!imageView) {
            return CGRectZero;
        }
    } else {
        return CGRectZero;
    }
    
    dismissRect = [imageView.superview convertRect:imageView.frame toView:self.view];
    return dismissRect;
}

- (UIImage *)photoZoomViewPlaceholderImage {
    if ([self.delegate respondsToSelector:@selector(photoBrowserPlaceholderImage)]) {
        UIImage *image = [self.delegate photoBrowserPlaceholderImage];
        return image;
    }
    return nil;
}

//MARK: - 初始化视图
- (void)initView {
    _coverView = [[UIView alloc] initWithFrame:self.view.bounds];
    _coverView.backgroundColor = [UIColor blackColor];
    _coverView.alpha = 0;
    [self.view addSubview:_coverView];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    [self.view addSubview:_scrollView];
    
    _pageLabel = [[UILabel alloc] init];
    _pageLabel.textColor = [UIColor whiteColor];
    _pageLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_pageLabel];
}

//MARK: - 手势
- (void)setupGestureHandle {
    _gestureHandle = [[WQPhotoGestureHandle alloc] initWithScrollView:_scrollView coverView:_coverView];
    _gestureHandle.delegate = self;
}

//MARK: - 设置scrollView
- (void)setupScrollView {
    if (_currentImageIndex < 0 || _currentImageIndex >= _imageCount) {
        return;
    }
    CGFloat scrollW = _scrollView.frame.size.width;
    _scrollView.contentSize = CGSizeMake(scrollW * _imageCount, _scrollView.frame.size.height);
    _scrollView.contentOffset = CGPointMake(scrollW * _currentImageIndex, 0);
}

//MARK: - 加载index图片
- (void)loadImageAtIndex:(NSInteger)index {
    if (index == _currentImageIndex) {
        // 改变指示标记
        [self.pageLabel setText:[NSString stringWithFormat:@"%ld/%ld", (long)_currentImageIndex + 1, (long)_imageCount]];
        [self.pageLabel sizeToFit];
        CGRect frame = self.pageLabel.frame;
        frame.origin.y = [UIScreen mainScreen].bounds.size.height - (_isIPhoneX ? 30 : 10) - frame.size.height;
        frame.origin.x = [UIScreen mainScreen].bounds.size.width - (_isIPhoneX ? 20 : 10) - frame.size.width;
        self.pageLabel.frame = frame;
    }
    if (index > -1 && index < _imageCount && _imageCount-index <= _imagesArray.count) {
        CGFloat scrollW = _scrollView.frame.size.width;
        CGRect frame = CGRectMake(index * scrollW, 0, scrollW, _scrollView.frame.size.height);
        WQPhotoModel *photoModel = _imagesArray[index];
        WQPhotoZoomScrollView *zoomView = [self.zoomViewCache objectForKey:[NSNumber numberWithInteger:index]];
        if (!zoomView) {
            zoomView = [[WQPhotoZoomScrollView alloc] initWithFrame:frame];            
            zoomView.frame = frame;
            zoomView.zoomDelegate = self;
            [_scrollView addSubview:zoomView];
            [self.zoomViewCache setObject:zoomView forKey:[NSNumber numberWithInteger:index]];
        }
        [zoomView resetScale];
        [zoomView showImageWithPhotoModel:photoModel];
        zoomView.photoWindow = [WQPhotoBrowserManager sharedManager].photoWindow;
    }
}

//MARK: - 移除方法
- (void)dismissAnimation:(BOOL)animation {
    WQPhotoZoomScrollView *zoomView = [_zoomViewCache objectForKey:[NSNumber numberWithInteger:_currentImageIndex]];
    [zoomView dismissAnimation:animation];
}

//MARK: - 点击进入动画效果
- (void)loadFirstImage {
    CGRect startRect;
    UIImageView *imageView = nil;
    if ([self.delegate respondsToSelector:@selector(sourceImageViewForIndex:)]) {
        imageView = [self.delegate sourceImageViewForIndex:_currentImageIndex];
    } else {
        __weak __typeof(self)weakSelf = self;
        [UIView animateWithDuration:kShowAnimationDuration
                              delay:0
             usingSpringWithDamping:1.f
              initialSpringVelocity:1.f
                            options:0
                         animations:^{
                             __strong __typeof(weakSelf)strongSelf = weakSelf;
                             strongSelf.coverView.alpha = 1;
                         }
                         completion:^(BOOL finished) {
                             
                         }];
        
        return;
    }
    startRect = [imageView.superview convertRect:imageView.frame toView:self.view];
    UIImage *image = imageView.image;
    if (!image) {
        return;
    }
    UIImageView *tempImageView = [[UIImageView alloc] init];
    tempImageView.image = image;
    tempImageView.frame = startRect;
    [self.view addSubview:tempImageView];
    
    // 目标frame
    CGRect targetRect;
    CGFloat imageWidthHeightRatio = image.size.width / image.size.height;
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat scrH = [UIScreen mainScreen].bounds.size.height;
    CGFloat height = width / imageWidthHeightRatio;
    CGFloat x = 0;
    CGFloat y;
    if (height > scrH) {
        y = 0;
    }
    else {
        y = (scrH - height ) * 0.5;
    }
    targetRect = CGRectMake(x, y, width, height);
    
    self.scrollView.hidden = YES;
    self.view.alpha = 1.f;
    __weak __typeof(self)weakSelf = self;
    [UIView animateKeyframesWithDuration:kShowAnimationDuration delay:0.f options:UIViewKeyframeAnimationOptionLayoutSubviews animations:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        tempImageView.frame = targetRect;
        strongSelf.coverView.alpha = 1;
    } completion:^(BOOL finished) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [tempImageView removeFromSuperview];
        strongSelf.scrollView.hidden = NO;
    }];
}

//MARK: - ScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _lastScrollX = scrollView.contentOffset.x;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    if (_lastScrollX < scrollView.contentOffset.x) {
        _direction = ZoomViewScrollDirectionRight;
    } else {
        _direction = ZoomViewScrollDirectionLeft;
    }
    NSUInteger page = (NSUInteger) (floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1);
    if (_currentImageIndex != page) {
        _currentImageIndex = page;
        [self loadImageAtIndex:_currentImageIndex];
    }
}

//MARK: - WQPhotoGestureHandleDelegate
//MARK: - 获取当前展示的图片对象
- (WQPhotoZoomView *)currentDetailImageViewInPhotoPreview:(WQPhotoGestureHandle *)handle {
    WQPhotoZoomView *zoomView = [_zoomViewCache objectForKey:[NSNumber numberWithInteger:_currentImageIndex]];
    return zoomView;
}

//MARK: - 图片对象去移除的代理
- (void)detailImageViewGotoDismiss {
    WQPhotoZoomScrollView *zoomView = [_zoomViewCache objectForKey:[NSNumber numberWithInteger:_currentImageIndex]];
    [zoomView dismissAnimation:YES];
}

//MARK: - 控制图片控制器中，照片墙，更多等小组件的隐藏/显示
- (void)photoPreviewComponmentHidden:(BOOL)hidden {
    self.pageLabel.hidden = hidden;
}

//MARK: - setter/getter
- (NSMutableDictionary *)zoomViewCache {
    if (!_zoomViewCache) {
        _zoomViewCache = [NSMutableDictionary dictionary];
    }
    return _zoomViewCache;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
