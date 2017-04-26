//
//  AWAudioEnginePlayer.m
//  AWAudioEnginePlayer
//
//  Created by Abe Wang on 2017/4/25.
//  Copyright © 2017年 AbeWang. All rights reserved.
//

#import "AWAudioEnginePlayer.h"
@import AVFoundation;

@interface AWAudioEnginePlayer ()
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioFile *audioFile;
@property (nonatomic, strong) AVAudioPlayerNode *playerNode;
@property (nonatomic, strong) AVAudioUnitEffect *eqNode;
@property (nonatomic, strong) AVAudioUnitReverb *reverbNode;
// Mixer 混音用
@property (nonatomic, strong) AVAudioFile *mixAudioFile;
@property (nonatomic, strong) AVAudioPlayerNode *mixPlayerNode;
@end

@implementation AWAudioEnginePlayer

- (instancetype)init
{
    if (self = [super init]) {
        self.engine = [[AVAudioEngine alloc] init];
        
        // 建立 PlayerNode 並加到 engine 中
        self.playerNode = [[AVAudioPlayerNode alloc] init];
        [self.engine attachNode:self.playerNode];
        
        // 須提供 EQ 的 AudioComponentDescription 來建立 EQ Effect Node 並加入到 engine 中
        // 補充：AVAudioUnit 繼承至 AVAudioNode
        self.eqNode = [[AVAudioUnitEffect alloc] initWithAudioComponentDescription:[self EQDescription]];
        [self.engine attachNode:self.eqNode];
        
        // 建立 ReverbNode 並加入到 engine 中
        // Reverb 是一種空間效果器
        // FactoryPreset : 可模擬不同空間尺寸大小
        // Wet/Dry mix : 控制聲音的乾濕度
        self.reverbNode = [[AVAudioUnitReverb alloc] init];
        [self.reverbNode loadFactoryPreset:AVAudioUnitReverbPresetMediumHall];
        self.reverbNode.wetDryMix = 40;
        [self.engine attachNode:self.reverbNode];
        
        // 建立混音用的 PlayerNode 並加入到 engine 中
        self.mixPlayerNode = [[AVAudioPlayerNode alloc] init];
        [self.engine attachNode:self.mixPlayerNode];
        
        // 將以上的這些 Node，透過 connect 來全部連接起來變成一個 chain
        // 補充：AVAudioEngine 在初始化時，會自己建立一個 MixerNode(mainMixerNode) 和 OutputNode，並會連接起來。所以我們輸出只要串接到 mixerNode 即可。
        // 補充：如果要用 mixer 混音的話，要使用另一組connect:to:fromBus:toBus:format:方法，選擇要接去 mixer 的哪一條 input bus
        [self.engine connect:self.playerNode to:self.eqNode format:nil];
        [self.engine connect:self.eqNode to:self.reverbNode format:nil];
        [self.engine connect:self.reverbNode to:self.engine.mainMixerNode fromBus:0 toBus:0 format:nil];
        [self.engine connect:self.mixPlayerNode to:self.engine.mainMixerNode fromBus:0 toBus:1 format:nil];
        
        // 設定 EQ 效果
        [self setEQPresetValue:0];
    }
    return self;
}

- (void)playWithLocalURL:(NSURL *)inLocalURL mixLocalURL:(NSURL *)inMixURL
{
    if ([self.engine isRunning]) {
        [self stop];
    }
    
    [self.engine startAndReturnError:nil];
    
    if (inLocalURL) {
        self.audioFile = [[AVAudioFile alloc] initForReading:inLocalURL error:nil];
        // 也可以用 AVAudioPCMBuffer 方式來 scheduleBuffer
        [self.playerNode scheduleFile:self.audioFile atTime:nil completionHandler:nil];
        [self.playerNode play];
    }
    if (inMixURL) {
        self.mixAudioFile = [[AVAudioFile alloc] initForReading:inMixURL error:nil];
        [self.mixPlayerNode scheduleFile:self.mixAudioFile atTime:nil completionHandler:nil];
        [self.mixPlayerNode play];
    }
}

- (void)pause
{
    [self.engine pause];
    [self.playerNode pause];
    [self.mixPlayerNode pause];
}

- (void)stop
{
    [self.engine stop];
    [self.playerNode stop];
    [self.mixPlayerNode stop];
}

- (void)setEQPresetValue:(NSInteger)EQPresetValue
{
    CFArrayRef presets;
    UInt32 size = sizeof(presets);
    OSStatus status = AudioUnitGetProperty(self.eqNode.audioUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &presets, &size);
    assert(status == noErr);
    
    if (EQPresetValue >= [(__bridge NSArray *)presets count]) {
        return;
    }
    
    AUPreset *preset = (AUPreset *)CFArrayGetValueAtIndex(presets, EQPresetValue);
    status = AudioUnitSetProperty(self.eqNode.audioUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, preset, sizeof(AUPreset));
    assert(status == noErr);
}

- (AudioComponentDescription)EQDescription
{
    AudioComponentDescription description;
    bzero(&description, sizeof(AudioComponentDescription));
    description.componentType = kAudioUnitType_Effect;
    description.componentSubType = kAudioUnitSubType_AUiPodEQ;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    description.componentFlags = 0;
    description.componentFlagsMask = 0;
    return description;
}

@end
