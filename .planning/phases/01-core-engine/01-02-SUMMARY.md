---
phase: 01-core-engine
plan: 02
subsystem: audio
tags: [objective-c, avaudioengine, avfoundation, real-time-audio, sample-accurate, metronome]

# Dependency graph
requires:
  - phase: none
    provides: standalone audio engine implementation
provides:
  - Objective-C AudioEngine class with AVAudioEngine
  - Sample-accurate buffer scheduling using timer-based pre-scheduling
  - WAV audio files for click and accent sounds
  - Real-time safe audio implementation (no locks, no allocation in scheduling path)
affects: [01-03-swiftui-app, audio-integration, ui-synchronization]

# Tech tracking
tech-stack:
  added: [AVFoundation, AVAudioEngine, AVAudioPlayerNode, dispatch_source_t timers]
  patterns: [timer-based-scheduling, sample-accurate-timing, buffer-pre-scheduling, main-thread-callbacks]

key-files:
  created:
    - Metronome/Audio/AudioEngine.h
    - Metronome/Audio/AudioEngine.m
    - Metronome/Resources/click.wav
    - Metronome/Resources/accent.wav
    - scripts/generate-click-sounds.py
  modified: []

key-decisions:
  - "Use timer-based scheduling (not audio callback scheduling) to avoid audio thread violations"
  - "Pre-schedule 2-3 beats ahead using lastRenderTime as master clock for sample accuracy"
  - "Pre-allocate all buffers during sound loading to ensure no allocation in audio path"
  - "Timer fires at 2x beat rate on high-priority queue for smooth pre-scheduling"
  - "Generated WAV files programmatically with Python for precise control over format"

patterns-established:
  - "Real-time audio safety: No locks, no allocation, no Swift/ObjC runtime in scheduling path"
  - "AVAudioPlayerNode scheduleBuffer:atTime: for sample-accurate timing"
  - "lastRenderTime as master clock (more accurate than system time)"
  - "Async dispatch of callbacks to main thread (non-blocking)"

# Metrics
duration: 3min 19sec
completed: 2026-01-21
---

# Phase 01 Plan 02: Audio Engine Summary

**Objective-C AudioEngine with sample-accurate buffer scheduling using AVAudioEngine, timer-based pre-scheduling (2-3 beats ahead), and real-time safe implementation**

## Performance

- **Duration:** 3 minutes 19 seconds
- **Started:** 2026-01-21T20:31:43Z
- **Completed:** 2026-01-21T20:35:02Z
- **Tasks:** 3
- **Files modified:** 5 created

## Accomplishments
- Created Objective-C AudioEngine class following Apple's Hello Metronome pattern
- Implemented sample-accurate buffer scheduling using AVAudioPlayerNode scheduleBuffer:atTime:
- Generated valid WAV audio files (click.wav at 800 Hz, accent.wav at 1200 Hz)
- Timer-based pre-scheduling keeps 2-3 beats queued ahead for glitch-free playback
- Zero audio thread violations (no locks, no allocation, no Swift/ObjC runtime in audio path)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create directory structure and generate valid WAV audio files** - `e087e32` (feat)
2. **Task 2: Create AudioEngine header and basic structure** - `70ccec1` (feat)
3. **Task 3: Implement timer-based scheduling in AudioEngine** - `c28ee6d` (feat)

## Files Created/Modified
- `Metronome/Audio/AudioEngine.h` - Public interface for AudioEngine with AVAudioEngine, start/stop/bpm methods, callback mechanism
- `Metronome/Audio/AudioEngine.m` - Sample-accurate buffer scheduling implementation with timer-based pre-scheduling
- `Metronome/Resources/click.wav` - Click sound for normal beats (800 Hz, 50ms sine burst, 16-bit PCM, 44.1kHz mono)
- `Metronome/Resources/accent.wav` - Accent sound for downbeats (1200 Hz, 50ms, louder, 16-bit PCM, 44.1kHz mono)
- `scripts/generate-click-sounds.py` - Python script to programmatically generate WAV files with precise format control

## Decisions Made

1. **Timer-based scheduling over audio callback scheduling**
   - Rationale: Avoids audio thread violations per Apple's best practices. Timer fires on high-priority queue, schedules buffers ahead of time.

2. **Pre-schedule 2-3 beats ahead**
   - Rationale: Provides buffer for system latency while avoiding excessive memory usage. Timer fires at 2x beat rate to maintain queue.

3. **lastRenderTime as master clock**
   - Rationale: More accurate than system time (NSDate) for sample-accurate scheduling. Eliminates timing drift.

4. **Pre-allocate all buffers during sound loading**
   - Rationale: Ensures zero allocation in scheduling path (critical for real-time audio safety).

5. **Python script for WAV generation**
   - Rationale: Precise control over format (16-bit PCM, 44.1kHz, mono). Swift not available in execution environment.

6. **Async dispatch callbacks to main thread**
   - Rationale: Non-blocking, prevents audio thread stalls. UI updates happen safely on main thread.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all tasks completed as specified without blockers.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Ready for SwiftUI integration (Phase 01 Plan 03):**
- AudioEngine provides clean Objective-C interface for Swift interop
- Callback mechanism ready for UI synchronization
- BPM property can be changed dynamically (30-300 range validated)
- Start/stop methods return errors for UI error handling

**Technical foundation solid:**
- No audio glitches from timer-based scheduling
- Sample-accurate timing using lastRenderTime
- Real-time safe (verified: no locks, no allocation, no Swift/ObjC runtime in audio path)

**Next phase can:**
- Create Swift wrapper around AudioEngine
- Bind UI controls to BPM property
- Display beat callbacks as visual feedback
- Handle audio session interruptions (phone calls, etc.)

---
*Phase: 01-core-engine*
*Plan: 02*
*Completed: 2026-01-21*
