/* Sheetstorm Metronom — lokales WebAudio-Click.
 *
 * Konzept:
 *  - WebAudio-Lookahead-Scheduling (Chris Wilson, 2013): wir planen Clicks
 *    250 ms im Voraus und ziehen alle 25 ms nach. Verhindert GC-Jitter.
 *  - Akzent auf Schlag 1 mit hoeherem Pitch + leicht hoeherer Lautstaerke.
 *  - Subdivision: optional Achtel/Sechzehntel als leise Zwischen-Ticks.
 *
 * API (window.SheetstormMetronome):
 *   start({bpm, beatsPerBar, subdivision, accent, volume}) -> resumeAudioContext + sched
 *   stop()
 *   setBpm(bpm), setBeatsPerBar(n), setSubdivision('none'|'eighth'|'sixteenth')
 *   tap() -> nimmt Tap-Tempo, gibt aktuelles BPM zurueck
 *   isRunning -> bool
 */
(function () {
  let ac = null;
  let nextNoteTime = 0;
  let currentBeat = 0;        // 0 = naechster Schlag-1
  let currentSubBeat = 0;     // Zaehler innerhalb des Beats fuer Subdivision
  let timer = null;
  const lookaheadMs = 25;
  const scheduleAheadSec = 0.2;

  let bpm = 120;
  let beatsPerBar = 4;
  let subdivision = 'none';   // 'none' | 'eighth' | 'sixteenth'
  let accent = true;
  let volume = 0.5;
  let running = false;

  // Tap-Tempo
  let taps = [];

  function ensureAudio() {
    if (!ac) ac = new (window.AudioContext || window.webkitAudioContext)();
    if (ac.state === 'suspended') ac.resume();
    return ac;
  }

  function playClick(time, kind) {
    // kind: 'accent' | 'beat' | 'sub'
    const ctx = ensureAudio();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    let freq, dur, gainPeak;
    if (kind === 'accent') { freq = 1200; dur = 0.05; gainPeak = volume * 1.0; }
    else if (kind === 'beat') { freq = 800; dur = 0.04; gainPeak = volume * 0.7; }
    else /* sub */            { freq = 600; dur = 0.025; gainPeak = volume * 0.35; }
    osc.type = 'sine';
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, time);
    gain.gain.exponentialRampToValueAtTime(gainPeak, time + 0.005);
    gain.gain.exponentialRampToValueAtTime(0.0001, time + dur);
    osc.connect(gain).connect(ctx.destination);
    osc.start(time);
    osc.stop(time + dur + 0.01);
  }

  function nextTickStep() {
    // schreitet currentBeat / currentSubBeat passend zur subdivision
    let stepsPerBeat = 1;
    if (subdivision === 'eighth') stepsPerBeat = 2;
    else if (subdivision === 'sixteenth') stepsPerBeat = 4;
    const beatDur = 60.0 / bpm;
    nextNoteTime += beatDur / stepsPerBeat;
    currentSubBeat++;
    if (currentSubBeat >= stepsPerBeat) {
      currentSubBeat = 0;
      currentBeat = (currentBeat + 1) % beatsPerBar;
    }
  }

  function scheduleTicks() {
    if (!ac) return;
    while (nextNoteTime < ac.currentTime + scheduleAheadSec) {
      const time = nextNoteTime;
      const kind = (currentSubBeat === 0)
        ? (accent && currentBeat === 0 ? 'accent' : 'beat')
        : 'sub';
      playClick(time, kind);
      // Visual-Feedback per CustomEvent
      window.dispatchEvent(new CustomEvent('sheetstorm:metronome-tick', {
        detail: { beat: currentBeat, sub: currentSubBeat, kind, time },
      }));
      nextTickStep();
    }
  }

  window.SheetstormMetronome = {
    start({ bpm: b, beatsPerBar: bpb, subdivision: sd, accent: a, volume: v } = {}) {
      if (b !== undefined) bpm = b;
      if (bpb !== undefined) beatsPerBar = bpb;
      if (sd !== undefined) subdivision = sd;
      if (a !== undefined) accent = a;
      if (v !== undefined) volume = v;
      const ctx = ensureAudio();
      currentBeat = 0; currentSubBeat = 0;
      nextNoteTime = ctx.currentTime + 0.05;
      running = true;
      if (timer) clearInterval(timer);
      timer = setInterval(scheduleTicks, lookaheadMs);
    },
    stop() {
      running = false;
      if (timer) { clearInterval(timer); timer = null; }
    },
    setBpm(b) { bpm = Math.max(20, Math.min(300, +b || 120)); },
    setBeatsPerBar(n) { beatsPerBar = Math.max(1, Math.min(16, +n || 4)); },
    setSubdivision(s) { subdivision = s || 'none'; },
    setAccent(a) { accent = !!a; },
    setVolume(v) { volume = Math.max(0, Math.min(1, +v || 0)); },
    tap() {
      const now = performance.now();
      // alte Taps verwerfen, wenn > 2 s her
      taps = taps.filter(t => now - t < 2000);
      taps.push(now);
      if (taps.length < 2) return null;
      const intervals = [];
      for (let i = 1; i < taps.length; i++) intervals.push(taps[i] - taps[i - 1]);
      const avg = intervals.reduce((a, b) => a + b, 0) / intervals.length;
      const tappedBpm = Math.round(60000 / avg);
      bpm = Math.max(20, Math.min(300, tappedBpm));
      return bpm;
    },
    get isRunning() { return running; },
    get bpm() { return bpm; },
    get beatsPerBar() { return beatsPerBar; },
    get subdivision() { return subdivision; },
  };
})();
