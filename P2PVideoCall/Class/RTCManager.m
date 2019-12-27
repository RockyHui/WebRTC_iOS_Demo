//
//  RTCManager.m
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/26.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import "RTCManager.h"

static NSString *const RTCSTUNServerURL1 = @"stun:stun.l.google.com:19302";
static NSString *const RTCSTUNServerURL2 = @"stun:23.21.150.121";

@interface RTCManager()<RTCPeerConnectionDelegate>

@property (nonatomic, strong) RTCPeerConnectionFactory *connectionFactory;
@property (nonatomic, strong) RTCPeerConnection *peerConnection;
@property (nonatomic, strong) RTCMediaStream *localStream;
@property (nonatomic, strong) RTCMediaStream *remoteMediaStream;
@property (nonatomic, strong) RTCCallbackLogger *loger;

@property (nonatomic, strong) NSMutableArray *candidateArr;

@end

@implementation RTCManager

- (instancetype)initWithDelegate:(id<RTCManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.candidateArr = [NSMutableArray array];
    }
    return self;
}

- (void)requestAudio {
    MWeakSelf
    //音频
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authStatus != AVAuthorizationStatusAuthorized) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (granted) {
                [weakSelf startLocalStream];
            }
        }];
    } else {
        [self startLocalStream];
    }
}

- (void)startLocalStream {
    _localStream = [self.connectionFactory mediaStreamWithStreamId:@"ARDAMS"];
    //音频
    RTCAudioTrack *audioTrack = [self.connectionFactory audioTrackWithTrackId:@"ARDAMSa0"];
    [_localStream addAudioTrack:audioTrack];
    //视频
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [deviceArray lastObject];
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        NSLog(@"相机访问受限");
    } else {
        if (device) {
            RTCVideoSource* videoSource = [self.connectionFactory videoSource];
            RTCCameraVideoCapturer *capturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
            AVCaptureDeviceFormat *format = [[RTCCameraVideoCapturer supportedFormatsForDevice:device] lastObject];
            [capturer startCaptureWithDevice:device format:format fps:25];
            
            RTCVideoTrack *videoTrack = [self.connectionFactory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];
            [_localStream addVideoTrack:videoTrack];
            if (self.delegate && [self.delegate respondsToSelector:@selector(didGetLocalCamera:)]) {
                [self.delegate didGetLocalCamera:capturer];
                //添加本地流
                [self bindLocalStream];
            }
        } else {
            NSLog(@"该设备不能打开摄像头");
        }
    }
}

- (void)callBackRTCStateWithKey:(NSString *)key infoValue:(NSString *)value {
    if (key == nil || value == nil) {
        return;
    }
    NSLog(@"%@: %@", key, value);
}

#pragma mark - Getter

- (RTCPeerConnectionFactory *)connectionFactory {
    if (!_connectionFactory) {
        RTCDefaultVideoEncoderFactory *encoder = [RTCDefaultVideoEncoderFactory new];
        RTCDefaultVideoDecoderFactory *decoder = [RTCDefaultVideoDecoderFactory new];
        RTCPeerConnectionFactory *connectionFactory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoder decoderFactory:decoder];
        _connectionFactory = connectionFactory;
    }
    return _connectionFactory;
}

- (RTCPeerConnection *)peerConnection {
    if (!_peerConnection) {
        NSMutableArray *ICEServers = [NSMutableArray array];
        [ICEServers addObject:[self defaultSTUNServer:RTCSTUNServerURL1]];
        [ICEServers addObject:[self defaultSTUNServer:RTCSTUNServerURL2]];
        
        RTCCallbackLogger *loger = [RTCCallbackLogger new];
        [loger start:^(NSString * _Nonnull log) {
            NSLog(@"%@", log);
        }];
        _loger = loger;
        
        RTCConfiguration *config = [RTCConfiguration new];
        config.iceServers = ICEServers;
//        config.bundlePolicy = RTCBundlePolicyMaxBundle;
//        config.tcpCandidatePolicy = RTCTcpCandidatePolicyDisabled;
//        config.continualGatheringPolicy = RTCContinualGatheringPolicyGatherOnce;
//        config.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
//        config.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
        
        _peerConnection = [self.connectionFactory peerConnectionWithConfiguration:config constraints:[self creatPeerConnectionConstraint] delegate:self];
    }
    return _peerConnection;
}

- (RTCMediaConstraints *)creatPeerConnectionConstraint {
    NSDictionary *params = @{
                             kRTCMediaConstraintsOfferToReceiveAudio : kRTCMediaConstraintsValueTrue,
                             kRTCMediaConstraintsOfferToReceiveVideo : kRTCMediaConstraintsValueTrue
                             };
    NSDictionary *params2 = @{
                              @"DtlsSrtpKeyAgreement" : @"true"
                              };
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:params optionalConstraints:params2];
    return constraints;
}

- (RTCIceServer *)defaultSTUNServer:(NSString *)stunURL {
    return [[RTCIceServer alloc] initWithURLStrings:@[stunURL]];
}

#pragma mark - Action
- (void)bindLocalStream {
    [self.peerConnection addStream:_localStream];
    NSLog(@"绑定本地数据流");
//    [self.peerConnection addTrack:_localStream.audioTracks.firstObject streamIds:@[_localStream.streamId]];
//    [self.peerConnection addTrack:_localStream.videoTracks.firstObject streamIds:@[_localStream.streamId]];
}

#pragma mark - RTCPeerConnectionDelegate


- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSString *keyWord = @"SignalingState";
    switch (stateChanged) {
        case RTCSignalingStateStable:
            [self callBackRTCStateWithKey:keyWord infoValue:@"STABLE"];
            break;
            
        case RTCSignalingStateHaveLocalOffer:
            [self callBackRTCStateWithKey:keyWord infoValue:@"HAVE_LOCAL_OFFER"];
            break;
            
        case RTCSignalingStateHaveLocalPrAnswer:
            [self callBackRTCStateWithKey:keyWord infoValue:@"HAVE_LOCAL_PRANSWER"];
            break;
            
        case RTCSignalingStateHaveRemoteOffer:
            [self callBackRTCStateWithKey:keyWord infoValue:@"HAVE_REMOTE_OFFER"];
            break;
            
        case RTCSignalingStateHaveRemotePrAnswer:
            [self callBackRTCStateWithKey:keyWord infoValue:@"HAVE_REMOTE_PRANSWER"];
            break;
            
        case RTCSignalingStateClosed:
            [self callBackRTCStateWithKey:keyWord infoValue:@"CLOSED"];
            break;
            
        default:
            break;
    }
}
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    if (stream == _localStream) {
        NSLog(@"本地流加入成功");
        return;
    }
    NSLog(@"远端流加入, video: %@ audio:%@", @(stream.videoTracks.count), @(stream.audioTracks.count));
    if (stream.videoTracks.count > 0) {
        RTCVideoTrack *remoteVideoTrack = stream.videoTracks.firstObject;
        _remoteMediaStream = stream;
        MWeakSelf
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didAddVideoTrack:)]) {
                [weakSelf.delegate didAddVideoTrack:remoteVideoTrack];
            }
        });
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {
    NSLog(@"有流移除");
}

- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
    NSLog(@"%s", __func__);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSString *keyWord = @"IceConnectionState";
    switch (newState) {
        case RTCIceConnectionStateNew:
            [self callBackRTCStateWithKey:keyWord infoValue:@"NEW"];
            break;
            
        case RTCIceConnectionStateChecking:
            [self callBackRTCStateWithKey:keyWord infoValue:@"CHECKING"];
            break;
            
        case RTCIceConnectionStateConnected:
            [self callBackRTCStateWithKey:keyWord infoValue:@"CONNECTED"];
            //            self.connectState = RTCState_ConnectSuccess;
            
            break;
            
        case RTCIceConnectionStateCompleted:
            [self callBackRTCStateWithKey:keyWord infoValue:@"COMPLETED"];
            break;
            
        case RTCIceConnectionStateFailed:
            [self callBackRTCStateWithKey:keyWord infoValue:@"FAILED"];
            //            self.connectState = RTCState_ConnectFail;
            break;
            
        case RTCIceConnectionStateDisconnected:
            [self callBackRTCStateWithKey:keyWord infoValue:@"DISCONNECTED"];
            break;
            
        case RTCIceConnectionStateClosed:
            [self callBackRTCStateWithKey:keyWord infoValue:@"CLOSED"];
            //            self.connectState = RTCState_DisConnect;
            break;
            
        default:
            NSLog(@"ICE State %@", @(newState));
            break;
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    if (newState == RTCIceGatheringStateComplete) {
        NSLog(@"ICE 收集完成");
        //        RTCSessionDescription *newSDP = [[RTCSessionDescription alloc] initWithType:self.answerSDP.type sdp:_answerSDPContent];
        
    }
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    NSLog(@"生成ICE Candidate:%@", candidate.sdpMid);
//    [_candidateArr addObject:candidate];
    //    _answerSDPContent = [_answerSDPContent stringByReplacingOccurrencesOfString:@"a=ice-ufrag" withString:[NSString stringWithFormat:@"a=%@\na=ice-ufrag", candidate.sdp]];
    MWeakSelf
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didCreateCandidate:)]) {
            [weakSelf.delegate didCreateCandidate:@[candidate]];
        }
    });
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel {
    NSLog(@"打开数据通道");
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    //
}


- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    //
}

#pragma mark - Public

- (void)tryStartLocalVide {
    MWeakSelf
    // 视频
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus != AVAuthorizationStatusAuthorized) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                [weakSelf requestAudio];
            }
        }];
    } else {
        [self requestAudio];
    }
}

- (void)setRemoteSDP:(RTCSessionDescription *)sdp {
    [self.peerConnection setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s %@", __func__, error.description);
        } else {
            NSLog(@"%s Success", __func__);
        }
    }];
}

- (void)createOfferSDP {
    MWeakSelf
    [self.peerConnection offerForConstraints:[self creatPeerConnectionConstraint] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s %@",__func__, error.description);
        } else {
            [weakSelf.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%s %@", __func__, error.description);
                } else {
                    NSLog(@"%s setLocalDescription Success!", __func__);
                }
            }];
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didCreateOfferSDP:)]) {
                [weakSelf.delegate didCreateOfferSDP:sdp];
            }
        }
    }];
}

- (void)createAnswerSDP {
    MWeakSelf
    [self.peerConnection answerForConstraints:[self creatPeerConnectionConstraint] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%s %@",__func__, error.description);
        } else {
            [weakSelf.peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%s %@", __func__, error.description);
                } else {
                    NSLog(@"%s setLocalDescription Success!", __func__);
                }
            }];
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(didCreateAnswerSDP:)]) {
                [weakSelf.delegate didCreateAnswerSDP:sdp];
            }
        }
    }];
}

- (void)addICEDidate:(RTCIceCandidate *)candidate {
    [self.peerConnection addIceCandidate:candidate];
}

- (void)resetData {
    [self.peerConnection close];
    
}

@end
