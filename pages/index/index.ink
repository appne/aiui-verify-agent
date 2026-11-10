<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
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
// Enter toggles the ASR loop as in vrf-b8; shoot still runs once
// from onLoad.
export default {
  data: {
    build: 'vrf-b11',
    connType: 'tap: test',
    line1: 'tap: fetch test',
    line2: 'Enter = run fetch',
    probe: 'loc: ...',
    cam: 'cam: ...',
    shot: 'shot: idle',
    shot2: '',
    locRes: '',
    asr1: 'ASR: Enter = loop start/stop',
    asr2: '', asr3: '', asr4: '', asr5: '',
    k1: '', k2: '', k3: '', k4: '', k5: ''
  },
  _lastRun: 0,
  _asr: null,
  onLoad() {
    this.refreshConn();
    this.probeApis();
    setTimeout(() => this.probeLm(), 800);
    setTimeout(() => this.shoot(), 2500);
  },
  // Camera test (vrf-b6): the page now HAS a <camera> component.
  // Create the context, dump its full method list into the k-lines,
  // then takePhoto with callback + promise + 12s timeout reporting.
  shoot() {
    const setShot = (s, s2) => this.setData({ shot: s, shot2: s2 || '' });
    try {
      if (!wx.media || typeof wx.media.createCameraContext !== 'function') {
        setShot('shot: no createCameraContext');
        return;
      }
      const ctx = wx.media.createCameraContext();
      if (!ctx) { setShot('shot: ctx is null'); return; }
      this._camCtx = ctx;
      const NOISE = ['__defineGetter__', '__defineSetter__', '__lookupGetter__', '__lookupSetter__', '__proto__', 'constructor', 'hasOwnProperty', 'isPrototypeOf', 'propertyIsEnumerable', 'toLocaleString', 'toString', 'valueOf'];
      let names = [];
      try {
        let o = ctx;
        for (let i = 0; i < 3 && o; i++) {
          names = names.concat(Object.getOwnPropertyNames(o));
          o = Object.getPrototypeOf(o);
        }
        names = Array.from(new Set(names)).filter((n) => NOISE.indexOf(n) === -1).sort();
      } catch (e) { /* keep empty */ }
      const joined = names.join(',');
      this.setData({
        k1: 'M:' + joined.slice(0, 36),
        k2: joined.slice(36, 74),
        k3: joined.slice(74, 112),
        k4: joined.slice(112, 150),
        k5: joined.slice(150, 188)
      });
      if (typeof ctx.takePhoto !== 'function') {
        setShot('ctx: no takePhoto fn');
        return;
      }
      setShot('shooting (tiny comp)...');
      let done = false;
      const finish = (a, b) => { if (!done) { done = true; setShot(a, b); } };
      setTimeout(() => finish('PHOTO TIMEOUT', 'no result in 12s'), 12000);
      const describe = (r) => {
        try {
          const d = r && r.data;
          const t = Object.prototype.toString.call(d);
          const len = d && (d.byteLength != null ? d.byteLength : (d.length != null ? d.length : (d.size != null ? d.size : '?')));
          return t.replace('[object ', '').replace(']', '') + ' ' + len + 'B ' + ((r && r.mimeType) || '');
        } catch (e) { return 'desc err'; }
      };
      const ret = ctx.takePhoto({ quality: 'high' });
      if (ret && typeof ret.then === 'function') {
        ret.then((r) => finish('PHOTO OK ' + ((r && r.data && r.data.byteLength) || 0) + 'B', ''))
          .catch((e) => finish('PHOTO FAIL (promise)', String((e && e.errMsg) || e).slice(0, 38)));
      } else {
        finish('takePhoto: no promise', 'ret=' + Object.prototype.toString.call(ret));
      }
    } catch (e) {
      setShot('shot exception', String(e).slice(0, 38));
    }
  },
  refreshConn() {
    let t = 'unknown';
    try {
      if (typeof navigator !== 'undefined' && navigator.connection) {
        t = navigator.connection.type || 'none';
        if (navigator.connection.effectiveType) {
          t += '/' + navigator.connection.effectiveType;
        }
      }
    } catch (e) {
      t = 'err';
    }
    this.setData({ connType: t });
  },
  // API-surface probe: which location APIs does this runtime actually
  // expose? zaisen found wx.getLocation missing on the real glasses
  // (footer "loc n/a"); this enumerates wx and tries the candidates.
  probeApis() {
    const has = (o, k) => {
      try { return !!o && typeof o[k] === 'function'; } catch (e) { return false; }
    };
    const gL = has(wx, 'getLocation');
    const gF = has(wx, 'getFuzzyLocation');
    const oLC = has(wx, 'onLocationChange');
    const sLU = has(wx, 'startLocationUpdate');
    let navGeo = false;
    try {
      navGeo = typeof navigator !== 'undefined' && !!navigator.geolocation &&
        typeof navigator.geolocation.getCurrentPosition === 'function';
    } catch (e) { /* no geolocation */ }
    let rk = '-';
    try {
      if (typeof rokid !== 'undefined') rk = 'rokid';
      else if (typeof Rokid !== 'undefined') rk = 'Rokid';
      else if (typeof yoda !== 'undefined') rk = 'yoda';
    } catch (e) { /* none */ }
    this.setData({
      probe: 'loc: gL' + (gL ? 'Y' : '-') + ' gF' + (gF ? 'Y' : '-') +
        ' oLC' + (oLC ? 'Y' : '-') + ' sLU' + (sLU ? 'Y' : '-') +
        ' navGeo' + (navGeo ? 'Y' : '-') + ' g:' + rk
    });
    // Enumerate the wx keys, chunked into lines of ~34 chars.
    let keys = [];
    try { keys = Object.keys(wx || {}).sort(); } catch (e) { /* none */ }
    const lines = [];
    let cur = 'wx(' + keys.length + '):';
    for (const k of keys) {
      if ((cur + ' ' + k).length > 34 && cur.length > 10) { lines.push(cur); cur = k; }
      else cur += (cur ? ' ' : '') + k;
    }
    if (cur) lines.push(cur);
    // vrf-b4: enumerate subkeys of every object-valued wx key
    // (wx.media, wx.speech, ...) into the k-lines.
    const objDesc = [];
    for (const k of keys) {
      try {
        const v = wx[k];
        if (v && typeof v === 'object') {
          objDesc.push(k + '{' + Object.keys(v).sort().join(',') + '}');
        }
      } catch (e) { /* ignore */ }
    }
    let joined = objDesc.join(' ') || 'no object values';
    const toks = [];
    for (const t of joined.split(' ')) {
      if (t.length <= 36) toks.push(t);
      else for (let i = 0; i < t.length; i += 36) toks.push(t.slice(i, i + 36));
    }
    const olines = [];
    let ocur = 'obj:';
    for (const t of toks) {
      if ((ocur + ' ' + t).length > 38 && ocur.length > 5) { olines.push(ocur); ocur = t; }
      else ocur += (ocur ? ' ' : '') + t;
    }
    if (ocur) olines.push(ocur);
    const patch = {};
    for (let i = 0; i < 5; i++) patch['k' + (i + 1)] = olines[i] || '';
    if (olines.length > 5) patch.k5 = (patch.k5 + ' +more').slice(0, 40);
    this.setData(patch);
    // Camera/media API candidates (vrf-b3): can an AIUI agent shoot?
    const mark = (b) => (b ? 'Y' : '-');
    const hasO = (o, k) => {
      try { return !!o && typeof o[k] !== 'undefined'; } catch (e) { return false; }
    };
    this.setData({
      cam: 'cam: cCC' + mark(has(wx, 'createCameraContext')) +
        ' chI' + mark(has(wx, 'chooseImage')) +
        ' chM' + mark(has(wx, 'chooseMedia')) +
        ' tP' + mark(has(wx, 'takePhoto')) +
        ' svI' + mark(has(wx, 'saveImageToPhotosAlbum')) +
        ' scC' + mark(has(wx, 'scanCode')) +
        ' gRM' + mark(has(wx, 'getRecorderManager')) +
        ' cVC' + mark(has(wx, 'createVideoContext'))
    });
    // Live attempts, only where the API exists.
    const setRes = (s) => this.setData({ locRes: s });
    if (gL) {
      try {
        wx.getLocation({
          success: (r) => setRes('gL ok ' + r.latitude + ',' + r.longitude),
          fail: (e) => setRes('gL fail ' + ((e && e.errMsg) || '').slice(0, 22))
        });
      } catch (e) { setRes('gL exception'); }
    }
    if (navGeo) {
      setRes('geo: waiting...');
      let answered = false;
      try {
        navigator.geolocation.getCurrentPosition(
          (p) => { answered = true; setRes('geo ok ' + p.coords.latitude.toFixed(4) + ',' + p.coords.longitude.toFixed(4)); },
          (e) => { answered = true; setRes('geo err ' + (e && e.code)); },
          { timeout: 6000 }
        );
        setTimeout(() => { if (!answered) setRes('geo: timeout'); }, 7000);
      } catch (e) { setRes('geo exception'); }
    }
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
      finalsHist: [], cueSeq: 0, lastFinal: '', liveInterim: ''
    };
    if (this._lm && this._lm.ok) this.cueSession();
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
    if (this._cue) this._cue.pending = null;
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
  // ---- vrf-b11: cue engine (latest-only coalescing) ----
  // At most one cue prompt is ever in flight. A final that arrives
  // while busy overwrites the single pending slot; when the flight
  // lands, the pending (newest) utterance fires immediately. The cue
  // line reacts instantly ('💡考え中…') so the wearer always sees
  // the glasses respond to speech, even before the cue itself lands.
  cueState() {
    if (!this._cue) this._cue = { busy: false, pending: null, sess: null, served: 0 };
    return this._cue;
  },
  lmTimeout(p, ms) {
    return Promise.race([
      p,
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))
    ]);
  },
  cueSession() {
    const c = this.cueState();
    if (c.sess && c.served < 6) return Promise.resolve(c.sess);
    const sys = 'あなたは会話の補助キュー係です。書き起こしを受け取り、最新の発話への短いキュー（用語の短い説明・要点・返答の候補）を30文字以内で1つだけ返してください。出す価値がなければ NONE とだけ返してください。';
    const mk = (opts) => this.lmTimeout(this.lmQueue(() => LanguageModel.create(opts)), 5000);
    return mk({ systemPrompt: sys }).catch(() => mk(undefined)).then((s) => {
      if (!s) return null;
      if (c.sess && c.sess !== s) { try { if (c.sess.destroy) c.sess.destroy(); } catch (e) { /* ignore */ } }
      c.sess = s;
      c.served = 0;
      return s;
    }).catch(() => null);
  },
  cueRequest(text) {
    if (!this._lm || !this._lm.ok) return;
    const c = this.cueState();
    this.setData({ asr4: '💡考え中…' });
    if (c.busy) { c.pending = text; return; }
    this.cueFire();
  },
  cueFire() {
    const c = this.cueState();
    const a = this._asr;
    if (!a) { c.busy = false; return; }
    c.busy = true;
    c.served++;
    const t0 = Date.now();
    this.cueSession().then((sess) => {
      if (!sess) {
        this.setData({ asr4: '💡 (LMなし)' });
        this.cueDone();
        return;
      }
      const convo = a.finalsHist.slice(-5).join('\n');
      this.lmTimeout(this.lmThen(() => sess.prompt('会話の書き起こし（最新が最後）:\n' + convo)), 8000).then((out) => {
        let cue = String(out || '').trim().replace(/\s+/g, ' ').replace(/[*#`>]/g, '');
        const sec = ((Date.now() - t0) / 1000).toFixed(1);
        if (!cue || cue === 'NONE') {
          this.setData({ asr4: '💡なし (' + sec + 's)' });
        } else {
          this.setData({ asr4: '💡 ' + cue.slice(0, 30) + ' (' + sec + 's)' });
        }
        this.cueDone();
      }).catch((e) => {
        this.setData({ asr4: '💡 ERR ' + String((e && e.message) || e).slice(0, 22) });
        this.cueDone();
      });
    });
  },
  cueDone() {
    const c = this.cueState();
    c.busy = false;
    if (c.pending !== null && this._asr && this._asr.on) {
      c.pending = null;
      this.setData({ asr4: '💡考え中…' });
      this.cueFire();
    } else {
      c.pending = null;
    }
  },
  runTest() {
    const now = Date.now();
    if (now - this._lastRun < 1500) return;
    this._lastRun = now;
    this.refreshConn();
    this.setData({ line1: 'fetching...', line2: '' });
    const started = now;
    const url = 'https://pebble-bridge.flat-tooth-221e.workers.dev/inbox-status';
    const done = (ok, msg, sub) => {
      const ms = Date.now() - started;
      this.setData({
        line1: msg + ' ' + ms + 'ms',
        line2: sub || ''
      });
    };
    try {
      wx.request({
        url: url,
        method: 'GET',
        success: (res) => {
          let sub = '';
          try {
            const d = typeof res.data === 'string' ? JSON.parse(res.data) : res.data;
            if (d && d.latest) sub = 'latest: ' + d.latest;
          } catch (e) { /* keep sub empty */ }
          done(res.statusCode >= 200 && res.statusCode < 300, 'HTTP ' + res.statusCode, sub);
        },
        fail: (err) => {
          done(false, 'fetch FAIL', (err && err.errMsg) ? String(err.errMsg).slice(0, 28) : '');
        }
      });
    } catch (e) {
      done(false, 'wx.request n/a', '');
    }
  },
  handleTap() {
    this.runTest();
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
    <text class="line sub probe">conn: {{ connType }} / {{ line1 }}</text>
    <text class="line sub">{{ probe }}</text>
    <text class="line sub">{{ cam }}</text>
    <text class="line sub">{{ shot }}</text>
    <text class="line sub">{{ locRes }}</text>
    <text class="line keys">{{ k1 }}</text>
    <text class="line keys">{{ k2 }}</text>
    <text class="line keys">{{ k3 }}</text>
    <text class="line keys">{{ k4 }}</text>
    <text class="line keys">{{ k5 }}</text>
    <camera class="camview"></camera>
    <button bindtap="handleTap">TEST</button>
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

.probe {
  margin-top: 6px;
}

.cue {
  color: #40FF5E;
  font-size: 24px;
  line-height: 30px;
}

.keys {
  color: #40FF5E99;
  font-size: 18px;
  line-height: 22px;
}

.camview {
  width: 2px;
  height: 2px;
  margin-top: 6px;
}

button {
  color: #40FF5E;
  border: 1px solid #40ff5d42;
  border-radius: 12px;
  box-sizing: border-box;
  padding: 5px;
  width: 120px;
  line-height: 24px;
  text-align: center;
  margin-top: 10px;
}
</style>
