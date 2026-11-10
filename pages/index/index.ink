<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b20: translation-lane fixes (device report on b19: term
// cues worked but English was NEVER translated). Two defects:
// (1) isAlphaFinal demanded pure printable ASCII — but a Japanese
// recognizer emitting English text plausibly appends '。' or uses
// full-width Latin, so real English finals fell back to the
// assist lane and were judged NONE. Detection is now: normalize
// (full-width -> half-width, JP punctuation -> space) and accept
// when >=2 Latin letters remain and NO CJK/kana character is
// present. (2) trPump borrowed the assist lane's seq as its
// cancel guard, but cueFire bumps seq on EVERY assist cue — an
// assist cue firing mid-translation silently discarded the
// translation. The lane now has its own generation counter
// (trGen), bumped only by asrStop.
// vrf-b19: alphabet-final auto-translation (device findings +
// user instruction after the b18 test). FINDING: even in JA mode
// the recognizer transcribed English speech AS ENGLISH — the
// ja-JP lang setting does not lock it. And the b17/b18 cue design
// only ever translated the LATEST final after a pause, dropping
// earlier foreign utterances. User instruction: when a final is
// all-alphabet, send it to the AI without waiting for the batch
// and translate it regardless of content. So: alphabet-only
// finals (printable ASCII with >=2 letters) bypass the assist
// lane entirely and enter a FIFO translation queue (trq) that
// runs immediately, one pair per utterance, mutually exclusive
// with the assist lane (trBusy/busy cross-checks). The explicit
// language cycle stays for non-Latin scripts (ZH/KO), whose
// transcription behaviour is still unverified.
// vrf-b18: FOREIGN-LANGUAGE mode spike (user request, corrected
// from 'English' to 'foreign language' in general: if the
// conversation partner speaks a foreign language, show a Japanese
// translation — with the caveat that everything depends on the
// transcription). The ASR lang was hard-coded ja-JP, which would
// mangle foreign speech into phonetic Japanese garbage; no other
// ASR language has ever been probed on this runtime. A double tap
// (a second GlobalHook inside the pending-tap window) cycles the
// ASR language ja-JP -> en-US -> zh-CN -> ko-KR -> ja-JP...; the
// ASR line shows JA/EN/ZH/KO; in a foreign mode the cue lane
// becomes a translator (🗣 foreign final -> 💡 Japanese, 44
// chars; the LM prompt is source-language-agnostic) instead of
// the content assistant. Switching language restarts the loop
// (counters/history reset — acceptable for a spike). The cycle
// doubles as the support probe: an unsupported language should
// surface via the ASR 'language-not-supported' error path. Open
// question beyond this spike: how well the wearer-tuned mic picks
// up a PARTNER's voice (this only proves wearer-spoken tests).
// vrf-b17: cue PURPOSE correction (user, after the b15 device
// conversation test): the point is NOT to converse with the LM —
// it listens to the conversation and assists about the CONTENT:
// when a difficult keyword/concept appears, show its meaning;
// otherwise useful background. The b15 cues had drifted into
// chat-partner behaviour (greeting replies, suggesting what to
// say next) because the prompt offered '返答の候補'. The new
// prompt forbids replying to the speaker and suggesting replies;
// greetings/small talk get NONE.
// vrf-b16: gesture disambiguation (user report on b15: taps AND
// swipes kept flipping the ASR loop between starting/stop — the
// b15 device capture even shows the conversation ending in
// 'STOP (manual)' with counters reset). Temple input arrives as
// GlobalHook FIRST, then the gesture key (tap: Enter, swipe fwd:
// ArrowUp, swipe back: ArrowDown) — measured by other AIUI devs
// in the Studio simulator; physical glasses may send a lone
// GlobalHook only. Pre-b16 code toggled on GlobalHook itself, so
// every swipe toggled and taps could double-toggle. Now
// GlobalHook only arms a pending tap (gestureDelayMs, default
// 300): an Arrow cancels it — swipes are SCROLL ONLY (user
// request); Enter confirms it (toggle once); if nothing follows,
// the timer fires it as a lone tap.
// vrf-b15: display rework #3 (user requests after the b14 device
// test — readable, though not while walking; and the log's last
// line was JUST cut off at the bottom). Removed two lines above
// the scroll area, which also fixes the cutoff: (1) the dedicated
// 'LM: avail=…' line — the probe latency now rides at the end of
// the ASR line (' LM1.6s'; failures show ' LM:NG' plus a ⚠ log
// entry); (2) the live-caption line under it, which duplicated
// the ASR status line's final/interim text. Layout: think / title
// / ASR counters+LM / ASR last event / 12-line pair log.
// vrf-b14: display rework #2 (user request after the b13 device
// test — "結構面白い" but the 24 px log text overflowed the
// screen). Layout now: think line (top-left) / title at HALF size
// (26→13 px) / the ASR live-info lines unchanged / the scroll
// area in zaisen's footer size (15 px, lh 17). The log shows
// PAIRS: the utterance that triggered the cue (🗣, the latest
// final — the AI also receives the previous 2 finals as context)
// and the AI's reply (💡), 12 lines visible (6 pairs), history 40
// lines, ArrowUp/Down paging as in b13. NONE still leaves no pair.
// vrf-b13: display rework (user request after the b12 device test,
// which PASSED — no more ERRs). The '💡考え中…' indicator moves to
// its own line at the top-left and is ERASED when the cue settles
// instead of being overwritten by the reply. AI replies become a
// scrolling log: each cue is appended as an entry (last 5 shown,
// chat order), and ArrowUp/ArrowDown page back/forward through the
// history (kept to 30 entries) so past replies stay readable. NONE
// results are not logged (nothing to read); ERRs are logged with a
// ⚠ prefix so failures stay visible in context.
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
    build: 'vrf-b20',
    think: '',
    asr1: 'ASR: Enter = loop start/stop',
    asr2: '',
    log1: '', log2: '', log3: '', log4: '', log5: '', log6: '',
    log7: '', log8: '', log9: '', log10: '', log11: '', log12: ''
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
        ' max' + (a.sessMax / 1000).toFixed(1) + 's' +
        this.langTag() +
        (this._lmInfo || ''),
      asr2: lastDesc || a.lastDesc || ''
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
    try { rec.lang = this._lang || 'ja-JP'; } catch (e) { /* ignore */ }
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
      this._cue.trq = [];
      this._cue.trGen++;
      this._cue.seq++;
    }
    this.thinkOff();
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
  // vrf-b15: the probe no longer owns a display line. Its latency
  // rides at the end of the ASR line via _lmInfo; failures also drop
  // a ⚠ entry into the reply log so they stay visible.
  lmInfoRender() {
    if (this._asr) { this.asrRender(); return; }
    this.setData({ asr1: 'ASR: Enter = loop start/stop' +
      this.langTag() + (this._lmInfo || '') });
  },
  langTag() {
    return this._lang === 'en-US' ? ' EN' : this._lang === 'zh-CN' ? ' ZH' :
      this._lang === 'ko-KR' ? ' KO' : ' JA';
  },
  isForeign() { return !!this._lang && this._lang !== 'ja-JP'; },
  // vrf-b18: cycle the ASR language; restarts the loop when running.
  langFlip() {
    const order = ['ja-JP', 'en-US', 'zh-CN', 'ko-KR'];
    const cur = order.indexOf(this._lang || 'ja-JP');
    const wasOn = !!(this._asr && this._asr.on);
    this._lang = order[(cur + 1) % order.length];
    if (wasOn) {
      this.asrStop('lang');
      this.toggleAsr();
    } else {
      this.lmInfoRender();
    }
    this.cueLogPush(this._lang === 'en-US' ? '🌐 EN 英語→和訳' :
      this._lang === 'zh-CN' ? '🌐 ZH 中国語→和訳' :
      this._lang === 'ko-KR' ? '🌐 KO 韓国語→和訳' : '🌐 JA 日本語');
  },
  lmFail(msg) {
    this._lm = { ok: false };
    this._lmInfo = ' LM:NG';
    this.lmInfoRender();
    this.cueLogPush('⚠ LM ' + msg);
  },
  probeLm() {
    if (typeof Promise === 'undefined') { this.lmFail('no Promise'); return; }
    if (typeof LanguageModel === 'undefined') { this.lmFail('undefined'); return; }
    this.lmThen(() => LanguageModel.availability()).then((avail) => {
      if (avail === 'unavailable') { this.lmFail('unavailable'); return; }
      const t0 = Date.now();
      this.lmQueue(() => LanguageModel.create()).then((session) => {
        this._lm = { ok: true, probe: session };
        this.lmQueue(() => session.prompt('「乾杯」を5文字以内で言い換えて。')).then((out) => {
          const sec = ((Date.now() - t0) / 1000).toFixed(1);
          this._lmInfo = ' LM' + sec + 's';
          this.lmInfoRender();
          this.cueLogPush('LM: ' + String(out).trim().slice(0, 28));
        }).catch((e) => {
          this.lmFail('prompt ' + String((e && e.message) || e).slice(0, 18));
        });
      }).catch((e) => {
        this.lmFail('create ' + String((e && e.message) || e).slice(0, 18));
      });
    }).catch((e) => {
      this.lmFail('avail ' + String((e && e.message) || e).slice(0, 18));
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
    if (!this._cue) this._cue = { busy: false, dirty: false, timer: null, seq: 0, log: [], off: 0, curQ: '', trq: [], trBusy: false, trGen: 0 };
    return this._cue;
  },
  // ---- vrf-b13: thinking indicator + reply log ----
  thinkOn() { this.setData({ think: '💡考え中…' }); },
  thinkOff() { this.setData({ think: '' }); },
  cueLogPush(entry) {
    const c = this.cueState();
    c.log.push(entry);
    if (c.log.length > 40) c.log.shift();
    c.off = 0;
    this.cueLogRender();
  },
  cuePairPush(qLine, aLine) {
    const c = this.cueState();
    c.log.push(qLine);
    c.log.push(aLine);
    while (c.log.length > 40) c.log.shift();
    c.off = 0;
    this.cueLogRender();
  },
  cueLogRender() {
    const c = this.cueState();
    const end = Math.max(0, c.log.length - c.off);
    const win = c.log.slice(Math.max(0, end - 12), end);
    const patch = {};
    for (let i = 0; i < 12; i++) patch['log' + (i + 1)] = win[i] || '';
    this.setData(patch);
  },
  cueScroll(dir) {
    const c = this.cueState();
    const maxOff = Math.max(0, c.log.length - 12);
    c.off = Math.min(maxOff, Math.max(0, c.off + dir * 4));
    this.cueLogRender();
  },
  lmTimeout(p, ms) {
    return Promise.race([
      p,
      new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))
    ]);
  },
  // vrf-b20: Latin-script detection tolerant of recognizer
  // habits: full-width Latin is folded to half-width and Japanese
  // punctuation is blanked before judging; a final counts as
  // foreign when >=2 Latin letters remain and no CJK/kana
  // character is present.
  latinNorm(text) {
    return String(text || '')
      .replace(/[Ａ-Ｚａ-ｚ０-９]/g, (ch) => String.fromCharCode(ch.charCodeAt(0) - 0xFEE0))
      .replace(/[。、・！？]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  },
  isAlphaFinal(text) {
    const t = this.latinNorm(text);
    if (!t) return false;
    const letters = t.match(/[A-Za-z]/g);
    if (!letters || letters.length < 2) return false;
    return !/[぀-ヿ㐀-鿿豈-﫿ｦ-ﾝ]/.test(t);
  },
  cueRequest(text) {
    if (!this._lm || !this._lm.ok) return;
    const c = this.cueState();
    if (this.isAlphaFinal(text)) {
      this.thinkOn();
      c.trq.push(text);
      if (c.trq.length > 6) c.trq.shift();
      this.trPump();
      return;
    }
    this.thinkOn();
    c.dirty = true;
    if (c.timer) clearTimeout(c.timer);
    c.timer = setTimeout(() => { c.timer = null; this.cueMaybe(); }, this.cueDebounceMs || 1200);
  },
  cueMaybe() {
    const c = this.cueState();
    if (c.busy || !c.dirty) return;
    if (c.trBusy) {
      if (c.timer) clearTimeout(c.timer);
      c.timer = setTimeout(() => { c.timer = null; this.cueMaybe(); }, 400);
      return;
    }
    if (!this._asr || !this._asr.on) { c.dirty = false; return; }
    this.cueFire();
  },
  // vrf-b19: FIFO translation lane. Each queued utterance gets its
  // own disposable-session translation and its own pair, in order.
  trPump() {
    const c = this.cueState();
    if (c.busy || c.trBusy || !c.trq.length) return;
    if (!this._asr || !this._asr.on) { c.trq = []; return; }
    const q = c.trq.shift();
    const genAt = c.trGen;
    c.trBusy = true;
    const t0 = Date.now();
    const promptText = '次の外国語の発話を自然な日本語に訳してください。訳文だけを日本語60文字以内で返してください。装飾記号は使わないでください。\n' + q;
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
      if (genAt !== c.trGen) return;
      const txt = String(out || '').trim().replace(/\s+/g, ' ').replace(/[*#`>]/g, '');
      const sec = ((Date.now() - t0) / 1000).toFixed(1);
      if (txt && txt !== 'NONE') {
        this.cuePairPush('🗣 ' + q.slice(0, 40), '💡 ' + txt.slice(0, 44) + ' (' + sec + 's)');
      }
    }).catch((e) => {
      if (genAt !== c.trGen) return;
      this.cuePairPush('🗣 ' + q.slice(0, 40), '⚠ ERR ' + String((e && e.message) || e).slice(0, 24));
    }).then(() => {
      c.trBusy = false;
      if (c.trq.length) { this.trPump(); return; }
      if (c.dirty) { this.cueMaybe(); return; }
      if (!c.busy) this.thinkOff();
    });
  },
  cueFire() {
    const c = this.cueState();
    const a = this._asr;
    if (!a) { c.busy = false; return; }
    c.busy = true;
    c.dirty = false;
    const seq = ++c.seq;
    const t0 = Date.now();
    const q = a.finalsHist.length ? a.finalsHist[a.finalsHist.length - 1] : '';
    c.curQ = q;
    const convo = a.finalsHist.slice(-3).join('\n');
    const promptText = this.isForeign()
      ? '次の外国語の発話を自然な日本語に訳してください。訳文だけを日本語60文字以内で返してください。装飾記号は使わないでください。\n' + q
      : 'あなたは会話を聞いているだけの補助AIです。発言者への返答や、次に言うことの提案は絶対にしないでください。書き起こし（最新が最後）の中に難しい専門用語・概念が出てきたらその意味を、なければ話題の理解に役立つ背景知識があればそれを、日本語30文字以内で1つだけ出してください。挨拶・相づち・雑談など補助が不要なら NONE とだけ返してください。装飾記号は使わないでください。\n' + convo;
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
        // NONE leaves no pair — there is no reply to read back.
        if (cue && cue !== 'NONE') {
          const lim = this.isForeign() ? 44 : 30;
          this.cuePairPush('🗣 ' + q.slice(0, 40), '💡 ' + cue.slice(0, lim) + ' (' + sec + 's)');
        }
      }
      this.cueDone();
    }).catch((e) => {
      if (seq === c.seq) {
        this.cuePairPush('🗣 ' + q.slice(0, 40), '⚠ ERR ' + String((e && e.message) || e).slice(0, 24));
      }
      this.cueDone();
    });
  },
  cueDone() {
    const c = this.cueState();
    c.busy = false;
    // Finals arrived while this cue was in flight: take one short
    // breath, then cue the newest context (never a backlog). The
    // thinking indicator stays up across that follow-up cue; it is
    // erased only when the engine goes idle.
    if (c.dirty && this._asr && this._asr.on) {
      if (c.timer) clearTimeout(c.timer);
      c.timer = setTimeout(() => { c.timer = null; this.cueMaybe(); }, 600);
    } else if (c.trq && c.trq.length) {
      this.trPump();
    } else {
      this.thinkOff();
    }
  },
  onKeyUp(event) {
    const code = event.code;
    if (code === 'GlobalHook') {
      event.preventDefault();
      if (this._tapTimer) {
        // Second GlobalHook inside the pending window = double
        // tap: flip the ASR language instead of toggling (b18).
        clearTimeout(this._tapTimer);
        this._tapTimer = null;
        this.langFlip();
        return;
      }
      this._tapTimer = setTimeout(() => {
        this._tapTimer = null;
        this.toggleAsr();
      }, this.gestureDelayMs || 300);
      return;
    }
    if (code === 'Enter') {
      event.preventDefault();
      if (this._tapTimer) { clearTimeout(this._tapTimer); this._tapTimer = null; }
      this.toggleAsr();
      return;
    }
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      event.preventDefault();
      if (this._tapTimer) { clearTimeout(this._tapTimer); this._tapTimer = null; }
      this.cueScroll(code === 'ArrowUp' ? 1 : -1);
    }
  }
}
</script>

<page>
  <view class="container">
    <text class="line sub">{{ think }}</text>
    <text class="title">Verify {{ build }}</text>
    <text class="line sub">{{ asr1 }}</text>
    <text class="line sub">{{ asr2 }}</text>
    <text class="line cue">{{ log1 }}</text>
    <text class="line cue">{{ log2 }}</text>
    <text class="line cue">{{ log3 }}</text>
    <text class="line cue">{{ log4 }}</text>
    <text class="line cue">{{ log5 }}</text>
    <text class="line cue">{{ log6 }}</text>
    <text class="line cue">{{ log7 }}</text>
    <text class="line cue">{{ log8 }}</text>
    <text class="line cue">{{ log9 }}</text>
    <text class="line cue">{{ log10 }}</text>
    <text class="line cue">{{ log11 }}</text>
    <text class="line cue">{{ log12 }}</text>
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
  font-size: 13px;
  line-height: 16px;
  margin-bottom: 4px;
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
  font-size: 15px;
  line-height: 17px;
}

</style>
