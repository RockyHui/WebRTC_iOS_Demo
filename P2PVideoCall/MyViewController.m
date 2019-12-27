//
//  MyViewController.m
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/18.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import "MyViewController.h"
#import "CallViewController.h"

@interface MyViewController ()
@property (weak, nonatomic) IBOutlet UITextField *ipTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;

@end

@implementation MyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"goToCallView"]) {
        CallViewController *desViewController = (CallViewController *)segue.destinationViewController;
        if (sender == _connectButton) {
            desViewController.isServer = NO;
            desViewController.desIPAddress = _ipTextField.text;
            desViewController.desPort =  (uint16_t)[_portTextField.text intValue];
        } else {
            desViewController.isServer = YES;
        }
    }
}

- (IBAction)clickedConnectButton:(id)sender {
    if (_ipTextField.text.length == 0 || _portTextField.text.length == 0) {
        NSLog(@"请输入ip地址和端口");
        return;
    }
    [self performSegueWithIdentifier:@"goToCallView" sender:_connectButton];
}

- (IBAction)clickedAccpetButton:(id)sender {
    [self performSegueWithIdentifier:@"goToCallView" sender:_acceptButton];
}

@end
