//
//  ScanViewController.m
//  ScanQRCode
//
//  Created by gc on 2017/9/20.
//  Copyright © 2017年 gc. All rights reserved.
//

#import "ScanViewController.h"
#import "ScanResultViewController.h"

#import <AVFoundation/AVFoundation.h>

#import <Photos/Photos.h>

@interface ScanViewController ()<AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    AVCaptureSession * session;//输入输出的中间桥梁
    AVCaptureDevice * device;//获取摄像设备
    AVCaptureDeviceInput * input;//创建输入流
    AVCaptureMetadataOutput * output;//创建输出流
    AVCaptureVideoPreviewLayer * layer;//扫描窗口
}

@property (nonatomic, weak) UIImageView *activeImage;

@property (nonatomic, strong) UIImagePickerController *photoLibraryVC;


@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(openPhotos:)];
    
    CGFloat imageX = ScreenWidth*0.15;
    CGFloat imageY = ScreenWidth*0.15+64;
    
    // 扫描框中的四个边角的背景图
    UIImageView *scanImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"saoyisao"]];
    scanImage.frame = CGRectMake(imageX, imageY, ScreenWidth*0.7, ScreenWidth*0.7);
    [self.view addSubview:scanImage];
    
    // 上下移动的扫描条
    UIImageView *activeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"saoyisao-3"]];
    activeImage.frame = CGRectMake(imageX, imageY, ScreenWidth*0.7, 4);
    [self.view addSubview:activeImage];
    self.activeImage = activeImage;
    
    // 扫描框下面的提示按钮
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(scanImage.frame), ScreenWidth, 40)];
    label.text = @"将二维码放入框内即可自动扫描";
    label.font = [UIFont systemFontOfSize:15];
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
    
    //添加全屏的黑色半透明蒙版
    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    maskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    [self.view addSubview:maskView];
    //从蒙版中扣出扫描框那一块,这块的大小尺寸将来也设成扫描输出的作用域大小
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.view.bounds];
    [maskPath appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(imageX, imageY, ScreenWidth*0.7, ScreenWidth*0.7)] bezierPathByReversingPath]];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = maskPath.CGPath;
    maskView.layer.mask = maskLayer;
    
    // 判断相机权限
    [self checkCaptureStatus];
    
    // 初始化扫描需要用的相关实例变量
    [self initScanningContent];
    // 开始动画，扫描条上下移动
    [self performSelectorOnMainThread:@selector(timerFired) withObject:nil waitUntilDone:NO];
    // 添加监听->APP从后台返回前台，重新扫描
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStartRunning:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self sessionStartRunning:nil];
}

#pragma mark - 导航栏右边按钮打开相册
- (void)openPhotos:(UIBarButtonItem *)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusAuthorized) {//允许访问相册，直接进入相册选择器
            [self presentViewController:self.photoLibraryVC animated:YES completion:nil];
        }else if (status == PHAuthorizationStatusNotDetermined) {   //未确定是否允许，请求用户授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [self presentViewController:self.photoLibraryVC animated:YES completion:nil];
                }
            }];
        }else {
            NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
            if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
            NSString *string = [NSString stringWithFormat:@"请在iPhone的设置中允许%@访问相册",appName];
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"相册访问受限" message:string preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertVC addAction:actionCancel];
            UIAlertAction *actionSet = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
                }else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }];
            [alertVC addAction:actionSet];
            [self presentViewController:alertVC animated:YES completion:nil];
        }
    }else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"访问失败" message:@"当前设备不能访问相册或相机" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:actionCancel];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

- (UIImagePickerController *)photoLibraryVC {
    if (_photoLibraryVC == nil) {
        _photoLibraryVC = [[UIImagePickerController alloc] init];
        _photoLibraryVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        _photoLibraryVC.delegate = self;
        _photoLibraryVC.allowsEditing = YES;
    }
    return _photoLibraryVC;
}

- (void)sessionStartRunning:(NSNotification *)notification {
    if (session != nil) {
        // AVCaptureSession开始工作
        [session startRunning];
        //开始动画
        [self performSelectorOnMainThread:@selector(timerFired) withObject:nil waitUntilDone:NO];
    }
}

- (void)checkCaptureStatus {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatus == AVAuthorizationStatusAuthorized) {
    }else if (authorizationStatus == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
            }else{
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }else {
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *string = [NSString stringWithFormat:@"请在iPhone的设置中允许%@访问相机",appName];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"相机访问受限" message:string preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertVC addAction:actionCancel];
        UIAlertAction *actionSet = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
            }else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
        }];
        [alertVC addAction:actionSet];
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

/**
 *  添加扫描控件
 */
- (void)initScanningContent{
    //获取摄像设备
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //创建输出流
    output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [session addInput:input];
    [session addOutput:output];
    
    //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    
    //设置相机可视范围--全屏
    layer.frame = self.view.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    
    //开始捕获
    [session startRunning];
    
    //设置扫描作用域范围(中间透明的扫描框)
    CGRect intertRect = [layer metadataOutputRectOfInterestForRect:CGRectMake(ScreenWidth*0.15, ScreenWidth*0.15+64, ScreenWidth*0.7, ScreenWidth*0.7)];
    output.rectOfInterest = intertRect;
}

/**
 *  加载动画
 */
-(void)timerFired {
    //    [self.activeImage.layer addAnimation:[self moveY:3 Y:[NSNumber numberWithFloat:ScreenWidth*0.7-4]] forKey:nil];
    [self.activeImage.layer addAnimation:[self moveY:2.5 Y:[NSNumber numberWithFloat:(ScreenWidth*0.7-4)]] forKey:nil];
}

/**
 *  扫描线动画
 *
 *  @param time 单次滑动完成时间
 *  @param y    滑动距离
 *
 *  @return 返回动画
 */
- (CABasicAnimation *)moveY:(float)time Y:(NSNumber *)y {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath : @"transform.translation.y" ]; ///.y 的话就向下移动。
    animation.toValue = y;
    animation.duration = time;
    animation.removedOnCompletion = YES ; //yes 的话，又返回原位置了。
    animation.repeatCount = MAXFLOAT ;
    animation.fillMode = kCAFillModeForwards;
    //    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]; //匀速变化
    return animation;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
/**
 *  获取扫描到的结果
 *
 *  @param captureOutput   输出
 *  @param metadataObjects 结果
 *  @param connection      连接
 */
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0) {
        [session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        NSString *content = metadataObject.stringValue;
        GCLog(@"content = %@",content);
        if ([[metadataObject type] isEqualToString:AVMetadataObjectTypeQRCode] && content != nil) {
//            if ([metadataObject.stringValue containsString:@"http://"] || [metadataObject.stringValue containsString:@"https://"]) {
//                NSString *urlResult = metadataObject.stringValue;
//                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlResult] options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
//            }
            [self playBeep];
            [self performSegueWithIdentifier:@"ScanResult" sender:metadataObject.stringValue];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ScanResultViewController *resultVC = (ScanResultViewController *)segue.destinationViewController;
    resultVC.result = sender;
}

#pragma mark - image picker view controller delegate

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *pickImage = [info objectForKey:UIImagePickerControllerEditedImage];
        
        NSData *imageData = UIImagePNGRepresentation(pickImage);
        CIImage *ciImage = [CIImage imageWithData:imageData];
        
        //创建探测器
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
        NSArray *features = [detector featuresInImage:ciImage];
        
        NSString *content;
        //取出探测到的数据
//        for (CIQRCodeFeature *result in features) {
//            content = result.messageString;
//        }
        if (features.count > 0) {
            CIQRCodeFeature *feature = features[0];
            content = feature.messageString;
        }
        
        __weak typeof(self) weakSelf = self;
        //选中图片后先返回扫描页面，然后跳转到新页面进行展示
        [picker dismissViewControllerAnimated:YES completion:^{
            if (content) {
                //震动
                [weakSelf playBeep];
                [weakSelf performSegueWithIdentifier:@"ScanResult" sender:content];
            }else{
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"扫描提示" message:@"未识别图中的二维码" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil];
                [alertVC addAction:actionCancel];
                [weakSelf presentViewController:alertVC animated:YES completion:nil];
            }
        }];
    }
}

// 音效震动
- (void)playBeep{
    NSString *audioFile = [[NSBundle mainBundle] pathForResource:@"di"ofType:@"mp3"];
    NSURL *fileUrl = [NSURL fileURLWithPath:audioFile];
    
    SystemSoundID soundID;
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileUrl, &soundID);
    
    AudioServicesPlaySystemSound(soundID);
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
