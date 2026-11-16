<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b31: exit-combo probe (follow-up to b30, device
// findings 2026-11-16). b30 established that
// wx.exitMiniProgram and window.close EXIST, and that
// ONE call advances the host exit sequence by exactly
// one stage (the same as one unconsumed BACK); the
// agent stays open and ~2 more BACKs finish the exit.
// This page tests whether stacking calls pops the
// remaining stages so the agent closes outright:
//   0: exitMiniProgram x3, synchronous burst
//   1: exitMiniProgram x4, 250 ms apart
//   2: exitMiniProgram / window.close alternating x4,
//      250 ms apart
//   3: navigateBack x3 burst (delta 1 each)
//   4: exitMiniProgram x1 (reference: one stage)
// After firing a combo, count how many extra BACKs are
// still needed: 0 = the combo closed the agent alone.
// Swipes move the cursor, tap fires the combo. BACK is
// left alone so the OS exit always works.
export default {
  data: {
    build: 'vrf-b31',
    status: 'コンボを選んでタップで発射',
    r0: '', r1: '', r2: '', r3: '', r4: ''
  },
  _sel: 0,
  _tapTimer: null,
  _tapLockUntil: 0,
  _combos: null,
  onLoad() {
    const W = (typeof wx !== 'undefined') ? wx : null;
    const G = (typeof globalThis !== 'undefined') ? globalThis : {};
    const exitOnce = () => { if (W && typeof W.exitMiniProgram === 'function') W.exitMiniProgram(); };
    const closeOnce = () => { if (typeof G.close === 'function') G.close(); };
    const backOnce = () => { if (W && typeof W.navigateBack === 'function') W.navigateBack({ delta: 1 }); };
    const burst = (fn, n) => () => { for (let i = 0; i < n; i++) fn(); };
    const spaced = (fns, ms) => () => {
      fns.forEach((fn, i) => setTimeout(fn, i * ms));
    };
    this._combos = [
      { name: 'exitMiniProgram ×3 連射', run: burst(exitOnce, 3) },
      { name: 'exitMiniProgram ×4 (250ms間隔)', run: spaced([exitOnce, exitOnce, exitOnce, exitOnce], 250) },
      { name: 'exit/close 交互 ×4 (250ms間隔)', run: spaced([exitOnce, closeOnce, exitOnce, closeOnce], 250) },
      { name: 'navigateBack ×3 連射', run: burst(backOnce, 3) },
      { name: 'exitMiniProgram ×1 (参照)', run: burst(exitOnce, 1) }
    ];
    this.renderRows();
  },
  renderRows() {
    const d = {};
    for (let i = 0; i < this._combos.length; i++) {
      d['r' + i] = (i === this._sel ? '▶ ' : '　') + this._combos[i].name;
    }
    this.setData(d);
  },
  move(dlt) {
    const n = this._combos.length;
    this._sel = ((this._sel + dlt) % n + n) % n;
    this.renderRows();
  },
  invoke() {
    const c = this._combos[this._sel];
    this.setData({ status: c.name + ' を発射…' });
    try {
      c.run();
    } catch (e) {
      this.setData({ status: c.name + ' 例外: ' + e.message });
      return;
    }
    setTimeout(() => {
      this.setData({ status: c.name + ': まだ開いています。残りBACK回数を数えてください' });
    }, 1600);
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
    <text class="title">Kensho {{ build }} 終了コンボ検証</text>
    <text class="line sub">{{ status }}</text>
    <text class="row">{{ r0 }}</text>
    <text class="row">{{ r1 }}</text>
    <text class="row">{{ r2 }}</text>
    <text class="row">{{ r3 }}</text>
    <text class="row">{{ r4 }}</text>
    <text class="line sub">スワイプ: 選択 / タップ: 発射 / BACK: 通常終了</text>
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
