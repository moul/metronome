//
//  AudioEngine.m
//  Metronome
//
//  Sample-accurate buffer scheduling implementation.
//  Follows Apple's Hello Metronome pattern for real-time safe audio.
//

#import "AudioEngine.h"

// Private interface
@interface AudioEngine ()

// Audio components
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioPlayerNode *playerNode;
@property (nonatomic, strong) AVAudioFormat *audioFormat;

// Pre-loaded buffers (allocated once, reused for entire session)
@property (nonatomic, strong) AVAudioPCMBuffer *clickBuffer;
@property (nonatomic, strong) AVAudioPCMBuffer *accentBuffer;

// Scheduling state
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) NSInteger currentBeat;
@property (nonatomic, assign) AVAudioFramePosition nextBeatFrame;
@property (nonatomic, strong, nullable) dispatch_source_t schedulerTimer;

// Callback
@property (nonatomic, copy, nullable) OnBeatCallback beatCallback;

@end

@implementation AudioEngine

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize default values
        _bpm = 120;
        _beatsPerBar = 4;
        _playing = NO;
        _currentBeat = 0;
        _nextBeatFrame = 0;

        // Create audio engine and player node
        _engine = [[AVAudioEngine alloc] init];
        _playerNode = [[AVAudioPlayerNode alloc] init];

        [_engine attachNode:_playerNode];

        // Audio format: 44.1 kHz, mono, float32
        // Using standard format that matches most WAV files
        _audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                        sampleRate:44100.0
                                                          channels:1
                                                       interleaved:NO];

        // Connect player node to main mixer
        [_engine connect:_playerNode
                      to:_engine.mainMixerNode
                  format:_audioFormat];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

#pragma mark - Sound Loading

- (BOOL)loadClickSoundFromURL:(NSURL *)clickURL
                     accentURL:(NSURL *)accentURL
                         error:(NSError **)error {

    // Load click sound
    AVAudioFile *clickFile = [[AVAudioFile alloc] initForReading:clickURL error:error];
    if (!clickFile) {
        return NO;
    }

    // Load accent sound
    AVAudioFile *accentFile = [[AVAudioFile alloc] initForReading:accentURL error:error];
    if (!accentFile) {
        return NO;
    }

    // Create buffers with capacity for the entire file
    // These buffers are pre-allocated and reused (no allocation in audio path)
    AVAudioFrameCount clickFrameCount = (AVAudioFrameCount)clickFile.length;
    AVAudioFrameCount accentFrameCount = (AVAudioFrameCount)accentFile.length;

    _clickBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_audioFormat
                                                 frameCapacity:clickFrameCount];
    if (!_clickBuffer) {
        if (error) {
            *error = [NSError errorWithDomain:@"AudioEngineErrorDomain"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create click buffer"}];
        }
        return NO;
    }

    _accentBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_audioFormat
                                                   frameCapacity:accentFrameCount];
    if (!_accentBuffer) {
        if (error) {
            *error = [NSError errorWithDomain:@"AudioEngineErrorDomain"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create accent buffer"}];
        }
        return NO;
    }

    // Read files into buffers
    // Note: If file format doesn't match audioFormat, AVAudioFile will convert automatically
    if (![clickFile readIntoBuffer:_clickBuffer error:error]) {
        return NO;
    }

    if (![accentFile readIntoBuffer:_accentBuffer error:error]) {
        return NO;
    }

    return YES;
}

#pragma mark - Property Accessors

- (void)setBpm:(NSInteger)bpm {
    // Validate BPM range
    if (bpm < 30) {
        _bpm = 30;
    } else if (bpm > 300) {
        _bpm = 300;
    } else {
        _bpm = bpm;
    }

    // If playing, BPM change will affect next scheduled beats
    // No special handling needed - scheduler will use new BPM value
}

#pragma mark - Callback

- (void)setOnBeatCallback:(OnBeatCallback)callback {
    _beatCallback = callback;
}

#pragma mark - Start/Stop (scheduling logic in Task 3)

- (BOOL)start:(NSError **)error {
    if (_playing) {
        return YES;
    }

    if (!_clickBuffer || !_accentBuffer) {
        if (error) {
            *error = [NSError errorWithDomain:@"AudioEngineErrorDomain"
                                         code:-2
                                     userInfo:@{NSLocalizedDescriptionKey: @"Sounds not loaded. Call loadClickSoundFromURL:accentURL:error: first."}];
        }
        return NO;
    }

    // Start the engine
    if (![_engine startAndReturnError:error]) {
        return NO;
    }

    // Start the player node
    [_playerNode play];

    // Initialize scheduling state
    _playing = YES;
    _currentBeat = 0;
    _nextBeatFrame = 0;

    // Scheduling logic will be added in Task 3
    // For now, just mark as playing

    return YES;
}

- (void)stop {
    if (!_playing) {
        return;
    }

    _playing = NO;

    // Scheduling cleanup will be added in Task 3

    // Stop player node and engine
    [_playerNode stop];
    [_engine stop];
}

@end
