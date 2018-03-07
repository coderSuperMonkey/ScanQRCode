//
//  UIImage+QRCode.h
//  ScanQRCode
//
//  Created by super on 2018/3/7.
//  Copyright © 2018年 gc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (QRCode)

/**
 *  快速创建不带logo二维码，默认宽高200*200
 *
 *  @param codeString 二维码内容
 *  @param sizeWidth  二维码图片大小
 *
 *  @return 生成的二维码图片
 */
+ (UIImage *)createQRCodeImageFromString:(NSString *)codeString withSize:(CGFloat)sizeWidth;

/**
 *  快速创建带logo二维码，默认宽高200*200,logo宽高40*40
 *
 *  @param codeString 二维码内容
 *  @param sizeWidth  二维码图片大小
 *  @param icon       logo 图片
 *  @param iconSize   logo size
 *
 *  @return 生成的带logo二维码图片
 */
+ (UIImage *)createQRCodeImageFromString:(NSString *)codeString withSize:(CGFloat)sizeWidth withLogo:(UIImage *)icon withIconSize:(CGSize)iconSize;

/**
 *  默认产生的黑白色的二维码图片,可以让它产生其它颜色的二维码图片
 *
 *  @param image 二维码图片
 *  @param red   red value
 *  @param green green value
 *  @param blue  blue value
 *
 *  @return 生成的图片
 */
+ (UIImage *)specialColorImage:(UIImage*)image withRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

/**
 *  解析二维码
 *
 *  @param ciImage    二维码图片CIImage
 *  @param completion 解析结果
 */
+ (void)analysisQRCodeFromCiImage:(CIImage *)ciImage completion:(void (^)(BOOL success, NSString *resultString))completion;

@end
