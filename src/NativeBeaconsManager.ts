import type {CodegenTypes, TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/**
 * TurboModule spec (New Architecture). One spec for both platforms: methods
 * that only make sense on one platform are no-ops (or resolve with a neutral
 * value) on the other.
 *
 * A region is a plain object: {identifier, uuid, major?, minor?}.
 * Event payloads are plain objects, see index.d.ts for their shape.
 */
export interface Spec extends TurboModule {
  // --- common -------------------------------------------------------------
  startMonitoringForRegion(region: Object): Promise<void>;
  stopMonitoringForRegion(region: Object): Promise<void>;
  startRangingBeaconsInRegion(region: Object): Promise<void>;
  stopRangingBeaconsInRegion(region: Object): Promise<void>;
  requestStateForRegion(region: Object): void;
  getMonitoredRegions(): Promise<Object[]>;

  // --- iOS only -----------------------------------------------------------
  requestAlwaysAuthorization(): void;
  requestWhenInUseAuthorization(): void;
  allowsBackgroundLocationUpdates(allow: boolean): void;
  getAuthorizationStatus(): Promise<string>;
  startUpdatingLocation(): void;
  stopUpdatingLocation(): void;
  shouldDropEmptyRanges(drop: boolean): void;

  // --- Android only -------------------------------------------------------
  setHardwareEqualityEnforced(flag: boolean): void;
  addParser(parser: string): Promise<void>;
  removeParser(parser: string): Promise<void>;
  addParsersListToDetection(parsers: string[]): Promise<void>;
  removeParsersListToDetection(parsers: string[]): Promise<void>;
  setBackgroundScanPeriod(period: number): void;
  setBackgroundBetweenScanPeriod(period: number): void;
  setForegroundScanPeriod(period: number): void;
  setForegroundBetweenScanPeriod(period: number): void;
  setRssiFilter(filterType: number, avgModifier: number): void;
  checkTransmissionSupported(): Promise<number>;
  getRangedRegions(): Promise<Object[]>;

  // --- events -------------------------------------------------------------
  readonly onBeaconsDidRange: CodegenTypes.EventEmitter<Object>;
  readonly onRegionDidEnter: CodegenTypes.EventEmitter<Object>;
  readonly onRegionDidExit: CodegenTypes.EventEmitter<Object>;
  readonly onDidDetermineState: CodegenTypes.EventEmitter<Object>;
  readonly onAuthorizationStatusDidChange: CodegenTypes.EventEmitter<string>;
  readonly onBeaconServiceConnected: CodegenTypes.EventEmitter<Object>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('BeaconsManager');
