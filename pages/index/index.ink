<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
export default {
  data: {
    build: 'vrf-b2',
    connType: 'tap: test',
    line1: 'BT forward check',
    line2: 'Enter = run fetch',
    probe: 'loc: ...',
    locRes: '',
    k1: '', k2: '', k3: '', k4: '', k5: ''
  },
  _lastRun: 0,
  onLoad() {
    this.refreshConn();
    this.probeApis();
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
    const patch = {};
    for (let i = 0; i < 5; i++) patch['k' + (i + 1)] = lines[i] || '';
    if (lines.length > 5) {
      patch.k5 = (patch.k5 + ' +more').slice(0, 38);
    }
    this.setData(patch);
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
      this.runTest();
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
    <text class="line sub">{{ locRes }}</text>
    <text class="line keys">{{ k1 }}</text>
    <text class="line keys">{{ k2 }}</text>
    <text class="line keys">{{ k3 }}</text>
    <text class="line keys">{{ k4 }}</text>
    <text class="line keys">{{ k5 }}</text>
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
