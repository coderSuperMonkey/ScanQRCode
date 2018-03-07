//
//  EditViewController.m
//  ScanQRCode
//
//  Created by super on 2018/3/7.
//  Copyright © 2018年 gc. All rights reserved.
//

#import "EditViewController.h"

#import "QRCodeViewController.h"

@interface EditViewController ()

@property (weak, nonatomic) IBOutlet UITextField *contentTF;

@end

@implementation EditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)createQRCode:(id)sender {
    if (self.contentTF.text.length > 0) {
        [self performSegueWithIdentifier:@"Create" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Create"]) {
        QRCodeViewController *codeVC = (QRCodeViewController *)segue.destinationViewController;
        codeVC.codeString = self.contentTF.text;
    }
}

@end
