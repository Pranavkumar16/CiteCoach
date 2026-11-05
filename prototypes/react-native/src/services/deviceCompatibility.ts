export type DeviceSnapshot={deviceName:string;androidVersion:string;apiLevel:number;minApiLevel:number;arm64:boolean;process64Bit:boolean;totalRamBytes:number;availableRamBytes:number;lowRamDevice:boolean;lowMemory:boolean;freeStorageBytes:number;reclaimableBytes:number;modelBytes:number;modelReady:boolean;activeDownload:boolean;downloadedBytes:number};
export type DeviceCheck={key:'system'|'processor'|'memory'|'storage';label:string;value:string;state:'pass'|'warn'|'fail';detail:string};
export type DeviceAssessment={level:'ready'|'caution'|'blocked';title:string;canDownload:boolean;checks:DeviceCheck[]};
export const DOWNLOAD_RESERVE_BYTES=128*1024*1024;
const gb=(bytes:number)=>(Math.max(0,bytes)/1_000_000_000).toFixed(1)+' GB';
export function requiredDownloadSpace(device:DeviceSnapshot):number {
  if(device.modelReady)return 0;
  const credited=device.activeDownload?Math.min(device.modelBytes,Math.max(0,device.downloadedBytes)):0;
  return Math.max(0,device.modelBytes-credited)+DOWNLOAD_RESERVE_BYTES;
}
export function assessDevice(device:DeviceSnapshot):DeviceAssessment {
  const os=device.apiLevel>=device.minApiLevel;
  const processor=device.arm64&&device.process64Bit;
  const memoryCaution=device.totalRamBytes<=0||device.totalRamBytes<4_000_000_000||device.lowRamDevice||device.lowMemory||device.availableRamBytes<1_500_000_000;
  const required=requiredDownloadSpace(device);
  const available=device.freeStorageBytes+(device.modelReady||device.activeDownload?0:Math.max(0,device.reclaimableBytes));
  const storageEnough=available>=required;
  const lowWorkingSpace=device.modelReady&&device.freeStorageBytes<DOWNLOAD_RESERVE_BYTES;
  const checks:DeviceCheck[]=[
    {key:'system',label:'Android',value:device.androidVersion,state:os?'pass':'fail',detail:os?'Supported Android version.':device.minApiLevel===24?'Android 7 or later is required.':'A newer Android version is required.'},
    {key:'processor',label:'Processor',value:processor?'64-bit supported':'Unsupported',state:processor?'pass':'fail',detail:processor?'This app supports your processor.':'This APK requires a 64-bit ARM Android device.'},
    {key:'memory',label:'Memory',value:device.totalRamBytes>0?gb(device.totalRamBytes)+' detected':'Unavailable',state:memoryCaution?'warn':'pass',detail:device.totalRamBytes<=0?'Memory could not be measured. Performance is unverified.':device.lowMemory||device.availableRamBytes<1_500_000_000?'Memory is currently limited. Close other apps and recheck.':memoryCaution?'Large files and long papers may be slow on this device.':'Memory estimate looks suitable; speed still varies.'},
    {key:'storage',label:'Storage',value:gb(available)+' available',state:!storageEnough?'fail':lowWorkingSpace?'warn':'pass',detail:!storageEnough?'Free about '+gb(required-available)+' more before downloading.':lowWorkingSpace?'Free space for new imports and PDF exports.':device.modelReady?'Offline AI is already downloaded.':device.reclaimableBytes>0&&!device.activeDownload?'Includes an incomplete AI download that will be replaced.':gb(required)+' needed to finish setup.'},
  ];
  const blocked=!os||!processor||!storageEnough;
  const caution=checks.some(check=>check.state==='warn');
  return {level:blocked?'blocked':caution?'caution':'ready',title:!os?'Android update required':!processor?'Processor not supported':!storageEnough?'Free storage before downloading':caution?'May run with limitations':'Basic checks passed',canDownload:!blocked,checks};
}
