//
//  AMapMarkerController.h
//  amap_flutter_map
//
//  Created by lly on 2020/11/3.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@class AMapMarker;

@interface AMapMarkerController : NSObject

- (instancetype)init:(FlutterMethodChannel*)methodChannel
             mapView:(MAMapView*)mapView
           registrar:(NSObject<FlutterPluginRegistrar>*)registrar;

- (nullable AMapMarker *)markerForId:(NSString *)markerId;

- (void)addMarkers:(NSArray*)markersToAdd;

- (void)changeMarkers:(NSArray*)markersToChange;

- (void)removeMarkerIds:(NSArray*)markerIdsToRemove;

//MARK: Marker的回调

- (BOOL)onMarkerTap:(NSString*)markerId;

- (BOOL)onMarker:(NSString *)markerId endPostion:(CLLocationCoordinate2D)position;

//- (BOOL)onInfoWindowTap:(NSString *)markerId;

/// 隐藏所有 InfoWindow
- (void)hideAllInfoWindows;

/// 隐藏指定 Marker 的 InfoWindow
- (void)hideInfoWindowByMarkerId:(NSString *)markerId;

/// 显示指定 Marker 的 InfoWindow
- (void)showInfoWindowByMarkerId:(NSString *)markerId;

@end

NS_ASSUME_NONNULL_END
