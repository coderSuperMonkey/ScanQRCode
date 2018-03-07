//
//  ScanResultViewController.m
//  ScanQRCode
//
//  Created by gc on 2017/9/20.
//  Copyright © 2017年 gc. All rights reserved.
//

#import "ScanResultViewController.h"

@interface ScanResultViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ScanResultViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.text = self.result;
}

@end
