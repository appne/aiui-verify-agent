<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
export default {
  data: {
    build: 'vrf-b1',
    connType: 'tap: test',
    line1: 'BT forward check',
    line2: 'Enter = run fetch',
    line3: ''
  },
  _lastRun: 0,
  onLoad() {
    this.refreshConn();
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
  runTest() {
    const now = Date.now();
    if (now - this._lastRun < 1500) return;
    this._lastRun = now;
    this.refreshConn();
    this.setData({ line1: 'fetching...', line2: '', line3: '' });
    const started = now;
    const url = 'https://pebble-bridge.flat-tooth-221e.workers.dev/inbox-status';
    const done = (ok, msg, sub) => {
      const ms = Date.now() - started;
      this.setData({
        line1: msg,
        line2: sub || '',
        line3: ok ? ('took ' + ms + 'ms') : ''
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
    <text class="line sub">{{ line3 }}</text>
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
  padding: 16px;
}

.title {
  color: #40FF5E;
  font-size: 30px;
  line-height: 34px;
  margin-bottom: 12px;
}

.line {
  color: #40FF5E;
  font-size: 24px;
  line-height: 30px;
}

.sub {
  color: #40FF5E99;
  font-size: 20px;
  line-height: 26px;
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
  margin-top: 16px;
}
</style>
