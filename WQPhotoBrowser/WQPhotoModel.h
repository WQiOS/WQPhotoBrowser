//
//  WQPhotoModel.h
//  YunTi-Weibao
//
//  Created by 王强 on 2018/9/21.
//  Copyright © 2018年 浙江再灵科技股份有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WQPhotoModel : NSObject

@property (nonatomic, strong) NSData *imageData;         /**< 图片数据 */
@property (nonatomic, strong) UIImage *image;             /**< 图片数据 */
@property (nonatomic, strong) NSString *thumbURLString;    /**< 普通图下载链接 */
@property (nonatomic, strong) NSString *originURLString;   /**< 原图下载链接 */
@property (nonatomic, assign) CGFloat originImageSize;    /**< 原图的大小，单位为 B */

@end
