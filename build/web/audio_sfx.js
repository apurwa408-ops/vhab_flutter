// Web Audio API Procedural Synthesizer for V-Hab Upper-Limb Rehabilitation
// Zero external audio files required, ultra-low latency, crystal clear.
(function () {
  let ctx = null;

  function getAudioContext() {
    if (!ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) {
        ctx = new AudioCtx();
      }
    }
    if (ctx && ctx.state === 'suspended') {
      ctx.resume();
    }
    return ctx;
  }

  window.vhabAudio = {
    // Crisp pinch / grab click
    playPinch: function () {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;

      const osc = c.createOscillator();
      const gain = c.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(480, now);
      osc.frequency.exponentialRampToValueAtTime(880, now + 0.06);

      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.07);

      osc.connect(gain);
      gain.connect(c.destination);
      osc.start(now);
      osc.stop(now + 0.07);
    },

    // Release / drop snap
    playRelease: function () {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;

      const osc = c.createOscillator();
      const gain = c.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(520, now);
      osc.frequency.exponentialRampToValueAtTime(280, now + 0.08);

      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.08);

      osc.connect(gain);
      gain.connect(c.destination);
      osc.start(now);
      osc.stop(now + 0.08);
    },

    // Success chime / target cleared
    playSuccess: function () {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;

      const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
      notes.forEach((freq, idx) => {
        const osc = c.createOscillator();
        const gain = c.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq, now + idx * 0.06);

        gain.gain.setValueAtTime(0.18, now + idx * 0.06);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.06 + 0.25);

        osc.connect(gain);
        gain.connect(c.destination);
        osc.start(now + idx * 0.06);
        osc.stop(now + idx * 0.06 + 0.26);
      });
    },

    // Error / off-path / dropped target
    playError: function () {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;

      const osc = c.createOscillator();
      const gain = c.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(180, now);
      osc.frequency.linearRampToValueAtTime(110, now + 0.15);

      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.16);

      osc.connect(gain);
      gain.connect(c.destination);
      osc.start(now);
      osc.stop(now + 0.16);
    },

    // Steady hold rhythmic tick (freq rises with progress 0..1)
    playHoldTick: function (progress) {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;
      const p = Math.max(0, Math.min(1, progress || 0));

      const osc = c.createOscillator();
      const gain = c.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(440 + p * 440, now);

      gain.gain.setValueAtTime(0.12, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.05);

      osc.connect(gain);
      gain.connect(c.destination);
      osc.start(now);
      osc.stop(now + 0.05);
    },

    // Gesture matched fanfare
    playGestureMatch: function () {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;

      const freqs = [440, 554.37, 659.25, 880]; // A major
      freqs.forEach((freq, idx) => {
        const osc = c.createOscillator();
        const gain = c.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(freq, now + idx * 0.05);

        gain.gain.setValueAtTime(0.16, now + idx * 0.05);
        gain.gain.exponentialRampToValueAtTime(0.001, now + idx * 0.05 + 0.22);

        osc.connect(gain);
        gain.connect(c.destination);
        osc.start(now + idx * 0.05);
        osc.stop(now + idx * 0.05 + 0.23);
      });
    },

    // Level completed grand fanfare
    playLevelComplete: function () {
      const c = getAudioContext();
      if (!c) return;
      const now = c.currentTime;

      const chord1 = [523.25, 659.25, 783.99]; // C
      const chord2 = [587.33, 739.99, 880.00]; // D
      const chord3 = [659.25, 830.61, 987.77]; // E
      const chord4 = [1046.50, 1318.51, 1567.98]; // C high

      [chord1, chord2, chord3, chord4].forEach((chord, cIdx) => {
        const time = now + cIdx * 0.15;
        chord.forEach(freq => {
          const osc = c.createOscillator();
          const gain = c.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(freq, time);

          gain.gain.setValueAtTime(0.15, time);
          gain.gain.exponentialRampToValueAtTime(0.001, time + (cIdx === 3 ? 0.6 : 0.25));

          osc.connect(gain);
          gain.connect(c.destination);
          osc.start(time);
          osc.stop(time + (cIdx === 3 ? 0.65 : 0.26));
        });
      });
    }
  };
})();
