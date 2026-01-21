//
//  AudioEngine.h
//  Metronome
//
//  Objective-C audio engine with sample-accurate buffer scheduling.
//  Uses AVAudioEngine with timer-based pre-scheduling to avoid audio thread violations.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Callback block invoked on the main thread when a beat occurs
typedef void (^OnBeatCallback)(NSInteger beatNumber, BOOL isAccent);

/// AudioEngine provides sample-accurate metronome clicks using AVAudioEngine
///
/// Implementation follows Apple's Hello Metronome pattern:
/// - Timer-based scheduling (not audio callback scheduling)
/// - Pre-schedules 2-3 beats ahead using sample-accurate timing
/// - Uses lastRenderTime as master clock
/// - No locks, no allocation, no Swift/ObjC runtime in audio path
@interface AudioEngine : NSObject

/// The underlying AVAudioEngine instance
@property (nonatomic, strong, readonly) AVAudioEngine *engine;

/// Whether the metronome is currently playing
@property (nonatomic, assign, readonly, getter=isPlaying) BOOL playing;

/// Current BPM (beats per minute), valid range 30-300
@property (nonatomic, assign) NSInteger bpm;

/// Beats per bar (for accent pattern), default 4
@property (nonatomic, assign) NSInteger beatsPerBar;

/// Load click sounds from URLs
/// @param clickURL URL to the normal click sound (WAV file)
/// @param accentURL URL to the accent sound (WAV file)
/// @param error Output parameter for any loading errors
/// @return YES if sounds loaded successfully, NO otherwise
- (BOOL)loadClickSoundFromURL:(NSURL *)clickURL
                     accentURL:(NSURL *)accentURL
                         error:(NSError **)error;

/// Start the metronome
/// @return YES if started successfully, NO otherwise
- (BOOL)start:(NSError **)error;

/// Stop the metronome
- (void)stop;

/// Set callback to be notified of beats (dispatched to main thread)
/// @param callback Block to invoke on each beat
- (void)setOnBeatCallback:(nullable OnBeatCallback)callback;

@end

NS_ASSUME_NONNULL_END
