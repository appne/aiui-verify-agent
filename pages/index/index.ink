<script def>
{
  "navigationBarTitleText": "Verify"
}
</script>

<script setup>
// vrf-b34: key-event logger. Records every event the ink
// runtime delivers to onKeyUp (and onKeyDown, if it exists)
// with its code / key / keyCode and the gap since the
// previous event. Purpose: capture the exact event shapes
// and order of ONE physical temple swipe (whose raw macro
// keys — NOTIFICATION, DPAD_RIGHT, DPAD_DOWN — reach ink
// pages, proven on odekake odk-b4/b5), so odekake's debug-
// key fingerprint guard can be built on measured facts.
// Nothing is consumed (no preventDefault anywhere).
export default {
  data: {
    build: 'vrf-b34',
    L0: '(no events yet)', L1: '', L2: '', L3: '', L4: '',
    L5: '', L6: '', L7: '', L8: '', L9: '', L10: '', L11: ''
  },
  _rows: [],
  _count: 0,
  _lastAt: 0,
  onLoad() {},
  logEvent(tag, event) {
    const now = Date.now();
    const dt = this._lastAt ? (now - this._lastAt) : 0;
    this._lastAt = now;
    this._count++;
    const code = event && event.code;
    const key = event && event.key;
    const kc = event && event.keyCode;
    const row = '#' + this._count + ' ' + tag
      + ' c=' + code + ' k=' + key + ' kc=' + kc + ' +' + dt;
    this._rows.unshift(row);
    if (this._rows.length > 12) this._rows.pop();
    const d = {};
    for (let i = 0; i < 12; i++) d['L' + i] = this._rows[i] || '';
    this.setData(d);
  },
  onKeyDown(event) { this.logEvent('DN', event); },
  onKeyUp(event) { this.logEvent('UP', event); }
}
</script>

<template>
  <div class="page">
    <text class="title">Kensho {{ build }} keylog</text>
    <text class="row">{{ L0 }}</text>
    <text class="row">{{ L1 }}</text>
    <text class="row">{{ L2 }}</text>
    <text class="row">{{ L3 }}</text>
    <text class="row">{{ L4 }}</text>
    <text class="row">{{ L5 }}</text>
    <text class="row">{{ L6 }}</text>
    <text class="row">{{ L7 }}</text>
    <text class="row">{{ L8 }}</text>
    <text class="row">{{ L9 }}</text>
    <text class="row">{{ L10 }}</text>
    <text class="row">{{ L11 }}</text>
  </div>
</template>

<style>
.page {
  display: flex;
  flex-direction: column;
  background-color: #000000;
  padding: 6px;
}
.title {
  color: #40FF5E;
  font-size: 17px;
  line-height: 19px;
}
.row {
  color: #40FF5E;
  font-size: 13px;
  line-height: 16px;
}
</style>
