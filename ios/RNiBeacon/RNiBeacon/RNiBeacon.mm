//
//  RNiBeacon.mm
//  RNiBeacon
//
//  Created by MacKentoch on 17/02/2017.
//  Copyright © 2017 Erwan DATIN. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import <React/RCTConvert.h>
#import "ESSBeaconScanner.h"
#import "ESSEddystone.h"

#import "RNiBeacon.h"

static NSString *const kEddystoneRegionID = @"EDDY_STONE_REGION_ID";

@interface RNiBeacon() <CLLocationManagerDelegate, ESSBeaconScannerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) ESSBeaconScanner *eddyStoneScanner;
@property (assign, nonatomic) BOOL dropEmptyRanges;

@end

@implementation RNiBeacon

RCT_EXPORT_MODULE(BeaconsManager)

#pragma mark Initialization

- (instancetype)init
{
  if (self = [super init]) {
    self.locationManager = [[CLLocationManager alloc] init];

    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.dropEmptyRanges = NO;

    self.eddyStoneScanner = [[ESSBeaconScanner alloc] init];
    self.eddyStoneScanner.delegate = self;
  }

  return self;
}

// CLLocationManager delivers delegate callbacks on the thread it was created on.
+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
  return std::make_shared<facebook::react::NativeBeaconsManagerSpecJSI>(params);
}

#pragma mark Region conversion

-(CLBeaconRegion *) createBeaconRegion: (NSString *) identifier
                                  uuid: (NSString *) uuid
                                 major: (NSInteger) major
                                 minor:(NSInteger) minor
{
  NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:uuid];

  unsigned short mj = (unsigned short) major;
  unsigned short mi = (unsigned short) minor;

  CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID major:mj
                                                                         minor:mi
                                                                    identifier:identifier];

  beaconRegion.notifyOnEntry = YES;
  beaconRegion.notifyOnExit = YES;
  beaconRegion.notifyEntryStateOnDisplay = YES;

  return beaconRegion;
}

-(CLBeaconRegion *) createBeaconRegion: (NSString *) identifier
                                  uuid: (NSString *) uuid
                                 major: (NSInteger) major
{
  NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:uuid];

  unsigned short mj = (unsigned short) major;

  CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID
                                                                         major:mj
                                                                    identifier:identifier];

  beaconRegion.notifyOnEntry = YES;
  beaconRegion.notifyOnExit = YES;
  beaconRegion.notifyEntryStateOnDisplay = YES;

  return beaconRegion;
}

-(CLBeaconRegion *) createBeaconRegion: (NSString *) identifier
                                  uuid: (NSString *) uuid
{
  NSUUID *beaconUUID = [[NSUUID alloc] initWithUUIDString:uuid];

  CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:beaconUUID
                                                                    identifier:identifier];

  beaconRegion.notifyOnEntry = YES;
  beaconRegion.notifyOnExit = YES;
  beaconRegion.notifyEntryStateOnDisplay = YES;

  return beaconRegion;
}

-(CLBeaconRegion *) convertDictToBeaconRegion: (NSDictionary *) dict
{
  // JS passes absent values as missing keys (null is treated the same).
  id major = dict[@"major"];
  id minor = dict[@"minor"];
  BOOL hasMajor = major != nil && major != [NSNull null];
  BOOL hasMinor = minor != nil && minor != [NSNull null];

  NSString *identifier = [RCTConvert NSString:dict[@"identifier"]];
  NSString *uuid = [RCTConvert NSString:dict[@"uuid"]];

  if (!hasMinor) {
    if (!hasMajor) {
      return [self createBeaconRegion:identifier uuid:uuid];
    }
    return [self createBeaconRegion:identifier uuid:uuid major:[RCTConvert NSInteger:major]];
  }
  return [self createBeaconRegion:identifier
                             uuid:uuid
                            major:[RCTConvert NSInteger:major]
                            minor:[RCTConvert NSInteger:minor]];
}

-(NSDictionary *) convertBeaconRegionToDict: (CLBeaconRegion *) region
{
  if (region.minor == nil) {
    if (region.major == nil) {
      return @{
               @"identifier": region.identifier,
               @"uuid": [region.proximityUUID UUIDString],
               };
    } else {
      return @{
               @"identifier": region.identifier,
               @"uuid": [region.proximityUUID UUIDString],
               @"major": region.major
               };
    }
  } else {
    return @{
             @"identifier": region.identifier,
             @"uuid": [region.proximityUUID UUIDString],
             @"major": region.major,
             @"minor": region.minor
             };
  }
}

-(NSString *)stringForProximity:(CLProximity)proximity {
  switch (proximity) {
    case CLProximityUnknown:    return @"unknown";
    case CLProximityFar:        return @"far";
    case CLProximityNear:       return @"near";
    case CLProximityImmediate:  return @"immediate";
    default:                    return @"";
  }
}

#pragma mark - iOS only

- (void)requestAlwaysAuthorization
{
  [self.locationManager requestAlwaysAuthorization];
}

- (void)requestWhenInUseAuthorization
{
  [self.locationManager requestWhenInUseAuthorization];
}

- (void)allowsBackgroundLocationUpdates:(BOOL)allow
{
  self.locationManager.allowsBackgroundLocationUpdates = allow;
}

- (void)getAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                        reject:(RCTPromiseRejectBlock)reject
{
  resolve([self nameForAuthorizationStatus:self.locationManager.authorizationStatus]);
}

- (void)startUpdatingLocation
{
  [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation
{
  [self.locationManager stopUpdatingLocation];
}

- (void)shouldDropEmptyRanges:(BOOL)drop
{
  self.dropEmptyRanges = drop;
}

#pragma mark - Common

- (void)getMonitoredRegions:(RCTPromiseResolveBlock)resolve
                     reject:(RCTPromiseRejectBlock)reject
{
  NSMutableArray *regionArray = [[NSMutableArray alloc] init];

  for (CLRegion *region in self.locationManager.monitoredRegions) {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
      [regionArray addObject:[self convertBeaconRegionToDict:(CLBeaconRegion *)region]];
    }
  }

  resolve(regionArray);
}

- (void)startMonitoringForRegion:(NSDictionary *)region
                         resolve:(RCTPromiseResolveBlock)resolve
                          reject:(RCTPromiseRejectBlock)reject
{
  [self.locationManager startMonitoringForRegion:[self convertDictToBeaconRegion:region]];
  resolve(nil);
}

- (void)stopMonitoringForRegion:(NSDictionary *)region
                        resolve:(RCTPromiseResolveBlock)resolve
                         reject:(RCTPromiseRejectBlock)reject
{
  [self.locationManager stopMonitoringForRegion:[self convertDictToBeaconRegion:region]];
  resolve(nil);
}

- (void)startRangingBeaconsInRegion:(NSDictionary *)region
                            resolve:(RCTPromiseResolveBlock)resolve
                             reject:(RCTPromiseRejectBlock)reject
{
  if ([region[@"identifier"] isEqualToString:kEddystoneRegionID]) {
    [self.eddyStoneScanner startScanning];
  } else {
    [self.locationManager startRangingBeaconsInRegion:[self convertDictToBeaconRegion:region]];
  }
  resolve(nil);
}

- (void)stopRangingBeaconsInRegion:(NSDictionary *)region
                           resolve:(RCTPromiseResolveBlock)resolve
                            reject:(RCTPromiseRejectBlock)reject
{
  if ([region[@"identifier"] isEqualToString:kEddystoneRegionID]) {
    [self.eddyStoneScanner stopScanning];
  } else {
    [self.locationManager stopRangingBeaconsInRegion:[self convertDictToBeaconRegion:region]];
  }
  resolve(nil);
}

- (void)requestStateForRegion:(NSDictionary *)region
{
  [self.locationManager requestStateForRegion:[self convertDictToBeaconRegion:region]];
}

#pragma mark - Android only (no-ops on iOS)

- (void)setHardwareEqualityEnforced:(BOOL)flag {}

- (void)addParser:(NSString *)parser
          resolve:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject
{
  resolve(nil);
}

- (void)removeParser:(NSString *)parser
             resolve:(RCTPromiseResolveBlock)resolve
              reject:(RCTPromiseRejectBlock)reject
{
  resolve(nil);
}

- (void)addParsersListToDetection:(NSArray *)parsers
                          resolve:(RCTPromiseResolveBlock)resolve
                           reject:(RCTPromiseRejectBlock)reject
{
  resolve(nil);
}

- (void)removeParsersListToDetection:(NSArray *)parsers
                             resolve:(RCTPromiseResolveBlock)resolve
                              reject:(RCTPromiseRejectBlock)reject
{
  resolve(nil);
}

- (void)setBackgroundScanPeriod:(double)period {}
- (void)setBackgroundBetweenScanPeriod:(double)period {}
- (void)setForegroundScanPeriod:(double)period {}
- (void)setForegroundBetweenScanPeriod:(double)period {}
- (void)setRssiFilter:(double)filterType avgModifier:(double)avgModifier {}

- (void)checkTransmissionSupported:(RCTPromiseResolveBlock)resolve
                            reject:(RCTPromiseRejectBlock)reject
{
  // 1 = NOT_SUPPORTED_MIN_SDK (index into transmissionSupport in JS)
  resolve(@1);
}

- (void)getRangedRegions:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
{
  NSMutableArray *regionArray = [[NSMutableArray alloc] init];

  for (CLRegion *region in self.locationManager.rangedRegions) {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
      [regionArray addObject:[self convertBeaconRegionToDict:(CLBeaconRegion *)region]];
    }
  }

  resolve(regionArray);
}

#pragma mark - CLLocationManagerDelegate

-(NSString *)nameForAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
  switch (authorizationStatus) {
    case kCLAuthorizationStatusAuthorizedAlways:
      return @"authorizedAlways";

    case kCLAuthorizationStatusAuthorizedWhenInUse:
      return @"authorizedWhenInUse";

    case kCLAuthorizationStatusDenied:
      return @"denied";

    case kCLAuthorizationStatusNotDetermined:
      return @"notDetermined";

    case kCLAuthorizationStatusRestricted:
      return @"restricted";

    default:
      return @"notDetermined";
  }
}

-(void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
  [self emitOnAuthorizationStatusDidChange:[self nameForAuthorizationStatus:manager.authorizationStatus]];
}

-(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
  NSLog(@"Failed ranging region: %@", error);
}

-(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
  NSLog(@"Failed monitoring region: %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  NSLog(@"Location manager failed: %@", error);
}

-(NSString *)stringForState:(CLRegionState)state {
  switch (state) {
    case CLRegionStateInside:   return @"inside";
    case CLRegionStateOutside:  return @"outside";
    case CLRegionStateUnknown:  return @"unknown";
    default:                    return @"unknown";
  }
}

- (void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
  NSDictionary *event = @{
                          @"state":   [self stringForState:state],
                          @"identifier":  region.identifier,
                          };
  [self emitOnDidDetermineState:event];
}

-(void) locationManager:(CLLocationManager *)manager didRangeBeacons:
(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
  if (self.dropEmptyRanges && beacons.count == 0) {
    return;
  }
  NSMutableArray *beaconArray = [[NSMutableArray alloc] init];

  for (CLBeacon *beacon in beacons) {
    [beaconArray addObject:@{
                             @"uuid": [beacon.proximityUUID UUIDString],
                             @"major": beacon.major,
                             @"minor": beacon.minor,

                             @"rssi": [NSNumber numberWithLong:beacon.rssi],
                             @"proximity": [self stringForProximity: beacon.proximity],
                             @"accuracy": [NSNumber numberWithDouble: beacon.accuracy],
                             @"distance": [NSNumber numberWithDouble: beacon.accuracy],
                             }];
  }

  NSDictionary *event = @{
                          @"region": @{
                              @"identifier": region.identifier,
                              @"uuid": [region.proximityUUID UUIDString],
                              },
                          @"beacons": beaconArray
                          };

  [self emitOnBeaconsDidRange:event];
}

-(void)locationManager:(CLLocationManager *)manager
        didEnterRegion:(CLBeaconRegion *)region {

  if (! [region respondsToSelector:@selector(proximityUUID)]) {
    return;
  }

  [self emitOnRegionDidEnter:[self convertBeaconRegionToDict: region]];
}

-(void)locationManager:(CLLocationManager *)manager
         didExitRegion:(CLBeaconRegion *)region {

  if (! [region respondsToSelector:@selector(proximityUUID)]) {
    return;
  }

  [self emitOnRegionDidExit:[self convertBeaconRegionToDict: region]];
}

#pragma mark - Eddystone

- (void)beaconScanner:(ESSBeaconScanner *)scanner didRangeBeacon:(NSArray *)beacons {
  [self notifyAboutBeaconChanges:beacons];
}

- (void)notifyAboutBeaconChanges:(NSArray *)beacons {
  NSMutableArray *beaconArray = [[NSMutableArray alloc] init];

  for (id key in beacons) {
    ESSBeaconInfo *beacon = key;
    NSDictionary *info = [self getEddyStoneInfo:beacon];
    [beaconArray addObject:info];
  }
  NSDictionary *event = @{
                          @"region": @{
                              @"identifier": kEddystoneRegionID,
                              @"uuid": @"", // do not use for eddy stone
                              },
                          @"beacons": beaconArray
                          };
  [self emitOnBeaconsDidRange:event];
}

- (NSDictionary*)getEddyStoneInfo:(id)beaconInfo {
  ESSBeaconInfo *info = beaconInfo;
  NSNumber *distance = [self calculateDistance:info.txPower rssi:info.RSSI];
  NSString *identifier = [self getEddyStoneUUID:info.beaconID.beaconID];
  NSDictionary *beaconData = @{
                               @"identifier": identifier,
                               @"uuid": identifier,
                               @"rssi": info.RSSI,
                               @"txPower": info.txPower,
                               @"distance": distance,
                               };
  return beaconData;
}

- (NSNumber*)calculateDistance:(NSNumber*)txPower rssi:(NSNumber*) rssi {
  if ([rssi floatValue] >= 0){
    return [NSNumber numberWithInt:-1];
  }

  float ratio = [rssi floatValue] / ([txPower floatValue] - 41);
  if (ratio < 1.0) {
    return [NSNumber numberWithFloat:pow(ratio, 10)];
  }

  float distance = (0.89976) * pow(ratio, 7.7095) + 0.111;
  return [NSNumber numberWithFloat:distance];
}

- (NSString *)getEddyStoneUUID:(NSData*)data {
  const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
  const int EDDYSTONE_UUID_LENGTH = 10;
  if (!dataBuffer) {
    return [NSString string];
  }

  NSMutableString *hexString  = [NSMutableString stringWithCapacity:(data.length * 2)];
  [hexString appendString:@"0x"];
  for (int i = 0; i < EDDYSTONE_UUID_LENGTH; ++i) {
    [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
  }

  return [NSString stringWithString:hexString];
}

@end
