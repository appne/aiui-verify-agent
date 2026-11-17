<script def>
{
  "title": "kensho"
}
</script>

<script setup>
export default {
  data: {
    build: 'vrf-b35',
    phase: 'PH0 all filled (tap=next)',
    a2: 'A2 slot', a3: 'A3 slot', a2c: 'ln', a3c: 'ln',
    b2: 'B2 slot', b3: 'B3 slot', b2s: '', b3s: '',
    c2: 'C2 slot', c3: 'C3 slot'
  },
  _ph: 0,
  onKeyUp(event) {
    const code = event && event.code;
    if (code !== 'Enter') return;
    event.preventDefault();
    this._ph = (this._ph + 1) % 2;
    if (this._ph === 1) {
      this.setData({
        phase: 'PH1 cleared: A=class B=style C=plain',
        a2: '', a3: '', a2c: 'ln col', a3c: 'ln col',
        b2: '', b3: '',
        b2s: 'line-height:0px;font-size:0px;height:0px;',
        b3s: 'line-height:0px;font-size:0px;height:0px;',
        c2: '', c3: ''
      });
    } else {
      this.setData({
        phase: 'PH0 all filled (tap=next)',
        a2: 'A2 slot', a3: 'A3 slot', a2c: 'ln', a3c: 'ln',
        b2: 'B2 slot', b3: 'B3 slot', b2s: '', b3s: '',
        c2: 'C2 slot', c3: 'C3 slot'
      });
    }
  }
}
</script>

<page>
  <view class="container">
    <text class="ln">{{ build }}</text>
    <text class="ln">{{ phase }}</text>
    <text class="ln">A1 slot</text>
    <text class="{{ a2c }}">{{ a2 }}</text>
    <text class="{{ a3c }}">{{ a3 }}</text>
    <text class="ln">== MARK A ==</text>
    <text class="ln">B1 slot</text>
    <text class="ln" style="{{ b2s }}">{{ b2 }}</text>
    <text class="ln" style="{{ b3s }}">{{ b3 }}</text>
    <text class="ln">== MARK B ==</text>
    <text class="ln">C1 slot</text>
    <text class="ln">{{ c2 }}</text>
    <text class="ln">{{ c3 }}</text>
    <text class="ln">== MARK C ==</text>
  </view>
</page>

<style>
  .container {
    display: flex;
    flex-direction: column;
    background-color: #000000;
    padding-top: 40px;
    padding-left: 16px;
  }
  .ln {
    color: #40FF5E;
    font-size: 19px;
    line-height: 20px;
  }
  .col {
    line-height: 0px;
    font-size: 0px;
    height: 0px;
  }
</style>
