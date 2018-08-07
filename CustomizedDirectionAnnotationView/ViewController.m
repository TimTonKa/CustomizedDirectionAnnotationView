//
//  ViewController.m
//  CustomizedDirectionAnnotationView
//
//  Created by Tim on 2018/8/7.
//  Copyright © 2018年 Tim. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

@interface ViewController ()
<
 MKMapViewDelegate,
 CLLocationManagerDelegate
>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) MKAnnotationView *userDirectionAnnView;
@property (strong, nonatomic) CLLocationManager *locationMgr;
@property (strong, nonatomic) CLLocation *currentLocation;

@end

@implementation ViewController

-(void)initMapView {
	self.mapView.delegate = self;
	self.mapView.rotateEnabled = NO;
	self.mapView.showsUserLocation = YES;
	self.mapView.showsCompass = NO;
}

-(void)initLocationMgr {
	self.locationMgr = [[CLLocationManager alloc] init];
	//使用者移動多少距離後會更新座標點
	self.locationMgr.distanceFilter = kCLLocationAccuracyNearestTenMeters;
	//設定定位的精確度
	self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationMgr.delegate = self;
	if ([CLLocationManager locationServicesEnabled]) {
		[self.locationMgr requestWhenInUseAuthorization];
		[self.locationMgr startUpdatingLocation];
	} else {
		//Give default value to map
		double lat = 25.034727;
		double lon = 121.521622;
		double delta = 0.01;
		CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat, lon);
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coord, 200, 200);
		region.center.latitude = lat;
		region.center.longitude = lon;
		region.span.latitudeDelta = delta;
		region.span.longitudeDelta = delta;
		[self.mapView setRegion:region animated:NO];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self initMapView];
	[self initLocationMgr];
}


-(void)showTitle:(NSString*)title message:(NSString*)message  completion:(void (^)(bool ok))completion {
	
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		if (completion) {
			completion(YES);
		}
	}];
	
	[alertController addAction:okAction];
	[self presentViewController:alertController animated:YES completion:nil];
	
}


#pragma mark - Map Position
-(void)setMapRegion:(MKCoordinateRegion)region {
	[self.mapView setRegion:region animated:true];
}


#pragma mark - CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
	
	self.currentLocation = locations.lastObject;
	
	static dispatch_once_t changeRegionOnceToken;
	dispatch_once(&changeRegionOnceToken,^{
		//MKCoordinateRegion 這個類別是可以讀寫  region可以抓到地圖中心以及縮放比例
		MKCoordinateRegion region = self.mapView.region;
		region.center = self.currentLocation.coordinate;
		//span縮放 目前螢幕可看的範圍是0.01個經緯度的內容
		region.span.latitudeDelta = 0.01;
		region.span.longitudeDelta = 0.01;
		
		[self setMapRegion:region];
	});
}

-(void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	
	if (status == kCLAuthorizationStatusAuthorizedAlways ||
	    status == kCLAuthorizationStatusAuthorizedWhenInUse) {
		[self.locationMgr startUpdatingLocation];
		[self.locationMgr startUpdatingHeading];
	} else {
		[self.locationMgr stopUpdatingLocation];
		[self.locationMgr stopUpdatingHeading];		

		[self showTitle:@"定位權限已關閉" message:@"如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟" completion:nil];
	}
}

//是否要顯示校正視窗
-(BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return NO;
}

//更改direction
-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	
	double rotation = newHeading.magneticHeading * M_PI / 180;
	if (fabs([newHeading magneticHeading]) > 0.01) {
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		[self.userDirectionAnnView setTransform:CGAffineTransformMakeRotation(rotation)];
		[CATransaction commit];
	}
}


#pragma mark - MKMapViewDelegate
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
	
	static NSString *identify = @"userAnnIdentify";
	
	if ([annotation isKindOfClass:[MKUserLocation class]]) {
		self.userDirectionAnnView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:identify];
		if (!self.userDirectionAnnView) {
			self.userDirectionAnnView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identify];
		}
		self.userDirectionAnnView.image = [UIImage imageNamed:@"personDirection"];
		self.userDirectionAnnView.opaque = NO;
		self.userDirectionAnnView.canShowCallout = NO;
		self.userDirectionAnnView.draggable = NO;
		return self.userDirectionAnnView;
	}
	
	return nil;
}

-(void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
	
}

-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
	NSLog(@"Map view fail!");
}

-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
	
}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
	
	
}




- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
