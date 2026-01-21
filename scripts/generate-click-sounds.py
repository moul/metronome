#!/usr/bin/env python3
"""
Generate valid WAV audio files for metronome clicks.
Creates click.wav (800 Hz, 50ms sine burst) and accent.wav (1200 Hz, 50ms, louder).
"""

import struct
import math
import sys

def generate_sine_wave(frequency, duration_ms, sample_rate=44100, amplitude=0.8):
    """Generate a sine wave with the given parameters."""
    num_samples = int(sample_rate * duration_ms / 1000.0)
    samples = []

    for i in range(num_samples):
        # Calculate sine wave value
        t = i / sample_rate
        value = amplitude * math.sin(2.0 * math.pi * frequency * t)

        # Apply envelope (fade in/out to avoid clicks)
        envelope = 1.0
        fade_samples = int(sample_rate * 0.005)  # 5ms fade
        if i < fade_samples:
            envelope = i / fade_samples
        elif i > num_samples - fade_samples:
            envelope = (num_samples - i) / fade_samples

        value *= envelope

        # Convert to 16-bit PCM
        sample = int(value * 32767)
        samples.append(sample)

    return samples

def write_wav_file(filename, samples, sample_rate=44100):
    """Write samples to a WAV file."""
    num_samples = len(samples)
    num_channels = 1
    bits_per_sample = 16
    byte_rate = sample_rate * num_channels * bits_per_sample // 8
    block_align = num_channels * bits_per_sample // 8
    data_size = num_samples * num_channels * bits_per_sample // 8

    with open(filename, 'wb') as f:
        # RIFF header
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + data_size))  # File size - 8
        f.write(b'WAVE')

        # fmt chunk
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))  # fmt chunk size
        f.write(struct.pack('<H', 1))   # Audio format (1 = PCM)
        f.write(struct.pack('<H', num_channels))
        f.write(struct.pack('<I', sample_rate))
        f.write(struct.pack('<I', byte_rate))
        f.write(struct.pack('<H', block_align))
        f.write(struct.pack('<H', bits_per_sample))

        # data chunk
        f.write(b'data')
        f.write(struct.pack('<I', data_size))

        # Write sample data
        for sample in samples:
            f.write(struct.pack('<h', sample))

def main():
    # Generate click.wav - 800 Hz, 50ms, moderate amplitude
    print("Generating click.wav (800 Hz, 50ms)...")
    click_samples = generate_sine_wave(frequency=800, duration_ms=50, amplitude=0.6)
    write_wav_file('Metronome/Resources/click.wav', click_samples)
    print(f"  Created: Metronome/Resources/click.wav ({len(click_samples)} samples)")

    # Generate accent.wav - 1200 Hz, 50ms, louder
    print("Generating accent.wav (1200 Hz, 50ms, louder)...")
    accent_samples = generate_sine_wave(frequency=1200, duration_ms=50, amplitude=0.8)
    write_wav_file('Metronome/Resources/accent.wav', accent_samples)
    print(f"  Created: Metronome/Resources/accent.wav ({len(accent_samples)} samples)")

    print("\nDone! WAV files generated successfully.")
    return 0

if __name__ == '__main__':
    sys.exit(main())
