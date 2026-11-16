<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b30: self-exit API probe (user request 2026-11-16).
// Exiting an agent today takes ~4 BACK presses: our pages
// consume the first BACK (reload), pass the second one
// through, and the host stack eats a couple more. If the
// runtime offers a programmatic exit, BACK x2 could close
// an agent outright. Nothing in the local docs lists one,
// so this page probes the candidates on device:
//   - existence (typeof) for a list of wx.* / global
//     candidates, shown as OK / --
//   - swipes move the cursor, tap invokes the selected
//     candidate (only when it exists); success/fail
//     callbacks and a 1.2 s survivor timer report back on
//     screen when the call returns without exiting.
// wx.navigateTo is a display-only control (a navigation
// API we may or may not have; it calibrates the rest).
// Key handling copies the radar/kensho idiom (GlobalHook
// arm + Enter confirm + 700 ms lockout). BACK is left
// alone so the OS exit always works as a fallback.
export default {
  data: {
    build: 'vrf-b30',
    status: '候補を選んでタップで実行',
    r0: '', r1: '', r2: '', r3: '', r4: '',
    r5: '', r6: '', r7: '', r8: ''
  },
  _sel: 0,
  _tapTimer: null,
  _tapLockUntil: 0,
  _cands: null,
  onLoad() {
    const W = (typeof wx !== 'undefined') ? wx : null;
    const G = (typeof globalThis !== 'undefined') ? globalThis : {};
    const P = (typeof $page !== 'undefined') ? $page : null;
    const self = this;
    const cb = (name) => ({
      success: () => self.setData({ status: name + ': success コールバック（終了せず）' }),
      fail: (e) => self.setData({ status: name + ': fail ' + ((e && e.errMsg) || '') }),
      complete: () => {}
    });
    this._cands = [
      { name: 'wx.exitMiniProgram', ok: !!(W && typeof W.exitMiniProgram === 'function'),
        run: () => W.exitMiniProgram(cb('exitMiniProgram')) },
      { name: 'wx.navigateBack', ok: !!(W && typeof W.navigateBack === 'function'),
        run: () => W.navigateBack(Object.assign({ delta: 99 }, cb('navigateBack'))) },
      { name: 'wx.closeWindow', ok: !!(W && typeof W.closeWindow === 'function'),
        run: () => W.closeWindow(cb('closeWindow')) },
      { name: 'wx.exit', ok: !!(W && typeof W.exit === 'function'),
        run: () => W.exit() },
      { name: '$page.finish', ok: !!(P && typeof P.finish === 'function'),
        run: () => P.finish() },
      { name: 'history.back', ok: !!(G.history && typeof G.history.back === 'function'),
        run: () => G.history.back() },
      { name: 'window.close', ok: typeof G.close === 'function',
        run: () => G.close() },
      { name: 'wx.reLaunch', ok: !!(W && typeof W.reLaunch === 'function'),
        run: () => W.reLaunch(Object.assign({ url: '/pages/index/index' }, cb('reLaunch'))) },
      { name: 'wx.navigateTo(表示のみ)', ok: !!(W && typeof W.navigateTo === 'function'),
        run: null }
    ];
    this.renderRows();
  },
  renderRows() {
    const d = {};
    for (let i = 0; i < this._cands.length; i++) {
      const c = this._cands[i];
      d['r' + i] = (i === this._sel ? '▶ ' : '　') + (c.ok ? 'OK ' : '-- ') + c.name;
    }
    this.setData(d);
  },
  move(dlt) {
    const n = this._cands.length;
    this._sel = ((this._sel + dlt) % n + n) % n;
    this.renderRows();
  },
  invoke() {
    const c = this._cands[this._sel];
    if (!c.ok) { this.setData({ status: c.name + ' は存在しません' }); return; }
    if (!c.run) { this.setData({ status: c.name + ' は表示のみです' }); return; }
    this.setData({ status: c.name + ' を呼びます…' });
    try {
      c.run();
    } catch (e) {
      this.setData({ status: c.name + ' 例外: ' + e.message });
      return;
    }
    setTimeout(() => {
      this.setData({ status: c.name + ': 呼んだけど終了しませんでした' });
    }, 1200);
  },
  fireTap() {
    this._tapLockUntil = Date.now() + 700;
    this.invoke();
  },
  onKeyUp(event) {
    const code = event && event.code;
    if (code === 'GlobalHook') {
      event.preventDefault();
      if (Date.now() < this._tapLockUntil) return;
      if (this._tapTimer) return;
      this._tapTimer = setTimeout(() => { this._tapTimer = null; this.fireTap(); }, 300);
      return;
    }
    if (code === 'Enter') {
      event.preventDefault();
      if (Date.now() < this._tapLockUntil) return;
      if (this._tapTimer) { clearTimeout(this._tapTimer); this._tapTimer = null; }
      this.fireTap();
      return;
    }
    if (code === 'ArrowUp' || code === 'ArrowDown') {
      event.preventDefault();
      if (this._tapTimer) { clearTimeout(this._tapTimer); this._tapTimer = null; }
      this.move(code === 'ArrowUp' ? -1 : 1);
    }
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Kensho {{ build }} 終了API探し</text>
    <text class="line sub">{{ status }}</text>
    <text class="row">{{ r0 }}</text>
    <text class="row">{{ r1 }}</text>
    <text class="row">{{ r2 }}</text>
    <text class="row">{{ r3 }}</text>
    <text class="row">{{ r4 }}</text>
    <text class="row">{{ r5 }}</text>
    <text class="row">{{ r6 }}</text>
    <text class="row">{{ r7 }}</text>
    <text class="row">{{ r8 }}</text>
    <text class="line sub">スワイプ: 選択 / タップ: 実行 / BACK: 通常終了</text>
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
  font-size: 16px;
  line-height: 20px;
  margin-bottom: 6px;
}

.row {
  color: #40FF5E;
  font-size: 17px;
  line-height: 21px;
}
</style>
