<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b28: same samples as b27, but the image URL carries
// a load-time cache bust (?t=Date.now()) so regenerated
// sample files show up without a repackage. (The b27
// samples were also regenerated production-faithfully:
// v1 dissolved the labels' G0 outline into the rain.)
// vrf-b27: additive-rain samples (2026-11-15). The radar's
// rain compositing became ADDITIVE (terrain G0..32 + rain
// G80..220) so the land stays visible under a full cover;
// the wearer wants to judge the BRIGHT end on the real
// display (samples on a monitor cannot show it). Four
// synthetic frames, generated with the production formula
// over the real Kyoto-Station base map and served by the
// listener as /radar/sampleN.png:
//   0: no rain (the base itself)
//   1: full light rain (strength 0.15, rain G101)
//   2: full heavy rain (strength 0.92, rain G208)
//   3: vertical thirds — none | light | heavy
// Tap cycles 0 -> 1 -> 2 -> 3; swipes step forward/back.
// Tap handling copies the radar idiom (GlobalHook arm +
// Enter confirm + 700 ms lockout). BACK is left alone so
// the OS exit works.
export default {
  data: {
    build: 'vrf-b28',
    status: '',
    imgSrc: ''
  },
  _base: 'http://100.124.235.107:18765/radar/',
  _samples: [
    { src: 'sample0.png', label: '1/4 無雨' },
    { src: 'sample1.png', label: '2/4 全面・薄い雨' },
    { src: 'sample2.png', label: '3/4 全面・濃い雨' },
    { src: 'sample3.png', label: '4/4 3分割 無|薄|濃' }
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
