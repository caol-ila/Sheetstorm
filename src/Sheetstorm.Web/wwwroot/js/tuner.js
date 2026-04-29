/* Sheetstorm Tuner — lokale Pitch-Detection mit YIN-Algorithmus.
 *
 * Analysiert das Mikrofon-Signal und liefert {hz, confidence}-Updates.
 * Fenster: 2048 Samples bei 44.1 kHz → ~46 ms.
 * Glaettung: Median ueber 5 Frames + Confidence-Threshold.
 *
 * Nutzung:
 *   await SheetstormTuner.start({ onUpdate: ({hz, confidence}) => {...} })
 *   SheetstormTuner.stop()
 *
 * Mikrofon-Stream verlaesst NIE das Geraet — kein Audio wird hochgeladen.
 */
(function () {
  let ac = null;
  let stream = null;
  let analyser = null;
  let buffer = null;
  let rafId = null;
  let onUpdate = null;
  const recentHz = [];

  function yin(buf, sampleRate, threshold = 0.15) {
    // Standard-YIN nach de Cheveigne/Kawahara 2002
    const N = buf.length;
    const halfN = Math.floor(N / 2);
    const yinBuf = new Float32Array(halfN);

    // 1) Difference function
    for (let tau = 0; tau < halfN; tau++) {
      let sum = 0;
      for (let i = 0; i < halfN; i++) {
        const d = buf[i] - buf[i + tau];
        sum += d * d;
      }
      yinBuf[tau] = sum;
    }

    // 2) Cumulative-mean normalized
    yinBuf[0] = 1;
    let running = 0;
    for (let tau = 1; tau < halfN; tau++) {
      running += yinBuf[tau];
      yinBuf[tau] *= tau / running;
    }

    // 3) Absolute threshold
    let tauEstimate = -1;
    for (let tau = 2; tau < halfN; tau++) {
      if (yinBuf[tau] < threshold) {
        while (tau + 1 < halfN && yinBuf[tau + 1] < yinBuf[tau]) tau++;
        tauEstimate = tau;
        break;
      }
    }
    if (tauEstimate === -1) return { hz: 0, confidence: 0 };

    // 4) Parabolic interpolation
    const x0 = tauEstimate < 1 ? tauEstimate : tauEstimate - 1;
    const x2 = tauEstimate + 1 < halfN ? tauEstimate + 1 : tauEstimate;
    let betterTau;
    if (x0 === tauEstimate) betterTau = (yinBuf[tauEstimate] <= yinBuf[x2]) ? tauEstimate : x2;
    else if (x2 === tauEstimate) betterTau = (yinBuf[tauEstimate] <= yinBuf[x0]) ? tauEstimate : x0;
    else {
      const s0 = yinBuf[x0], s1 = yinBuf[tauEstimate], s2 = yinBuf[x2];
      betterTau = tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
    }
    const hz = sampleRate / betterTau;
    const confidence = 1 - yinBuf[tauEstimate];
    return { hz, confidence };
  }

  function median(a) {
    const s = [...a].sort((x, y) => x - y);
    return s[Math.floor(s.length / 2)];
  }

  async function start({ onUpdate: cb } = {}) {
    if (stream) await stop();
    onUpdate = cb;
    stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false } });
    ac = new (window.AudioContext || window.webkitAudioContext)({ sampleRate: 44100 });
    const src = ac.createMediaStreamSource(stream);
    analyser = ac.createAnalyser();
    analyser.fftSize = 2048;
    src.connect(analyser);
    buffer = new Float32Array(analyser.fftSize);

    function tick() {
      analyser.getFloatTimeDomainData(buffer);
      const { hz, confidence } = yin(buffer, ac.sampleRate, 0.15);
      // Glaettung
      if (hz > 0 && confidence > 0.85) {
        recentHz.push(hz);
        if (recentHz.length > 5) recentHz.shift();
        const m = median(recentHz);
        if (onUpdate) onUpdate({ hz: m, confidence });
      } else {
        if (onUpdate) onUpdate({ hz: 0, confidence });
        recentHz.length = 0;
      }
      rafId = requestAnimationFrame(tick);
    }
    rafId = requestAnimationFrame(tick);
  }

  async function stop() {
    if (rafId) cancelAnimationFrame(rafId);
    rafId = null;
    if (stream) {
      stream.getTracks().forEach(t => t.stop());
      stream = null;
    }
    if (ac) {
      try { await ac.close(); } catch { }
      ac = null;
    }
    analyser = null; buffer = null; onUpdate = null;
    recentHz.length = 0;
  }

  window.SheetstormTuner = { start, stop };
})();
