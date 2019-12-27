//
//  SocketClient.h
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/18.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SocketClientDelegate <NSObject>

- (void)didReceiveData:(NSData *)data;
- (void)didConnectSuccess;
- (void)didLostConnection;

@end

@interface SocketClient : NSObject

@property (weak, nonatomic) id<SocketClientDelegate> delegate;

- (BOOL)startListenPort:(uint16_t)port;
- (void)startConnectTo:(NSString *)ipAddress port:(uint16_t)port;
- (void)sendData:(NSData *)data;
- (void)resetData;

@end

NS_ASSUME_NONNULL_END
