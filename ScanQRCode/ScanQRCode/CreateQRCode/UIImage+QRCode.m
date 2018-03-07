//
//  UIImage+QRCode.m
//  ScanQRCode
//
//  Created by super on 2018/3/7.
//  Copyright © 2018年 gc. All rights reserved.
//

#import "UIImage+QRCode.h"

@implementation UIImage (QRCode)

#pragma mark - Private Methods for use

/**
 *  创建二维码图片CIImage
 *
 *  @param codeString 二维码内容
 *
 *  @return 生成的二维码图片(CIImage)
 */
+ (CIImage *)ciImageFromString:(NSString *)codeString {
    // 1.实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复滤镜的默认属性 (因为滤镜有可能保存上一次的属性)
    [filter setDefaults];
    // 3.将字符串转换成NSdata
    NSData *stringData = [codeString dataUsingEncoding:NSUTF8StringEncoding];
    // 4.通过KVO设置滤镜, 传入data, 将来滤镜就知道要通过传入的数据生成二维码
    [filter setValue:stringData forKey:@"inputMessage"];
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    // 5.生成二维码
    CIImage *outputImage = [filter outputImage];
    return outputImage;
}

/**
 *  将CIImage图片转成UIImage类型的二维码图片
 *
 *  @param image     CIImage图片
 *  @param sizeWidth 图片大小
 *
 *  @return 生成的二维码图片(UIImage)
 */
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)sizeWidth {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(sizeWidth/CGRectGetWidth(extent), sizeWidth/CGRectGetHeight(extent));
    
    // 创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}

/**
 *  添加logo到二维码图片
 *
 *  @param image    图片
 *  @param icon     logo
 *  @param iconSize logo size
 *
 *  @return 带logo图片
 */
+ (UIImage *)addIconToQRCodeImage:(UIImage *)image withIcon:(UIImage *)icon withIconSize:(CGSize)iconSize {
    //    UIGraphicsBeginImageContext(image.size);
    UIGraphicsBeginImageContextWithOptions(image.size, YES, [UIScreen mainScreen].scale);
    //通过两张图片进行位置和大小的绘制，实现两张图片的合并；其实此原理做法也可以用于多张图片的合并
    CGFloat widthOfImage = image.size.width;
    CGFloat heightOfImage = image.size.height;
    CGFloat widthOfIcon = iconSize.width;
    CGFloat heightOfIcon = iconSize.height;
    [image drawInRect:CGRectMake(0, 0, widthOfImage, heightOfImage)];
    [icon drawInRect:CGRectMake((widthOfImage-widthOfIcon)/2, (heightOfImage-heightOfIcon)/2, widthOfIcon, heightOfIcon)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

/**
 *  添加logo到二维码图片
 *
 *  @param image 图片
 *  @param icon  logo
 *  @param scale logo scale
 *
 *  @return 带logo图片
 */
+ (UIImage *)addIconToQRCodeImage:(UIImage *)image withIcon:(UIImage *)icon withScale:(CGFloat)scale {
    //    UIGraphicsBeginImageContext(image.size);
    UIGraphicsBeginImageContextWithOptions(image.size, YES, [UIScreen mainScreen].scale);
    //通过两张图片进行位置和大小的绘制，实现两张图片的合并；其实此原理做法也可以用于多张图片的合并
    CGFloat widthOfImage = image.size.width;
    CGFloat heightOfImage = image.size.height;
    CGFloat widthOfIcon = widthOfImage * scale;
    CGFloat heightOfIcon = heightOfImage * scale;
    
    [image drawInRect:CGRectMake(0, 0, widthOfImage, heightOfImage)];
    [icon drawInRect:CGRectMake((widthOfImage-widthOfIcon)/2, (heightOfImage-heightOfIcon)/2, widthOfIcon, heightOfIcon)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

void ProviderReleaseData(void *info, const void *data, size_t size){
    free((void*)data);
}

#pragma mark - simple method for use

+ (UIImage *)createQRCodeImageFromString:(NSString *)codeString withSize:(CGFloat)sizeWidth {
    if (sizeWidth <= 0) {
        sizeWidth = 200;
    }
    CIImage *ciImage = [self ciImageFromString:codeString];
    UIImage *image = [self createNonInterpolatedUIImageFormCIImage:ciImage withSize:sizeWidth];
    return image;
}

+ (UIImage *)createQRCodeImageFromString:(NSString *)codeString withSize:(CGFloat)sizeWidth withLogo:(UIImage *)icon withIconSize:(CGSize)iconSize {
    if (sizeWidth <= 0) {
        sizeWidth = 200;
    }
    if (iconSize.width <= 0) {
        iconSize = CGSizeMake(50, 50);
    }
    CIImage *ciImage = [self ciImageFromString:codeString];
    UIImage *image = [self createNonInterpolatedUIImageFormCIImage:ciImage withSize:sizeWidth];
    UIImage *resultImage = [self addIconToQRCodeImage:image withIcon:icon withIconSize:iconSize];
    return resultImage;
}

+ (void)analysisQRCodeFromCiImage:(CIImage *)ciImage completion:(void (^)(BOOL success, NSString *resultString))completion {
    if (!ciImage) {
        if (completion) {
            completion(NO, nil);
        }
    }else {
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:[CIContext contextWithOptions:nil] options:@{CIDetectorAccuracy:CIDetectorAccuracyHigh}];
        NSArray *features = [detector featuresInImage:ciImage];
        if (features.count) {
            for (CIFeature *feature in features) {
                if ([feature isKindOfClass:[CIQRCodeFeature class]]) {
                    NSString *content = ((CIQRCodeFeature *)feature).messageString;
                    if (completion) {
                        completion(YES, content);
                    }
                    break;
                }
            }
        } else {
            if (completion) {
                completion(NO, nil);
            }
        }
    }
}

+ (UIImage *)specialColorImage:(UIImage *)image withRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue {
    const int imageWidth = image.size.width;
    const int imageHeight = image.size.height;
    size_t bytesPerRow = imageWidth * 4;
    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);
    
    //Create context
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef contextRef = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpaceRef, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);
    
    //Traverse pixe
    int pixelNum = imageWidth * imageHeight;
    uint32_t* pCurPtr = rgbImageBuf;
    for (int i = 0; i < pixelNum; i++, pCurPtr++){
        if ((*pCurPtr & 0xFFFFFF00) < 0x99999900){
            //Change color
            uint8_t *ptr = (uint8_t *)pCurPtr;
            ptr[3] = red; //0~255
            ptr[2] = green;
            ptr[1] = blue;
        }else{
            uint8_t *ptr = (uint8_t *)pCurPtr;
            ptr[0] = 0;
        }
    }
    
    //Convert to image
    CGDataProviderRef dataProviderRef = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);
    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpaceRef, kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProviderRef, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProviderRef);
    UIImage* img = [UIImage imageWithCGImage:imageRef];
    
    //Release
    CGImageRelease(imageRef);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpaceRef);
    return img;
}

@end
