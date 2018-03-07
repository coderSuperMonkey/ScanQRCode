//
//  QRCodeViewController.m
//  ScanQRCode
//
//  Created by super on 2018/3/7.
//  Copyright © 2018年 gc. All rights reserved.
//

#import "QRCodeViewController.h"

#import "UIImage+QRCode.h"

@interface QRCodeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *codeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *logoCodeImageView;

@end

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.codeImageView.image = [UIImage createQRCodeImageFromString:self.codeString withSize:160];
    
    self.logoCodeImageView.image = [UIImage createQRCodeImageFromString:self.codeString withSize:160 withLogo:[UIImage imageNamed:@"centerIcon"] withIconSize:CGSizeMake(40, 40)];
}

@end
