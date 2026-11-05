import {test} from 'node:test';
import assert from 'node:assert/strict';
import {assessDevice,DOWNLOAD_RESERVE_BYTES,requiredDownloadSpace,type DeviceSnapshot} from '../src/services/deviceCompatibility';
const good:DeviceSnapshot={deviceName:'Test phone',androidVersion:'14',apiLevel:34,minApiLevel:24,arm64:true,process64Bit:true,totalRamBytes:7_500_000_000,availableRamBytes:3_000_000_000,lowRamDevice:false,lowMemory:false,freeStorageBytes:10_000_000_000,reclaimableBytes:0,modelBytes:1_107_409_472,modelReady:false,activeDownload:false,downloadedBytes:0};
test('a supported phone with enough resources passes the basic checks',()=>{assert.equal(assessDevice(good).level,'ready');assert.equal(assessDevice(good).canDownload,true);});
test('unsupported Android and non-ARM64 processes are blocked',()=>{
 assert.equal(assessDevice({...good,apiLevel:23}).canDownload,false);
 assert.equal(assessDevice({...good,arm64:false}).canDownload,false);
 assert.equal(assessDevice({...good,process64Bit:false}).canDownload,false);
});
test('low or unknown memory produces guidance, not an untested hard rejection',()=>{
 for(const change of [{totalRamBytes:2_800_000_000},{availableRamBytes:500_000_000},{lowMemory:true},{totalRamBytes:0}]){
  const result=assessDevice({...good,...change});assert.equal(result.level,'caution');assert.equal(result.canDownload,true);
 }
});
test('insufficient download storage blocks setup and identifies storage',()=>{
 const result=assessDevice({...good,freeStorageBytes:300_000_000});assert.equal(result.canDownload,false);assert.equal(result.checks.find(c=>c.key==='storage')?.state,'fail');
});
test('active downloads credit only their remaining bytes',()=>{
 assert.equal(requiredDownloadSpace({...good,activeDownload:true,downloadedBytes:700_000_000}),good.modelBytes-700_000_000+DOWNLOAD_RESERVE_BYTES);
 assert.equal(requiredDownloadSpace({...good,activeDownload:false,downloadedBytes:700_000_000}),good.modelBytes+DOWNLOAD_RESERVE_BYTES);
});
test('an invalid package can be replaced using its recoverable space',()=>{
 const result=assessDevice({...good,freeStorageBytes:300_000_000,reclaimableBytes:1_107_409_472});assert.equal(result.canDownload,true);
});
test('an installed package does not require a second download; low working space is advisory',()=>{
 const installed={...good,modelReady:true,freeStorageBytes:20_000_000};assert.equal(requiredDownloadSpace(installed),0);assert.equal(assessDevice(installed).canDownload,true);assert.equal(assessDevice(installed).level,'caution');
});
