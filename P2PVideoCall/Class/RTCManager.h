//
//  RTCManager.h
//  P2PVideoCall
//
//  Created by Rocky Hui on 2019/12/26.
//  Copyright © 2019 Rocky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RTCManagerDelegate <NSObject>

- (void)didGetLocalCamera:(RTCCameraVideoCapturer *)capture;
- (void)didAddVideoTrack:(RTCVideoTrack *)videoTrack;
- (void)didCreateOfferSDP:(RTCSessionDescription *)sdp;
- (void)didCreateAnswerSDP:(RTCSessionDescription *)sdp;
- (void)didCreateCandidate:(NSArray<RTCIceCandidate *> *)candidates;

@end

@interface RTCManager : NSObject

@property (weak, nonatomic) id<RTCManagerDelegate> delegate;

- (instancetype)initWithDelegate:(id<RTCManagerDelegate>)delegate;

- (void)tryStartLocalVide;
- (void)setRemoteSDP:(RTCSessionDescription *)sdp;
- (void)createOfferSDP;
- (void)createAnswerSDP;
- (void)addICEDidate:(RTCIceCandidate *)candidate;
- (void)resetData;

@end

NS_ASSUME_NONNULL_END
