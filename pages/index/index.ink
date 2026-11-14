<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b25: green gradation test (2026-11-14, user request).
// How many brightness steps can the glasses' green panel
// actually show? Two screens of solid G-channel strips:
//   A: 16 steps, G = 0,17,34,...,255 (full range, even ladder)
//   B: 17 steps — low range 0..56 by 8 (where ladders usually
//      collapse) + high range 192..255 by 8.
// Each strip is labelled with its G value in full-brightness
// text; the user counts how many bands are distinguishable.
// Tap (GlobalHook arm + Enter confirm, 700 ms lockout — the
// radar rdr-b7 pattern) cycles A -> B -> A. Verdict feeds the
// rain ladder design in the radar agent.
export default {
  data: {
    build: 'vrf-b25',
    screen: 'A',
    head: 'A: 16段 (0〜255, 17刻み)'
  },
  _tapTimer: null,
  _tapLockUntil: 0,
  fireTap() {
    this._tapLockUntil = Date.now() + 700;
    if (this.data.screen === 'A') {
      this.setData({ screen: 'B', head: 'B: 低域 0〜56 / 高域 192〜255 (8刻み)' });
    } else {
      this.setData({ screen: 'A', head: 'A: 16段 (0〜255, 17刻み)' });
    }
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
    }
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Verify {{ build }} 階調</text>
    <text class="head">{{ head }}</text>
    <view v-if="screen === 'A'">
    <view class="strip ga0"><text class="lab">0</text></view>
    <view class="strip ga1"><text class="lab">17</text></view>
    <view class="strip ga2"><text class="lab">34</text></view>
    <view class="strip ga3"><text class="lab">51</text></view>
    <view class="strip ga4"><text class="lab">68</text></view>
    <view class="strip ga5"><text class="lab">85</text></view>
    <view class="strip ga6"><text class="lab">102</text></view>
    <view class="strip ga7"><text class="lab">119</text></view>
    <view class="strip ga8"><text class="lab">136</text></view>
    <view class="strip ga9"><text class="lab">153</text></view>
    <view class="strip ga10"><text class="lab">170</text></view>
    <view class="strip ga11"><text class="lab">187</text></view>
    <view class="strip ga12"><text class="lab">204</text></view>
    <view class="strip ga13"><text class="lab">221</text></view>
    <view class="strip ga14"><text class="lab">238</text></view>
    <view class="strip ga15"><text class="lab">255</text></view>
    </view>
    <view v-else>
    <view class="strip gb0"><text class="lab">0</text></view>
    <view class="strip gb1"><text class="lab">8</text></view>
    <view class="strip gb2"><text class="lab">16</text></view>
    <view class="strip gb3"><text class="lab">24</text></view>
    <view class="strip gb4"><text class="lab">32</text></view>
    <view class="strip gb5"><text class="lab">40</text></view>
    <view class="strip gb6"><text class="lab">48</text></view>
    <view class="strip gb7"><text class="lab">56</text></view>
    <view class="strip gb8"><text class="lab">192</text></view>
    <view class="strip gb9"><text class="lab">200</text></view>
    <view class="strip gb10"><text class="lab">208</text></view>
    <view class="strip gb11"><text class="lab">216</text></view>
    <view class="strip gb12"><text class="lab">224</text></view>
    <view class="strip gb13"><text class="lab">232</text></view>
    <view class="strip gb14"><text class="lab">240</text></view>
    <view class="strip gb15"><text class="lab">248</text></view>
    <view class="strip gb16"><text class="lab">255</text></view>
    </view>
    <text class="foot">タップ: 画面切替</text>
  </view>
</page>

<style>
.container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  height: 100vh;
  padding: 8px;
}

.title {
  color: #40FF5E;
  font-size: 13px;
  line-height: 16px;
}

.head {
  color: #40FF5E;
  font-size: 15px;
  line-height: 19px;
  margin-bottom: 4px;
}

.foot {
  color: #40FF5E99;
  font-size: 12px;
  line-height: 15px;
  margin-top: 4px;
}

.strip {
  width: 432px;
  height: 12px;
  margin-bottom: 1px;
}

.lab {
  color: #40FF5E;
  font-size: 10px;
  line-height: 12px;
}

.ga0 { background: #000000; }
.ga1 { background: #001100; }
.ga2 { background: #002200; }
.ga3 { background: #003300; }
.ga4 { background: #004400; }
.ga5 { background: #005500; }
.ga6 { background: #006600; }
.ga7 { background: #007700; }
.ga8 { background: #008800; }
.ga9 { background: #009900; }
.ga10 { background: #00aa00; }
.ga11 { background: #00bb00; }
.ga12 { background: #00cc00; }
.ga13 { background: #00dd00; }
.ga14 { background: #00ee00; }
.ga15 { background: #00ff00; }

.gb0 { background: #000000; }
.gb1 { background: #000800; }
.gb2 { background: #001000; }
.gb3 { background: #001800; }
.gb4 { background: #002000; }
.gb5 { background: #002800; }
.gb6 { background: #003000; }
.gb7 { background: #003800; }
.gb8 { background: #00c000; }
.gb9 { background: #00c800; }
.gb10 { background: #00d000; }
.gb11 { background: #00d800; }
.gb12 { background: #00e000; }
.gb13 { background: #00e800; }
.gb14 { background: #00f000; }
.gb15 { background: #00f800; }
.gb16 { background: #00ff00; }
</style>
