<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b33: follow-up layout probe (after b32 verdicts:
// no scrollTo APIs, '\n' does not break lines, '' keeps
// the height of a slot that once held content, and
// <scroll-view> + scroll-top binding works). Tap toggles
// the global phase 0 <-> 1; swipes stay unconsumed.
//   T1: slots styled with a `.eslot:empty` CSS rule.
//       Phase 1 clears E1-E4 to ''. If MARKERE rises,
//       :empty collapses cleared slots (a clean fix for
//       the zaisen footer drop).
//   T2: <scroll-view height="{{ svH }}">: phase 0 -> 60,
//       phase 1 -> 200. If the box height follows, the
//       height attribute is bindable (per-mode box
//       heights for odekake).
//   T5: <scroll-view scroll-top="{{ svTop }}"> W01-W20,
//       phase 0 -> 0, phase 1 -> 200 (re-confirmation in
//       this page). Native key-scroll of the inner view
//       is checked separately with arrow keys.
export default {
  data: {
    build: 'vrf-b33',
    phase: 'phase: 0（タップで切替）',
    q0: 'E1', q1: 'E2', q2: 'E3', q3: 'E4',
    svH: 60,
    svTop: 0
  },
  _phase: 0,
  _tapTimer: null,
  _tapLockUntil: 0,
  onLoad() {},
  fireTap() {
    this._tapLockUntil = Date.now() + 700;
    this._phase = this._phase ? 0 : 1;
    const p = this._phase;
    const d = { phase: 'phase: ' + p + '（タップで切替）' };
    if (p === 1) {
      d.q0 = ''; d.q1 = ''; d.q2 = ''; d.q3 = '';
      d.svH = 200;
      d.svTop = 200;
    } else {
      d.q0 = 'E1'; d.q1 = 'E2'; d.q2 = 'E3'; d.q3 = 'E4';
      d.svH = 60;
      d.svTop = 0;
    }
    this.setData(d);
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
    // Arrows left unconsumed (page scroll / inner
    // scroll native behaviour is part of the test).
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Kensho {{ build }} レイアウト検証2</text>
    <text class="sub">{{ phase }}</text>
    <text class="hd">T1: :emptyで空枠を潰す</text>
    <text class="eslot">{{ q0 }}</text>
    <text class="eslot">{{ q1 }}</text>
    <text class="eslot">{{ q2 }}</text>
    <text class="eslot">{{ q3 }}</text>
    <text class="mark">▲MARKERE</text>
    <text class="hd">T2: scroll-view高さ可変（60→200）</text>
    <scroll-view class="sv2" height="{{ svH }}" scroll-top="0" scroll-y="true">
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
    </scroll-view>
    <text class="hd">T5: scroll-view（scroll-top 0→200）</text>
    <scroll-view class="sv" scroll-top="{{ svTop }}" scroll-y="true">
      <text class="line">W01</text>
      <text class="line">W02</text>
      <text class="line">W03</text>
      <text class="line">W04</text>
      <text class="line">W05</text>
      <text class="line">W06</text>
      <text class="line">W07</text>
      <text class="line">W08</text>
      <text class="line">W09</text>
      <text class="line">W10</text>
      <text class="line">W11</text>
      <text class="line">W12</text>
      <text class="line">W13</text>
      <text class="line">W14</text>
      <text class="line">W15</text>
      <text class="line">W16</text>
      <text class="line">W17</text>
      <text class="line">W18</text>
      <text class="line">W19</text>
      <text class="line">W20</text>
    </scroll-view>
    <text class="sub">末尾: T5はキーで内側が動くかも見る</text>
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

.eslot {
  color: #40FF5E;
  font-size: 17px;
  line-height: 21px;
}

.eslot:empty {
  font-size: 0px;
  line-height: 0px;
  height: 0px;
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

.sv2 {
  height: 126px;
  width: 300px;
  background-color: #0A2A0A;
}
</style>
