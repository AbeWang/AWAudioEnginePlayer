//
//  AWAudioEnginePlayer.h
//  AWAudioEnginePlayer
//
//  Created by Abe Wang on 2017/4/25.
//  Copyright © 2017年 AbeWang. All rights reserved.
//

@import Foundation;

@interface AWAudioEnginePlayer : NSObject
- (void)playWithLocalURL:(NSURL *)inLocalURL mixLocalURL:(NSURL *)inMixURL;
- (void)pause;
- (void)stop;
@end
