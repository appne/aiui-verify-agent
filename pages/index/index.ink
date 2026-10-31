<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
export default {
  data: {
    build: 'vrf-b7',
    connType: 'tap: test',
    line1: 'BT forward check',
    line2: 'Enter = run fetch',
    probe: 'loc: ...',
    cam: 'cam: ...',
    shot: 'shot: idle',
    shot2: '',
    locRes: '',
    k1: '', k2: '', k3: '', k4: '', k5: ''
  },
  _lastRun: 0,
  onLoad() {
    this.refreshConn();
    this.probeApis();
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
        ret.then((r) => finish('PHOTO OK', describe(r)))
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
        ' cVC' + mark(has(wx, 'createVideoContext')) +
        ' | oCam' + mark(hasO(wx, 'camera')) +
        ' oSp' + mark(hasO(wx, 'speech'))
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
          (p) => { answered = true; setRes('geo ok ' + p.coords.latitude + ',' + p.coords.longitude); },
          (e) => { answered = true; setRes('geo err ' + (e && e.code)); },
          { timeout: 6000 }
        );
        setTimeout(() => { if (!answered) setRes('geo: timeout'); }, 7000);
      } catch (e) { setRes('geo exception'); }
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
      this.shoot();
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
    <text class="line">conn: {{ connType }}</text>
    <text class="line">{{ line1 }}</text>
    <text class="line sub">{{ line2 }}</text>
    <text class="line sub probe">{{ probe }}</text>
    <text class="line sub">{{ cam }}</text>
    <text class="line sub">{{ shot }}</text>
    <text class="line sub">{{ shot2 }}</text>
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
