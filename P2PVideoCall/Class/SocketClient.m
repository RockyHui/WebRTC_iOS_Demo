//
//  SocketClient.m
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/18.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import "SocketClient.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface SocketClient()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socketClient;
@property (nonatomic, strong) GCDAsyncSocket *neSocket;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@property (nonatomic, strong) NSMutableArray *sendDataQueue;

@end

@implementation SocketClient

- (instancetype)init {
    self = [super init];
    if (self) {
        _socketClient = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _dataBuffer = [NSMutableData data];
        _sendDataQueue  = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isDataComplete:(NSData *)data {
    NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, 4)];
    unsigned int totalSize = 0;
    [totalSizeData getBytes:&totalSize length:4];
    if (totalSize <= data.length) {
        return YES;
    } else {
        return NO;
    }
}

- (void)recvData:(NSData *)data{
    //直接就给他缓存起来
    if (data.length > 0) {
        [self.dataBuffer appendData:data];
    }
    // 获取总的数据包大小
    // 整段数据长度(不包含长度跟类型)
    NSData *totalSizeData = [self.dataBuffer subdataWithRange:NSMakeRange(0, 8)];
    unsigned int totalSize = 0;
    [totalSizeData getBytes:&totalSize length:8];
    //包含长度跟类型的数据长度
    unsigned int completeSize = totalSize - 8;
    //必须要大于4 才会进这个循环
    if (self.dataBuffer.length>8) {
        if (self.dataBuffer.length < completeSize) {
            //如果缓存的长度 还不如 我们传过来的数据长度，就让socket继续接收数据
            return;
        }
        //取出数据
        NSData *resultData = [self.dataBuffer subdataWithRange:NSMakeRange(8, completeSize)];
        //处理数据
        [self handleRecvData:resultData];
        //清空刚刚缓存的data
        [self.dataBuffer replaceBytesInRange:NSMakeRange(0, totalSize) withBytes:nil length:0];
        //如果缓存的数据长度还是大于4，再执行一次方法
        if (self.dataBuffer.length > 8) {
            [self recvData:nil];
        }
    }
}

- (void)handleRecvData:(NSData *)data {
    NSLog(@"收到数据");
    NSData *pureData = data;
    if (_delegate && [_delegate respondsToSelector:@selector(didReceiveData:)]) {
        [_delegate didReceiveData:pureData];
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (nullable dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock {
    NSLog(@"%s", __func__);
    return dispatch_get_main_queue();
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"%s", __func__);
    
    self.neSocket = newSocket;
    self.neSocket.delegate = _socketClient.delegate;
    self.neSocket.delegateQueue = _socketClient.delegateQueue;
    
    [self.neSocket readDataWithTimeout:-1 tag:10000];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"连接到：%@ %@", host, @(port));
    [_socketClient readDataWithTimeout:-1 tag:10000];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didConnectSuccess)]) {
        [self.delegate didConnectSuccess];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url {
    NSLog(@"%s", __func__);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"%s", __func__);
    [self recvData:data];
    [_socketClient readDataWithTimeout:-1 tag:10000];
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"%s", __func__);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s", __func__);
}

- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"%s", __func__);
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    NSLog(@"%s", __func__);
    return 10;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length {
    NSLog(@"%s", __func__);
    return 10;
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    NSLog(@"%s", __func__);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err {
    NSLog(@"%s %@", __func__, err.description);
    [self resetData];
    if (_delegate && [_delegate respondsToSelector:@selector(didLostConnection)]) {
        [_delegate didLostConnection];
    }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"%s", __func__);
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler {
    NSLog(@"%s", __func__);
}

#pragma mark - Public

// 监听端口
- (BOOL)startListenPort:(uint16_t)port {
    if (port < 0) {
        return NO;
    }
    NSError *error;
    BOOL result = [_socketClient acceptOnPort:port error:&error];
    if (!result || error != nil) {
        NSLog(@"Listening Fial: %@", error.description);
    } else {
        NSLog(@"开始监听端口：%@", @(port));
    }
    
    return result;
}

- (void)startConnectTo:(NSString *)ipAddress port:(uint16_t)port {
    if (ipAddress.length == 0 || port < 0) {
        return;
    }
    if (_socketClient.isConnected) {
        NSLog(@"Socket 已连接");
        return;
    }
    NSError *error;
    BOOL result = [_socketClient connectToHost:ipAddress onPort:port error:&error];
    if (!result || error != nil) {
        NSLog(@"Connect Fail:%@", error.description);
    } else {
        NSLog(@"正在连接中……");
    }
}

- (void)sendData:(NSData *)data {
    // 添加数据长度，用于处理分包问题
    NSMutableData *mData = [NSMutableData data];
    long long unsigned int dataLength = 8+(int)data.length;
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:8];
    [mData appendData:lengthData];
    [mData appendData:data];
    
    [self sendAction:mData];
}

- (void)realSend{
    if (_sendDataQueue.count == 0) {
        return;
    }
    MWeakSelf
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSData *data = weakSelf.sendDataQueue.firstObject;
        [weakSelf.sendDataQueue removeObjectAtIndex:0];
        [weakSelf sendAction:data];
        [weakSelf realSend];
    });
}

- (void)sendAction:(NSData *)data {
    if (_neSocket) {
        if (!_neSocket.isConnected) {
            NSLog(@"Socket 没有连接上");
            return;
        }
        [_neSocket writeData:data withTimeout:10 tag:0];
    } else {
        if (!_socketClient.isConnected) {
            NSLog(@"Socket 没有连接上");
            return;
        }
        [_socketClient writeData:data withTimeout:10 tag:0];
    }
}

- (void)resetData {
    _dataBuffer = [NSMutableData data];
}

@end
