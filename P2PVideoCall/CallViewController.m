//
//  CallViewController.m
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/18.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import "CallViewController.h"
#import <WebRTC/WebRTC.h>

#import "Utils.h"
#import "SocketClient.h"
#import "RTCManager.h"

@interface CallViewController ()<SocketClientDelegate, RTCManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@property (nonatomic, weak) RTCCameraPreviewView *localVideoView;//自己的画面
@property (nonatomic, weak) RTCEAGLVideoView *remoteVideoView;//对方的画面

@property (nonatomic, assign) uint16_t defaultPort;
@property (nonatomic, strong) SocketClient *socketClient;
@property (nonatomic, strong) RTCManager *rtcManager;


@end

@implementation CallViewController

- (void)dealloc {
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Call View";
    
    [self setupViews];
    [self setupDefaultData];
    [self startSocket];
    [self startRTCManager];
}

- (void)setupViews {
    RTCEAGLVideoView *remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.view insertSubview:_remoteVideoView = remoteVideoView belowSubview:_ipAddressLabel];
    
    RTCCameraPreviewView *localVideoView = [[RTCCameraPreviewView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-120, 80, 100, 150)];
    localVideoView.layer.borderWidth = 2;
    localVideoView.layer.borderColor = [UIColor blueColor].CGColor;
    
    [self.view addSubview:_localVideoView = localVideoView];
}

- (void)setupDefaultData {
    if (_isServer) {
        _defaultPort = arc4random()% 500+8000;
        _ipAddressLabel.text = [NSString stringWithFormat:@"%@:%@", [Utils getIPAddress:YES], @(_defaultPort)];
    } else {
        _ipAddressLabel.text = [Utils getIPAddress:YES];
    }
}


#pragma mark - Action

- (void)startSocket {
    _socketClient = [SocketClient new];
    _socketClient.delegate = self;
    if (_isServer) {
        [_socketClient startListenPort:_defaultPort];
    } else {
        [_socketClient startConnectTo:_desIPAddress port:_desPort];
    }
}


- (void)startRTCManager {
    _rtcManager = [[RTCManager alloc] initWithDelegate:self];
    [_rtcManager tryStartLocalVide];
}

#pragma mark - SocketClientDelegate

- (void)didConnectSuccess {
    if (!_isServer) {
        [_rtcManager createOfferSDP];
//        NSDictionary *dict = @{@"type": @"v=0o=-12250389772486519712INIP4127.0.0.1s=-t=00a=group:BUNDLE01a=msid-semantic:WMSm=audio9UDP/TLS/RTP/SAVPF11110310491020810610513110112113126c=INIP40.0.0.0a=rtcp:9INIP40.0.0.0a=ice-ufrag:2Qtpa=ice-pwd:+ESAiAu2Ldl7zG/wFem3Rnpla=ice-options:tricklerenominationa=fingerprint:sha-25611:FB:2D:0C:EA:DC:E7:E7:D1:D6:84:23:09:A5:86:1C:A2:90:89:28:ED:15:2C:2C:ED:1F:C1:D2:0F:5C:F3:94a=setup:actpassa=mid:0a=extmap:1urn:ietf:params:rtp-hdrext:ssrc-audio-levela=extmap:2http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01a=extmap:3urn:ietf:params:rtp-hdrext:sdes:mida=extmap:4urn:ietf:params:rtp-hdrext:sdes:rtp-stream-ida=extmap:5urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-ida=recvonlya=rtcp-muxa=rtpmap:111opus/48000/2a=rtcp-fb:111transport-cca=fmtp:111minptime=10;useinbandfec=1a=rtpmap:103ISAC/16000a=rtpmap:104ISAC/32000a=rtpmap:9G722/8000a=rtpmap:102ILBC/8000a=rtpmap:0PCMU/8000a=rtpmap:8PCMA/8000a=rtpmap:106CN/32000a=rtpmap:105CN/16000a=rtpmap:13CN/8000a=rtpmap:110telephone-event/48000a=rtpmap:112telephone-event/32000a=rtpmap:113telephone-event/16000a=rtpmap:126telephone-event/8000m=video9UDP/TLS/RTP/SAVPF96979899100101127124125c=INIP40.0.0.0a=rtcp:9INIP40.0.0.0a=ice-ufrag:2Qtpa=ice-pwd:+ESAiAu2Ldl7zG/wFem3Rnpla=ice-options:tricklerenominationa=fingerprint:sha-25611:FB:2D:0C:EA:DC:E7:E7:D1:D6:84:23:09:A5:86:1C:A2:90:89:28:ED:15:2C:2C:ED:1F:C1:D2:0F:5C:F3:94a=setup:actpassa=mid:1a=extmap:14urn:ietf:params:rtp-hdrext:toffseta=extmap:13http://www.webrtc.org/experiments/rtp-hdrext/abs-send-timea=extmap:12urn:3gpp:video-orientationa=extmap:2http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01a=extmap:11http://www.webrtc.org/experiments/rtp-hdrext/playout-delaya=extmap:6http://www.webrtc.org/experiments/rtp-hdrext/video-content-typea=extmap:7http://www.webrtc.org/experiments/rtp-hdrext/video-timinga=extmap:8http://tools.ietf.org/html/draft-ietf-avtext-framemarking-07a=extmap:9http://www.webrtc.org/experiments/rtp-hdrext/color-spacea=extmap:3urn:ietf:params:rtp-hdrext:sdes:mida=extmap:4urn:ietf:params:rtp-hdrext:sdes:rtp-stream-ida=extmap:5urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-ida=recvonlya=rtcp-muxa=rtcp-rsizea=rtpmap:96H264/90000a=rtcp-fb:96goog-remba=rtcp-fb:96transport-cca=rtcp-fb:96ccmfira=rtcp-fb:96nacka=rtcp-fb:96nackplia=fmtp:96level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c1fa=rtpmap:97rtx/90000a=fmtp:97apt=96a=rtpmap:98H264/90000a=rtcp-fb:98goog-remba=rtcp-fb:98transport-cca=rtcp-fb:98ccmfira=rtcp-fb:98nacka=rtcp-fb:98nackplia=fmtp:98level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01fa=rtpmap:99rtx/90000a=fmtp:99apt=98a=rtpmap:100VP8/90000a=rtcp-fb:100goog-remba=rtcp-fb:100transport-cca=rtcp-fb:100ccmfira=rtcp-fb:100nacka=rtcp-fb:100nackplia=rtpmap:101rtx/90000a=fmtp:101apt=100a=rtpmap:127red/90000a=rtpmap:124rtx/90000a=fmtp:124apt=127a=rtpmap:125ulpfec/90000"};
//        NSDictionary *msgDict = @{
//
//                                  @"lineIndex" : @(0),
//                                  @"mid" : @"audio",
//                                  @"sdp": @"candidate:614711952 1 udp 2122260223 10.254.238.157 62134 typ host generation 0 ufrag +ko9 network-id 1 network-cost 10",
//                                  };
//        NSDictionary *dict = @{
//                               @"type" : @"candidate",
//                               @"data" : @[msgDict],
//                               };
//        NSData *dta = [Utils convertDataFrom:dict];
//        [_socketClient sendData:dta];
    }
}

- (void)didLostConnection {
    [_rtcManager resetData];
}

- (void)didReceiveData:(NSData *)data {
    if (data.length == 0) {
        return;
    }
    NSDictionary *msgDict = [Utils convertDictFrom:data];
    NSLog(@"%@", msgDict);
    
    NSString *eventType = msgDict[@"type"];
    
    if ([eventType isEqualToString:@"offer"]) {
        NSString *sdpStr = msgDict[@"sdp"];
        if (sdpStr.length == 0) {
            return;
        }
        sdpStr = [Utils addSpaceAndNewline:sdpStr];
        RTCSessionDescription *offerSDP = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:sdpStr];
        [_rtcManager setRemoteSDP:offerSDP];
        [_rtcManager createAnswerSDP];
    } else if ([eventType isEqualToString:@"answer"]) {
        NSString *sdpStr = msgDict[@"sdp"];
        if (sdpStr.length == 0) {
            return;
        }
        sdpStr = [Utils addSpaceAndNewline:sdpStr];
        RTCSessionDescription *offerSDP = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:sdpStr];
        [_rtcManager setRemoteSDP:offerSDP];
    } else if ([eventType isEqualToString:@"candidate"]) {
        NSArray *tempArr = msgDict[@"data"];
        for (NSDictionary *dict in tempArr) {
            NSNumber *lineIndex = dict[@"lineIndex"];
            NSString *mid = dict[@"mid"];
            NSString *sdp = dict[@"sdp"];
            RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:lineIndex.intValue sdpMid:mid];
            [_rtcManager addICEDidate:candidate];
        }
    } else {
        NSLog(@"Unknown Event: %@", eventType);
    }
}

#pragma mark - RTCManagerDelegate

- (void)didGetLocalCamera:(RTCCameraVideoCapturer *)capture {
    if (capture) {
        _localVideoView.captureSession = capture.captureSession;
    }
}

- (void)didAddVideoTrack:(RTCVideoTrack *)videoTrack {
    [videoTrack addRenderer:_remoteVideoView];
}

- (void)didCreateOfferSDP:(RTCSessionDescription *)sdp {
    if (!_isServer) {
        NSLog(@"已生成offer SDP");
        NSDictionary *msgDict = @{
                                  @"type": @"offer",
                                  @"sdp" : [Utils removeSpaceAndNewline:sdp.sdp],
                                  };
        NSData *msgData = [Utils convertDataFrom:msgDict];
        [_socketClient sendData:msgData];
        NSLog(@"发送offer SDP");
    }
}

- (void)didCreateAnswerSDP:(RTCSessionDescription *)sdp {
    NSLog(@"已生成answer SDP");
    NSDictionary *msgDict = @{
                              @"type": @"answer",
                              @"sdp" : [Utils removeSpaceAndNewline:sdp.sdp],
                              };
    NSData *msgData = [Utils convertDataFrom:msgDict];
    [_socketClient sendData:msgData];
    NSLog(@"发送answer SDP");
}

- (void)didCreateCandidate:(NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"%@ 个Candidate", @(candidates.count));
    NSMutableArray *tempArr = [NSMutableArray array];
    for (RTCIceCandidate *one in candidates) {
        NSDictionary *msgDict = @{
                                  
                                  @"lineIndex" : @(one.sdpMLineIndex),
                                  @"mid" : one.sdpMid,
                                  @"sdp": [Utils removeSpaceAndNewline:one.sdp],
                                  };
        [tempArr addObject:msgDict];
    }
    NSDictionary *dict = @{
                           @"type" : @"candidate",
                           @"data" : tempArr,
                           };
    NSData *msgData = [Utils convertDataFrom:dict];
    [_socketClient sendData:msgData];
    NSLog(@"发送 Candidate");
}

@end
