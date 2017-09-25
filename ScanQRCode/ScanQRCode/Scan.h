//
//  Scan.h
//  ScanQRCode
//
//  Created by gc on 2017/9/20.
//  Copyright © 2017年 gc. All rights reserved.
//

#ifndef Scan_h
#define Scan_h


#define COLOR(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define COLOR_A(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)/1.0]

#ifdef DEBUG
#define GCLog(...) NSLog(__VA_ARGS__);
#else
#define GCLog(...);
#endif

//屏幕的宽 高 比例
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

#define ScreenWidthScale ScreenWidth/375.0


#endif /* Scan_h */
