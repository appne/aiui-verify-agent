<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b29: light-rain samples, much dimmer than the
// production floor (user request 2026-11-15 evening).
// Production rain starts at G80+; the wearer wants to
// judge whether a dimmer light-rain field still reads
// as rain on the real display. Three synthetic frames
// over the current production Kyoto-Station base (auto
// labels included), served as /radar/sampleN.png:
//   0: no rain (the base itself)
//   1: full light rain, rain component G40 (terrain+40)
//   2: full light rain, rain component G60 (terrain+60)
// Marks are stamped back production-faithfully (the
// b27-v1 lesson: the G0 outline must survive).
// vrf-b28: image URL carries a load-time cache bust
// (?t=Date.now()) so regenerated sample files show up
// without a repackage.
// Tap cycles 0 -> 1 -> 2; swipes step forward/back.
// Tap handling copies the radar idiom (GlobalHook arm +
// Enter confirm + 700 ms lockout). BACK is left alone so
// the OS exit works.
export default {
  data: {
    build: 'vrf-b29',
    status: '',
    imgSrc: ''
  },
  _base: 'http://100.124.235.107:18765/radar/',
  _samples: [
    { src: 'sample0.png', label: '1/3 無雨' },
    { src: 'sample1.png', label: '2/3 薄い雨 G40' },
    { src: 'sample2.png', label: '3/3 薄い雨 G60' }
  ],
  _idx: 0,
  _tapTimer: null,
  _tapLockUntil: 0,
  onLoad() {
    this.applySample();
  },
  applySample() {
    const s = this._samples[this._idx];
    this.setData({
      status: s.label,
      imgSrc: this._base + s.src + '?t=' + Date.now()
    });
  },
  step(d) {
    const n = this._samples.length;
    this._idx = ((this._idx + d) % n + n) % n;
    this.applySample();
  },
  fireTap() {
    this._tapLockUntil = Date.now() + 700;
    this.step(1);
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
      this.step(code === 'ArrowUp' ? 1 : -1);
    }
  }
}
</script>

<page>
  <view class="container">
    <text class="title">Kensho {{ build }} 雨サンプル</text>
    <text class="line sub">{{ status }}</text>
    <image class="radar" src="{{ imgSrc }}"></image>
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

.radar {
  width: 448px;
  height: 286px;
  margin: 4px 0;
}
</style>
