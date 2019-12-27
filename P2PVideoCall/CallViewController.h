//
//  CallViewController.h
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/18.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CallViewController : UIViewController

@property (nonatomic, assign) BOOL isServer;
@property (nonatomic, copy) NSString *desIPAddress;
@property (nonatomic, assign) uint16_t desPort;

@end

NS_ASSUME_NONNULL_END
