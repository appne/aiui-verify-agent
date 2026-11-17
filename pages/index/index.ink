<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b32: layout/scroll probe for the zaisen footer-drop
// bug and the odekake mode-switch scroll problem
// (device reports 2026-11-17). One tap toggles the
// global phase 0 <-> 1 and applies it to every section;
// swipes are NOT consumed so the page scrolls freely.
//   S0: existence of scroll-related APIs (static).
//   S1: one <text> holding '\n'-joined lines. Phase 1
//       shortens 6 lines -> 2. If MARKER1 moves up,
//       '\n' renders multi-line AND the element shrinks.
//   S2: six slot texts; phase 1 clears slots 3-6 to ''.
//       If MARKER2 stays down, '' keeps the height
//       (the zaisen bug reproduced).
//   S4: <scroll-view> with scroll-top bound to data;
//       phase 1 sets it to 200. Tests whether the
//       element exists and the binding moves the view.
//   S3: page-scroll reset, LAST section on purpose:
//       scroll down here, then tap. The tap handler
//       calls window.scrollTo(0,0) and wx.pageScrollTo
//       when they exist; if the view jumps to the top,
//       one of them works.
export default {
  data: {
    build: 'vrf-b32',
    phase: 'phase: 0（タップで切替）',
    e0: '', e1: '', e2: '', e3: '',
    nlText: 'N1\nN2\nN3\nN4\nN5\nN6',
    s0: 'S1', s1: 'S2', s2: 'S3', s3: 'S4', s4: 'S5', s5: 'S6',
    svTop: 0,
    att: 'scroll試行: まだ'
  },
  _phase: 0,
  _tapTimer: null,
  _tapLockUntil: 0,
  onLoad() {
    const W = (typeof wx !== 'undefined') ? wx : null;
    const hasWin = (typeof window !== 'undefined');
    const t = (o, k) => (o && typeof o[k] === 'function') ? 'function' : typeof (o ? o[k] : undefined);
    this.setData({
      e0: 'window: ' + (hasWin ? '有' : '無') + ' / scrollTo: ' + (hasWin ? t(window, 'scrollTo') : '-'),
      e1: 'window.scrollBy: ' + (hasWin ? t(window, 'scrollBy') : '-'),
      e2: 'wx.pageScrollTo: ' + (W ? t(W, 'pageScrollTo') : 'wx無'),
      e3: 'wx.createSelectorQuery: ' + (W ? t(W, 'createSelectorQuery') : 'wx無') + ' / document: ' + (typeof document !== 'undefined' ? '有' : '無')
    });
  },
  fireTap() {
    this._tapLockUntil = Date.now() + 700;
    this._phase = this._phase ? 0 : 1;
    const p = this._phase;
    const d = { phase: 'phase: ' + p + '（タップで切替）' };
    if (p === 1) {
      d.nlText = 'N1\nN2';
      d.s2 = ''; d.s3 = ''; d.s4 = ''; d.s5 = '';
      d.svTop = 200;
    } else {
      d.nlText = 'N1\nN2\nN3\nN4\nN5\nN6';
      d.s2 = 'S3'; d.s3 = 'S4'; d.s4 = 'S5'; d.s5 = 'S6';
      d.svTop = 0;
    }
    this.setData(d);
    const tried = [];
    try {
      if (typeof window !== 'undefined' && typeof window.scrollTo === 'function') { window.scrollTo(0, 0); tried.push('win.scrollTo'); }
    } catch (e) { tried.push('win例外'); }
    try {
      if (typeof wx !== 'undefined' && typeof wx.pageScrollTo === 'function') { wx.pageScrollTo({ scrollTop: 0, duration: 0 }); tried.push('wx.pageScrollTo'); }
    } catch (e) { tried.push('wx例外'); }
    this.setData({ att: 'scroll試行: ' + (tried.length ? tried.join(' + ') : '手段なし') });
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
    // ArrowUp/ArrowDown intentionally left unconsumed:
    // the page must scroll so every section is reachable.
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Kensho {{ build }} レイアウト検証</text>
    <text class="sub">{{ phase }}</text>
    <text class="hd">S0: API有無</text>
    <text class="line">{{ e0 }}</text>
    <text class="line">{{ e1 }}</text>
    <text class="line">{{ e2 }}</text>
    <text class="line">{{ e3 }}</text>
    <text class="hd">S1: 改行テキスト（6行→2行）</text>
    <text class="line">{{ nlText }}</text>
    <text class="mark">▲MARKER1</text>
    <text class="hd">S2: 枠クリア（S3-S6を空に）</text>
    <text class="line">{{ s0 }}</text>
    <text class="line">{{ s1 }}</text>
    <text class="line">{{ s2 }}</text>
    <text class="line">{{ s3 }}</text>
    <text class="line">{{ s4 }}</text>
    <text class="line">{{ s5 }}</text>
    <text class="mark">▲MARKER2</text>
    <text class="hd">S4: scroll-view（phase1で200へ）</text>
    <scroll-view class="sv" scroll-top="{{ svTop }}" scroll-y="true">
      <text class="line">V01</text>
      <text class="line">V02</text>
      <text class="line">V03</text>
      <text class="line">V04</text>
      <text class="line">V05</text>
      <text class="line">V06</text>
      <text class="line">V07</text>
      <text class="line">V08</text>
      <text class="line">V09</text>
      <text class="line">V10</text>
      <text class="line">V11</text>
      <text class="line">V12</text>
      <text class="line">V13</text>
      <text class="line">V14</text>
      <text class="line">V15</text>
      <text class="line">V16</text>
      <text class="line">V17</text>
      <text class="line">V18</text>
      <text class="line">V19</text>
      <text class="line">V20</text>
    </scroll-view>
    <text class="hd">S3: ページscroll戻し（ここまで来てタップ）</text>
    <text class="line">{{ att }}</text>
    <text class="line">P01</text>
    <text class="line">P02</text>
    <text class="line">P03</text>
    <text class="line">P04</text>
    <text class="line">P05</text>
    <text class="line">P06</text>
    <text class="line">P07</text>
    <text class="line">P08</text>
    <text class="line">P09</text>
    <text class="line">P10</text>
    <text class="line">P11</text>
    <text class="line">P12</text>
    <text class="line">P13</text>
    <text class="line">P14</text>
    <text class="line">P15</text>
    <text class="line">P16</text>
    <text class="line">P17</text>
    <text class="line">P18</text>
    <text class="line">P19</text>
    <text class="line">P20</text>
    <text class="mark">S3末尾: 上でタップして先頭に戻れば成功</text>
  </view>
</page>

<style>
.container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  padding: 10px;
}

.title {
  color: #40FF5E;
  font-size: 13px;
  line-height: 16px;
  margin-bottom: 4px;
}

.hd {
  color: #40FF5E;
  font-size: 17px;
  line-height: 21px;
  margin-top: 10px;
  margin-bottom: 2px;
}

.line {
  color: #40FF5E;
  font-size: 17px;
  line-height: 21px;
}

.mark {
  color: #40FF5E;
  font-size: 17px;
  line-height: 21px;
  background-color: #14501C;
}

.sub {
  color: #40FF5E99;
  font-size: 16px;
  line-height: 20px;
  margin-bottom: 6px;
}

.sv {
  height: 126px;
  width: 300px;
  background-color: #0A2A0A;
}
</style>
