<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b26: gradation follow-up (2026-11-14). b25 findings from
// the wearer: low range separates well (8-steps visible at
// 0..56; up to ~G64 usable for map shading), 17-steps above
// ~100 are marginal, 8-steps at 192..255 are invisible. Also:
// v-if is NOT supported by the ink runtime — both branches
// rendered stacked (the page itself scrolls, so a single long
// page is fine). b26 is therefore one scrollable page, no
// conditionals, no tap handling:
//   block 1: 100..255 in 6 steps (31 apart) — the wearer
//            asked to see this division for the rain band
//   block 2: 100..255 in 11 steps (~15.5 apart) — finer probe
//            of where separation dies in the upper range
export default {
  data: {
    build: 'vrf-b26'
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Verify {{ build }} 階調2</text>
    <text class="head">1: 100〜255 を6段 (31刻み)</text>
    <view class="strip ga0"><text class="lab">100</text></view>
    <view class="strip ga1"><text class="lab">131</text></view>
    <view class="strip ga2"><text class="lab">162</text></view>
    <view class="strip ga3"><text class="lab">193</text></view>
    <view class="strip ga4"><text class="lab">224</text></view>
    <view class="strip ga5"><text class="lab">255</text></view>
    <text class="head">2: 100〜255 を11段 (約15.5刻み)</text>
    <view class="strip gb0"><text class="lab">100</text></view>
    <view class="strip gb1"><text class="lab">116</text></view>
    <view class="strip gb2"><text class="lab">131</text></view>
    <view class="strip gb3"><text class="lab">147</text></view>
    <view class="strip gb4"><text class="lab">162</text></view>
    <view class="strip gb5"><text class="lab">178</text></view>
    <view class="strip gb6"><text class="lab">193</text></view>
    <view class="strip gb7"><text class="lab">209</text></view>
    <view class="strip gb8"><text class="lab">224</text></view>
    <view class="strip gb9"><text class="lab">240</text></view>
    <view class="strip gb10"><text class="lab">255</text></view>
    <text class="foot">スワイプでスクロール</text>
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
  margin-top: 6px;
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

.ga0 { background: #006400; }
.ga1 { background: #008300; }
.ga2 { background: #00a200; }
.ga3 { background: #00c100; }
.ga4 { background: #00e000; }
.ga5 { background: #00ff00; }

.gb0 { background: #006400; }
.gb1 { background: #007400; }
.gb2 { background: #008300; }
.gb3 { background: #009300; }
.gb4 { background: #00a200; }
.gb5 { background: #00b200; }
.gb6 { background: #00c100; }
.gb7 { background: #00d100; }
.gb8 { background: #00e000; }
.gb9 { background: #00f000; }
.gb10 { background: #00ff00; }
</style>
