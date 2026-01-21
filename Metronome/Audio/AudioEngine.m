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

#pragma mark - Scheduling

/// Schedule next beats using sample-accurate timing
/// Called from timer on high-priority queue (NOT audio thread)
/// CRITICAL: No locks, no allocation, no Swift/ObjC runtime calls
- (void)scheduleNextBeats {
    if (!_playing) {
        return;
    }

    // Get current audio time from player node
    // lastRenderTime is the master clock (more accurate than system time)
    AVAudioTime *lastRenderTime = [_playerNode lastRenderTime];
    if (!lastRenderTime || !lastRenderTime.isSampleTimeValid) {
        // Engine hasn't started rendering yet, try again next timer fire
        return;
    }

    // Calculate beat interval in samples
    double sampleRate = _audioFormat.sampleRate;
    double beatIntervalSeconds = 60.0 / (double)_bpm;
    AVAudioFramePosition beatIntervalFrames = (AVAudioFramePosition)(beatIntervalSeconds * sampleRate);

    // Initialize nextBeatFrame on first call
    if (_nextBeatFrame == 0) {
        // Start first beat slightly in the future to allow scheduling
        _nextBeatFrame = lastRenderTime.sampleTime + (AVAudioFramePosition)(sampleRate * 0.1); // 100ms ahead
    }

    // Pre-schedule beats up to 3 beat intervals ahead
    AVAudioFramePosition scheduleHorizon = lastRenderTime.sampleTime + (beatIntervalFrames * 3);

    while (_nextBeatFrame < scheduleHorizon) {
        // Determine if this is an accent beat (beat 1 of the bar)
        BOOL isAccent = (_currentBeat % _beatsPerBar) == 0;

        // Select buffer based on accent
        AVAudioPCMBuffer *buffer = isAccent ? _accentBuffer : _clickBuffer;

        // Create sample-accurate timing for this beat
        AVAudioTime *beatTime = [AVAudioTime timeWithSampleTime:_nextBeatFrame
                                                      atRate:sampleRate];

        // Schedule buffer at precise sample time
        // This is the critical call - scheduleBuffer:atTime: for sample accuracy
        [_playerNode scheduleBuffer:buffer
                             atTime:beatTime
                            options:0
                  completionHandler:nil];

        // Dispatch callback to main thread (async, non-blocking)
        if (_beatCallback) {
            NSInteger beatNumber = _currentBeat;
            BOOL accent = isAccent;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.beatCallback(beatNumber, accent);
            });
        }

        // Advance to next beat
        _currentBeat++;
        _nextBeatFrame += beatIntervalFrames;
    }
}

#pragma mark - Start/Stop

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

    // Create timer to drive scheduling
    // Timer fires at 2x beat rate to maintain 2-3 beats ahead
    double beatIntervalSeconds = 60.0 / (double)_bpm;
    double timerInterval = beatIntervalSeconds / 2.0;

    // Create dispatch source timer on high-priority queue
    dispatch_queue_t schedulerQueue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    _schedulerTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, schedulerQueue);

    if (!_schedulerTimer) {
        [self stop];
        if (error) {
            *error = [NSError errorWithDomain:@"AudioEngineErrorDomain"
                                         code:-3
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create scheduler timer"}];
        }
        return NO;
    }

    // Set timer to fire every timerInterval seconds
    uint64_t interval = (uint64_t)(timerInterval * NSEC_PER_SEC);
    dispatch_source_set_timer(_schedulerTimer,
                             dispatch_time(DISPATCH_TIME_NOW, 0),
                             interval,
                             interval / 10); // 10% leeway for battery efficiency

    // Set timer event handler
    __weak AudioEngine *weakSelf = self;
    dispatch_source_set_event_handler(_schedulerTimer, ^{
        [weakSelf scheduleNextBeats];
    });

    // Start timer
    dispatch_resume(_schedulerTimer);

    // Schedule initial beats immediately
    [self scheduleNextBeats];

    return YES;
}

- (void)stop {
    if (!_playing) {
        return;
    }

    _playing = NO;

    // Cancel and release scheduler timer
    if (_schedulerTimer) {
        dispatch_source_cancel(_schedulerTimer);
        _schedulerTimer = nil;
    }

    // Stop player node and engine
    [_playerNode stop];
    [_engine stop];
}

@end
