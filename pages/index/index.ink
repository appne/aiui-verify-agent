<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b12: cue engine v3 + legacy probe clutter removed (user call).
// b11 device test: '💡考え中…' appeared instantly (good) but cues
// mostly ended in ERR timeout / session errors and the thinking
// state dragged on. Root causes addressed here:
//  (1) the 8 s prompt timeout only changed the DISPLAY — the prompt
//      kept living on the shared session, so the next cue prompted
//      a busy session and the runtime rejected it (session errors),
//      cascading. b12 uses a FRESH session per cue (bare create(),
//      the probe's known-fast path; instructions ride in the prompt
//      text, no systemPrompt create), prompts it exactly once, and
//      discards it — a timed-out session is never touched again.
//  (2) prompts fired mid-speech compete with the ASR loop for the
//      SoC and ingest ever-growing session context. b12 debounces:
//      a cue fires only after ~1.2 s of no new final, with just the
//      last 3 finals as context, i.e. into a pause, from scratch.
// Removed per user request: the legacy verification surface from
// the vrf-b2..b7 era (conn/fetch test lines + TEST button, loc /
// cam API probes, wx-key enumeration lines, camera shoot). Those
// APIs were verified long ago; kensho's job now is the ASR loop +
// LM cue. The LM probe stays (it gates the cue engine).
// vrf-b11: cue UX rework after the b10 device test — the wearer saw
// NO reaction because cues queued FIFO behind 17 finals and landed
// 35 s late. Now: a final instantly shows '💡考え中…', at most one
// cue prompt is in flight, newer finals coalesce into a single
// pending slot (latest only, never a backlog), the cue session is
// recreated every 6 prompts to reset accumulated context, and every
// LM call has a timeout so a hung create/prompt cannot stall the
// engine silently.
// vrf-b10: LM calls serialized + cue error text shown; layout slimmed
// (ASR/LM block moved under the title, probe clutter compressed) so
// the LM response line is actually readable on the glasses.
// vrf-b9: LanguageModel probe + LM-backed cue spike (2026-11-11).
// vrf-b8 proved the ASR loop: interim results stream in, one
// continuous=false session delivers many finals, restarts are rare.
// vrf-b9 adds two things:
//  (1) an on-load probe of the built-in LanguageModel API
//      (typeof / availability() / one timed Japanese prompt) shown
//      on the asr3/asr4 lines;
//  (2) when the probe passes, each ASR final is fed to a dedicated
//      LanguageModel session that returns at most one short cue
//      (term explanation / key point / suggested reply, or NONE),
//      shown on asr4 with its latency; asr5 shows the live interim
//      caption or the latest final. The Gemini /cue path on the
//      laptop listener stays as the fallback if LM is unavailable.
// Enter (tap) toggles the ASR loop as in vrf-b8.
export default {
  data: {
    build: 'vrf-b12',
    asr1: 'ASR: Enter = loop start/stop',
    asr2: '', asr3: '', asr4: '', asr5: ''
  },
  _asr: null,
  onLoad() {
    setTimeout(() => this.probeLm(), 800);
  },
  // ---- vrf-b8: ASR continuous-loop spike ----
  fmtT(ms) {
    const s = Math.floor(ms / 1000);
    return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0');
  },
  asrRender(lastDesc) {
    const a = this._asr;
    if (!a) return;
    const el = a.on ? Date.now() - a.t0 : a.frozenMs;
    const patch = {
      asr1: 'ASR #' + a.idx + ' ' + this.fmtT(el) +
        ' i' + a.interim + ' f' + a.finals +
        ' rst' + a.restarts + ' err' + a.errors +
        ' max' + (a.sessMax / 1000).toFixed(1) + 's',
      asr2: lastDesc || a.lastDesc || '',
      asr5: a.liveInterim
        ? '… ' + a.liveInterim.slice(0, 34)
        : (a.lastFinal ? '🗣 ' + a.lastFinal.slice(0, 34) : '')
    };
    this.setData(patch);
  },
  toggleAsr() {
    if (this._asr && this._asr.on) { this.asrStop('manual'); return; }
    if (typeof SpeechRecognition === 'undefined') {
      this.setData({ asr1: 'ASR: SpeechRecognition n/a' });
      return;
    }
    this._asr = {
      on: true, idx: 0, t0: Date.now(), frozenMs: 0, sessT0: 0,
      interim: 0, finals: 0, restarts: 0, errors: 0, consecErr: 0,
      sessMax: 0, hist: [], lastDesc: 'starting...', rec: null, fatal: '',
      finalsHist: [], lastFinal: '', liveInterim: ''
    };
    this.asrRender();
    this.asrStart();
  },
  asrStart() {
    const a = this._asr;
    if (!a || !a.on) return;
    let rec = null;
    try {
      rec = new SpeechRecognition();
    } catch (e) {
      a.errors++;
      a.lastDesc = 'ctor NG: ' + String(e).slice(0, 26);
      this.asrStop('ctor');
      return;
    }
    a.rec = rec;
    a.idx++;
    a.sessT0 = Date.now();
    try { rec.lang = 'ja-JP'; } catch (e) { /* ignore */ }
    try { rec.interimResults = true; } catch (e) { /* ignore */ }
    try { rec.continuous = false; } catch (e) { /* ignore */ }
    rec.onresult = (ev) => {
      try {
        let transcript = '';
        let isFinal = false;
        if (ev && typeof ev.transcript === 'string') {
          transcript = ev.transcript;
          isFinal = true;
        } else if (ev && ev.results && ev.results.length) {
          const last = ev.results[ev.results.length - 1];
          const alt = last && last[0];
          transcript = (alt && alt.transcript) || '';
          isFinal = !!(last && last.isFinal);
        }
        if (!transcript) return;
        a.consecErr = 0;
        if (isFinal) {
          a.finals++;
          a.hist.unshift(this.fmtT(Date.now() - a.t0) + ' ' + transcript.slice(0, 24));
          a.hist = a.hist.slice(0, 3);
          a.lastDesc = 'final: ' + transcript.slice(0, 26);
          a.finalsHist.push(transcript);
          if (a.finalsHist.length > 12) a.finalsHist.shift();
          a.lastFinal = transcript;
          a.liveInterim = '';
          this.cueRequest(transcript);
        } else {
          a.interim++;
          a.lastDesc = 'interim: ' + transcript.slice(0, 24);
          a.liveInterim = transcript;
        }
        this.asrRender();
      } catch (e) {
        a.lastDesc = 'onresult err';
        this.asrRender();
      }
    };
    rec.onerror = (ev) => {
      const msg = String((ev && (ev.error || ev.errMsg)) || 'unknown');
      a.errors++;
      a.consecErr++;
      a.lastDesc = 'err: ' + msg.slice(0, 30);
      if (msg === 'not-allowed' || msg === 'service-not-allowed' ||
          msg === 'language-not-supported') {
        a.fatal = msg;
      }
      this.asrRender();
    };
    rec.onend = () => {
      const dur = Date.now() - a.sessT0;
      if (dur > a.sessMax) a.sessMax = dur;
      if (!a.on) return;
      if (a.fatal) { this.asrStop('fatal ' + a.fatal); return; }
      if (Date.now() - a.t0 > 900000) { this.asrStop('CAP 15min'); return; }
      if (a.consecErr >= 5) { this.asrStop('errors x' + a.consecErr); return; }
      a.restarts++;
      this.asrRender();
      this.asrStart();
    };
    try {
      rec.start();
    } catch (e) {
      a.errors++;
      a.consecErr++;
      a.lastDesc = 'start NG: ' + String(e).slice(0, 24);
      if (a.consecErr >= 5) { this.asrStop('start NG x5'); return; }
      this.asrRender();
      setTimeout(() => this.asrStart(), 500);
    }
  },
  asrStop(reason) {
    const a = this._asr;
    if (!a) return;
    a.on = false;
    a.frozenMs = Date.now() - a.t0;
    try { if (a.rec) a.rec.stop(); } catch (e) { /* ignore */ }
    if (this._cue) {
      if (this._cue.timer) { clearTimeout(this._cue.timer); this._cue.timer = null; }
      this._cue.dirty = false;
      this._cue.seq++;
    }
    a.lastDesc = 'STOP (' + reason + ') ' + this.fmtT(a.frozenMs);
    this.asrRender();
  },
  // ---- vrf-b9: built-in LanguageModel probe + cue ----
  // The blog-documented API is Chrome Prompt-API shaped and may return
  // promises OR plain values depending on runtime version; lmThen
  // normalizes both. All failures land on the asr3/asr4 lines so the
  // glasses screen itself reports what the runtime supports.
  lmThen(fn) {
    try {
      const r = fn();
      if (r && typeof r.then === 'function') return r;
      return Promise.resolve(r);
    } catch (e) {
      return Promise.reject(e);
    }
  },
  // Serialize every LM call (probe/cue create+prompt) through one
  // chain: vrf-b9's cue prompt failed with a bare ERR while the probe
  // prompt may still have been in flight — the runtime may allow only
  // one active LM operation at a time.
  lmQueue(fn) {
    const prev = this._lmQ || Promise.resolve();
    const p = prev.then(() => this.lmThen(fn), () => this.lmThen(fn));
    this._lmQ = p.then(() => {}, () => {});
    return p;
  },
  probeLm() {
    if (typeof Promise === 'undefined') {
      this._lm = { ok: false };
      this.setData({ asr3: 'LM: no Promise in runtime' });
      return;
    }
    if (typeof LanguageModel === 'undefined') {
      this._lm = { ok: false };
      this.setData({ asr3: 'LM: undefined (no global)' });
      return;
    }
    this.setData({ asr3: 'LM: probing...' });
    this.lmThen(() => LanguageModel.availability()).then((avail) => {
      if (avail === 'unavailable') {
        this._lm = { ok: false };
        this.setData({ asr3: 'LM: avail=unavailable' });
        return;
      }
      const t0 = Date.now();
      this.lmQueue(() => LanguageModel.create()).then((session) => {
        this._lm = { ok: true, probe: session };
        this.lmQueue(() => session.prompt('「乾杯」を5文字以内で言い換えて。')).then((out) => {
          const sec = ((Date.now() - t0) / 1000).toFixed(1);
          this.setData({
            asr3: 'LM: avail=' + String(avail) + ' ' + sec + 's',
            asr4: 'LM: ' + String(out).trim().slice(0, 28)
          });
        }).catch((e) => {
          this.setData({ asr4: 'LM prompt ERR ' + String((e && e.message) || e).slice(0, 24) });
        });
      }).catch((e) => {
        this._lm = { ok: false };
        this.setData({ asr3: 'LM create ERR ' + String((e && e.message) || e).slice(0, 24) });
      });
    }).catch((e) => {
      this._lm = { ok: false };
      this.setData({ asr3: 'LM avail ERR ' + String((e && e.message) || e).slice(0, 24) });
    });
  },
  // ---- vrf-b12: cue engine v3 (debounce + disposable sessions) ----
  // A final instantly shows '💡考え中…' and (re)arms a debounce
  // timer; the cue fires only once speech pauses (~1.2 s with no new
  // final), so the LM never competes with the ASR loop mid-utterance
  // and never ingests a long backlog. Each cue uses a FRESH bare
  // create() session, prompts it exactly once with the last 3 finals
  // (instructions in the prompt text), then discards the session:
  // no accumulated context (the probe's 1.6 s condition), and a
  // timed-out session can never poison the next cue — b11's ERR
  // timeout → busy-session ERR cascade is structurally impossible.
  cueState() {
    if (!this._cue) this._cue = { busy: false, dirty: false, timer: null, seq: 0 };
    return this._cue;
  },
  lmTimeout(p, ms) {
    return Promise.race([
      p,
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))
    ]);
  },
  cueRequest(text) {
    if (!this._lm || !this._lm.ok) return;
    const c = this.cueState();
    this.setData({ asr4: '💡考え中…' });
    c.dirty = true;
    if (c.timer) clearTimeout(c.timer);
    c.timer = setTimeout(() => { c.timer = null; this.cueMaybe(); }, this.cueDebounceMs || 1200);
  },
  cueMaybe() {
    const c = this.cueState();
    if (c.busy || !c.dirty) return;
    if (!this._asr || !this._asr.on) { c.dirty = false; return; }
    this.cueFire();
  },
  cueFire() {
    const c = this.cueState();
    const a = this._asr;
    if (!a) { c.busy = false; return; }
    c.busy = true;
    c.dirty = false;
    const seq = ++c.seq;
    const t0 = Date.now();
    const convo = a.finalsHist.slice(-3).join('\n');
    const promptText = '会話補助のキュー係として、書き起こし（最新が最後）の最新発話への短いキュー（用語の短い説明・要点・返答の候補）を30文字以内で1つだけ返してください。出す価値がなければ NONE とだけ返してください。装飾記号は使わないでください。\n' + convo;
    this.lmTimeout(this.lmQueue(() => LanguageModel.create()), this.cueCreateTimeoutMs || 6000).then((sess) => {
      if (!sess) throw new Error('create-null');
      return this.lmTimeout(this.lmThen(() => sess.prompt(promptText)), this.cuePromptTimeoutMs || 15000).then((out) => {
        try { if (sess.destroy) sess.destroy(); } catch (e) { /* ignore */ }
        return out;
      }).catch((e) => {
        try { if (sess.destroy) sess.destroy(); } catch (e2) { /* ignore */ }
        throw e;
      });
    }).then((out) => {
      if (seq === c.seq) {
        const cue = String(out || '').trim().replace(/\s+/g, ' ').replace(/[*#`>]/g, '');
        const sec = ((Date.now() - t0) / 1000).toFixed(1);
        if (!cue || cue === 'NONE') {
          this.setData({ asr4: '💡なし (' + sec + 's)' });
        } else {
          this.setData({ asr4: '💡 ' + cue.slice(0, 30) + ' (' + sec + 's)' });
        }
      }
      this.cueDone();
    }).catch((e) => {
      if (seq === c.seq) {
        this.setData({ asr4: '💡 ERR ' + String((e && e.message) || e).slice(0, 22) });
      }
      this.cueDone();
    });
  },
  cueDone() {
    const c = this.cueState();
    c.busy = false;
    // Finals arrived while this cue was in flight: take one short
    // breath, then cue the newest context (never a backlog).
    if (c.dirty && this._asr && this._asr.on) {
      if (c.timer) clearTimeout(c.timer);
      c.timer = setTimeout(() => { c.timer = null; this.cueMaybe(); }, 600);
    }
  },
  onKeyUp(event) {
    if (event.code === 'Enter' || event.code === 'GlobalHook') {
      event.preventDefault();
      this.toggleAsr();
    }
    if (event.code === 'ArrowUp' || event.code === 'ArrowDown') {
      event.preventDefault();
    }
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Verify {{ build }}</text>
    <text class="line sub">{{ asr1 }}</text>
    <text class="line sub">{{ asr2 }}</text>
    <text class="line sub">{{ asr3 }}</text>
    <text class="line cue">{{ asr4 }}</text>
    <text class="line sub">{{ asr5 }}</text>
  </view>
</page>

<style>
.container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  height: 100vh;
  padding: 10px;
}

.title {
  color: #40FF5E;
  font-size: 26px;
  line-height: 30px;
  margin-bottom: 8px;
}

.line {
  color: #40FF5E;
  font-size: 22px;
  line-height: 26px;
}

.sub {
  color: #40FF5E99;
  font-size: 18px;
  line-height: 22px;
}

.cue {
  color: #40FF5E;
  font-size: 24px;
  line-height: 30px;
}

</style>
