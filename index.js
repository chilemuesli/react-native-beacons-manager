// @flow

import NativeBeaconsManager from './src/NativeBeaconsManager';
import {
  PARSER_IBEACON,
  PARSER_ESTIMOTE,
  PARSER_ALTBEACON,
  PARSER_EDDYSTONE_TLM,
  PARSER_EDDYSTONE_UID,
  PARSER_EDDYSTONE_URL,
  transmissionSupport,
} from './lib/next/module.types';

const RUNNING_AVG_RSSI_FILTER = 0;
const ARMA_RSSI_FILTER = 1;

// Maps the event names used by earlier (bridge based) versions to the typed
// event emitters of the TurboModule.
const EVENT_EMITTERS = {
  beaconsDidRange: NativeBeaconsManager.onBeaconsDidRange,
  regionDidEnter: NativeBeaconsManager.onRegionDidEnter,
  regionDidExit: NativeBeaconsManager.onRegionDidExit,
  didDetermineState: NativeBeaconsManager.onDidDetermineState,
  authorizationStatusDidChange: NativeBeaconsManager.onAuthorizationStatusDidChange,
  beaconServiceConnected: NativeBeaconsManager.onBeaconServiceConnected,
};

/**
 * Same on iOS and Android: BeaconsEventEmitter.addListener('beaconsDidRange', cb)
 * returns a subscription with remove().
 */
const BeaconsEventEmitter = {
  addListener(eventName: string, listener: (event: any) => void) {
    const emitter = EVENT_EMITTERS[eventName];
    if (!emitter) {
      throw new Error(
        `react-native-beacons-manager: unknown event '${eventName}'. Known events: ${Object.keys(
          EVENT_EMITTERS,
        ).join(', ')}`,
      );
    }
    return emitter(listener);
  },
};

const addParsers = parsers => NativeBeaconsManager.addParsersListToDetection(parsers);
const removeParsers = parsers => NativeBeaconsManager.removeParsersListToDetection(parsers);

const Beacons = {
  // parsers constants (Android)
  PARSER_IBEACON,
  PARSER_ESTIMOTE,
  PARSER_ALTBEACON,
  PARSER_EDDYSTONE_TLM,
  PARSER_EDDYSTONE_UID,
  PARSER_EDDYSTONE_URL,
  ARMA_RSSI_FILTER,
  RUNNING_AVG_RSSI_FILTER,

  BeaconsEventEmitter,

  // iOS
  requestAlwaysAuthorization: () => NativeBeaconsManager.requestAlwaysAuthorization(),
  requestWhenInUseAuthorization: () => NativeBeaconsManager.requestWhenInUseAuthorization(),
  allowsBackgroundLocationUpdates: (allow: boolean = false) =>
    NativeBeaconsManager.allowsBackgroundLocationUpdates(allow),
  /** callback style kept for compatibility, a Promise is returned as well */
  getAuthorizationStatus: (callback?: (status: string) => any): Promise<string> => {
    const promise = NativeBeaconsManager.getAuthorizationStatus();
    if (callback) {
      promise.then(callback);
    }
    return promise;
  },
  startUpdatingLocation: () => NativeBeaconsManager.startUpdatingLocation(),
  stopUpdatingLocation: () => NativeBeaconsManager.stopUpdatingLocation(),
  shouldDropEmptyRanges: (drop: boolean) => NativeBeaconsManager.shouldDropEmptyRanges(drop),

  // Android
  setHardwareEqualityEnforced: (flag: boolean) =>
    NativeBeaconsManager.setHardwareEqualityEnforced(flag),
  detectIBeacons: () => NativeBeaconsManager.addParser(PARSER_IBEACON),
  addIBeaconsDetection: () => NativeBeaconsManager.addParser(PARSER_IBEACON),
  removeIBeaconsDetection: () => NativeBeaconsManager.removeParser(PARSER_IBEACON),
  detectAltBeacons: () => NativeBeaconsManager.addParser(PARSER_ALTBEACON),
  addAltBeaconsDetection: () => NativeBeaconsManager.addParser(PARSER_ALTBEACON),
  removeAltBeaconsDetection: () => NativeBeaconsManager.removeParser(PARSER_ALTBEACON),
  detectEstimotes: () => NativeBeaconsManager.addParser(PARSER_ESTIMOTE),
  addEstimotesDetection: () => NativeBeaconsManager.addParser(PARSER_ESTIMOTE),
  removeEstimotesDetection: () => NativeBeaconsManager.removeParser(PARSER_ESTIMOTE),
  detectEddystoneUID: () => NativeBeaconsManager.addParser(PARSER_EDDYSTONE_UID),
  addEddystoneUIDDetection: () => NativeBeaconsManager.addParser(PARSER_EDDYSTONE_UID),
  removeEddystoneUIDDetection: () => NativeBeaconsManager.removeParser(PARSER_EDDYSTONE_UID),
  detectEddystoneURL: () => NativeBeaconsManager.addParser(PARSER_EDDYSTONE_URL),
  addEddystoneURLDetection: () => NativeBeaconsManager.addParser(PARSER_EDDYSTONE_URL),
  removeEddystoneURLDetection: () => NativeBeaconsManager.removeParser(PARSER_EDDYSTONE_URL),
  detectEddystoneTLM: () => NativeBeaconsManager.addParser(PARSER_EDDYSTONE_TLM),
  addEddystoneTLMDetection: () => NativeBeaconsManager.addParser(PARSER_EDDYSTONE_TLM),
  removeEddystoneTLMDetection: () => NativeBeaconsManager.removeParser(PARSER_EDDYSTONE_TLM),
  detectCustomBeaconLayout: (parser: string) => NativeBeaconsManager.addParser(parser),
  addCustomBeaconLayoutDetection: (parser: string) => NativeBeaconsManager.addParser(parser),
  removeCustomBeaconLayoutDetection: (parser: string) => NativeBeaconsManager.removeParser(parser),
  addParsersListToDetection: addParsers,
  removeParsersListToDetection: removeParsers,
  setBackgroundScanPeriod: (period: number) => NativeBeaconsManager.setBackgroundScanPeriod(period),
  setBackgroundBetweenScanPeriod: (period: number) =>
    NativeBeaconsManager.setBackgroundBetweenScanPeriod(period),
  setForegroundScanPeriod: (period: number) => NativeBeaconsManager.setForegroundScanPeriod(period),
  setForegroundBetweenScanPeriod: (period: number) =>
    NativeBeaconsManager.setForegroundBetweenScanPeriod(period),
  setRssiFilter: (filterType: number, avgModifier: number) =>
    NativeBeaconsManager.setRssiFilter(filterType, avgModifier),
  checkTransmissionSupported: (): Promise<string> =>
    NativeBeaconsManager.checkTransmissionSupported().then(status => transmissionSupport[status]),
  getRangedRegions: () => NativeBeaconsManager.getRangedRegions(),

  // common
  getMonitoredRegions: () => NativeBeaconsManager.getMonitoredRegions(),
  startMonitoringForRegion: (region: Object) => NativeBeaconsManager.startMonitoringForRegion(region),
  stopMonitoringForRegion: (region: Object) => NativeBeaconsManager.stopMonitoringForRegion(region),
  startRangingBeaconsInRegion: (region: Object | string, beaconsUUID?: string) =>
    NativeBeaconsManager.startRangingBeaconsInRegion(
      typeof region === 'string' ? {identifier: region, uuid: beaconsUUID} : region,
    ),
  stopRangingBeaconsInRegion: (region: Object | string, beaconsUUID?: string) =>
    NativeBeaconsManager.stopRangingBeaconsInRegion(
      typeof region === 'string' ? {identifier: region, uuid: beaconsUUID} : region,
    ),
  requestStateForRegion: (region: Object) => NativeBeaconsManager.requestStateForRegion(region),
};

export default Beacons;
