//
//  ViewController.m
//  MPCTest
//
//  Created by Tom K on 3/30/14.
//  Copyright (c) 2014 Tom Kraina. All rights reserved.
//

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

#import <CoreBluetooth/CoreBluetooth.h>

#import "PeerAnnotation.h"

static NSString * const XXServiceType = @"mp-location";

@interface MapViewController () <MKMapViewDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCBrowserViewControllerDelegate, CLLocationManagerDelegate, CBPeripheralManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) MCPeerID *localPeerID;

@property (strong, nonatomic) MCNearbyServiceAdvertiser *advertiser;
@property (strong, nonatomic) MCNearbyServiceBrowser *browser;
@property (strong, nonatomic) MCSession *session;
@property (nonatomic) BOOL initializer;

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) NSDictionary *peripheralData;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) MCPeerID *peerToAnswer;

@property (nonatomic, getter = isAdvertisingiBeacon) BOOL advertisingiBeacon;

@property (strong, nonatomic) NSMutableDictionary *peerBeaconTable;

@property (weak, nonatomic) MKAnnotationView *selectedAnnotationView;

@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.mapView.showsUserLocation = YES;
    self.mapView.showsBuildings = YES;
    
    [self startBrowsing];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Properties
- (NSMutableDictionary *)peerBeaconTable
{
    if (_peerBeaconTable == nil) {
        _peerBeaconTable = [NSMutableDictionary dictionary];
    }
    
    return _peerBeaconTable;
}

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (IBAction)broadcastTapped:(id)sender
{
    [self startBeaconing];
}
- (IBAction)rangeTapped:(id)sender
{
    [self startRangingForRegion:[[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"FC335F6F-996A-47F5-8E26-BADBA8D4149A"] identifier:@"com.tomkraina.demo"]];
}

- (MCPeerID *)localPeerID
{
    if (!_localPeerID) {
        _localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    }
    
    return _localPeerID;
}

- (NSDictionary *)localDiscoveryInfo
{
    return @{@"lat": [NSString stringWithFormat:@"%f", self.mapView.userLocation.coordinate.latitude],
             @"long": [NSString stringWithFormat:@"%f", self.mapView.userLocation.coordinate.longitude],
             @"image-url": @"",
             @"a": [NSString stringWithFormat:@"%ld", (long)round(self.mapView.userLocation.location.horizontalAccuracy)]};
}

- (void)setAdvertisingiBeacon:(BOOL)advertisingiBeacon
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *newTitle;
        if (advertisingiBeacon == NO)
        {
            newTitle = @"Start iBeacon";
        }
        else
        {
            newTitle = @"Stop iBeacon";
        }
        
        UIBarButtonItem *newBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:newTitle style:UIBarButtonItemStyleDone target:self.navigationItem.rightBarButtonItem.target action:self.navigationItem.rightBarButtonItem.action];
        self.navigationItem.rightBarButtonItem = newBarButtonItem;
        
        _advertisingiBeacon = advertisingiBeacon;

    });
}

#pragma mark - IBAction

- (IBAction)toggleiBeacon:(id)sender
{
    if (self.peripheralManager.isAdvertising) {
        [self stopBeaconing];
    }
    else
    {
        [self startBeaconing];
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    //restart advertising with new data
    [self.advertiser stopAdvertisingPeer];
    [self startAdvertising];
    
    NSLog(@"didUpdateUserLocation: %@", userLocation);
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 250, 300);
    
    [self.mapView setRegion:region
                   animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (annotation == self.mapView.userLocation) {
        return nil;
    }
    
    static NSString *Identifier = @"PeerAnnotation";
    
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:Identifier];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:Identifier];
        annotationView.pinColor = MKPinAnnotationColorPurple;
        annotationView.canShowCallout = YES;
        
        annotationView.rightCalloutAccessoryView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32.0, 32.0)];
    }
    
    [self updateAnnotationView:annotationView forBeaconRegion:self.peerBeaconTable[annotation]];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    NSMutableDictionary *info  =[((PeerAnnotation *)view.annotation).discoveryInfo mutableCopy];
    info[@"proximity"] = @"Connecting...";
    ((PeerAnnotation *)view.annotation).discoveryInfo = [info copy];
    
    // connect
    MCPeerID *peerID = ((PeerAnnotation *)view.annotation).peerID;
    
    NSLog(@"Connecting to peer: %@", peerID);
    
    MCSession *session = [[MCSession alloc] initWithPeer:self.localPeerID
                                        securityIdentity:nil
                                    encryptionPreference:MCEncryptionNone];
    session.delegate = self;
    self.session = session;
    
    [self.browser invitePeer:peerID toSession:session withContext:nil timeout:60];
    
    self.initializer = YES;
    
    self.selectedAnnotationView = view;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:(MKCircle *)overlay];
    circleView.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.15];
    return circleView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    PeerAnnotation *peerAnnotation = (PeerAnnotation *)view.annotation;
    CLBeaconRegion *beaconRegion = self.peerBeaconTable[peerAnnotation.peerID];
    
    BOOL isBeaconMonitored = NO;
    
    // This may not work beacuse monitored region may be more 'general'
    isBeaconMonitored = [self.locationManager.monitoredRegions containsObject:beaconRegion];
    
    if (isBeaconMonitored)
    {
        NSLog(@"Stopping monitoring region: %@", beaconRegion);
        [self.locationManager stopMonitoringForRegion:beaconRegion];
    }
    else
    {
        NSLog(@"Starting monitoring region: %@", beaconRegion);
        [self.locationManager startMonitoringForRegion:beaconRegion];
    }
    
    [self updateAnnotationView:view forBeaconRegion:beaconRegion];
}

- (void)updateAnnotationView:(MKAnnotationView *)view forBeaconRegion:(CLBeaconRegion *)beaconRegion
{
    ((UIButton *)view.rightCalloutAccessoryView).enabled = beaconRegion != nil;
    
    if (beaconRegion == nil) {
        return;
    }
    
    BOOL isBeaconMonitored = NO;
    
    // This may not work beacuse monitored region may be more 'general'
    isBeaconMonitored = [self.locationManager.monitoredRegions containsObject:beaconRegion];
    
    if (isBeaconMonitored)
    {
        [(UIButton *)view.rightCalloutAccessoryView setImage:[UIImage imageNamed:@"unstar"] forState:UIControlStateNormal];
    }
    else
    {
        [(UIButton *)view.rightCalloutAccessoryView setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
    }
}


#pragma mark - Multipeer

- (void)startAdvertising
{
    MCNearbyServiceAdvertiser *advertiser =
    [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                      discoveryInfo:[self localDiscoveryInfo]
                                        serviceType:XXServiceType];
    
    advertiser.delegate = self;
    [advertiser startAdvertisingPeer];
    
    self.advertiser = advertiser;
}

- (void)startBrowsing
{
    MCNearbyServiceBrowser *browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.localPeerID serviceType:XXServiceType];
    browser.delegate = self;
    
     NSLog(@"Start browsing");

    [browser startBrowsingForPeers];

    self.browser = browser;
}

#pragma mark - MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    NSLog(@"browserViewControllerDidFinish");
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Stop browsing");
        [self.browser stopBrowsingForPeers];
    }];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    NSLog(@"browserViewControllerWasCancelled");
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Stop browsing");
        [self.browser stopBrowsingForPeers];
    }];
}

- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"peer: %@, info: %@", peerID.displayName, info);
    
    return YES;
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser
didReceiveInvitationFromPeer:(MCPeerID *)peerID
       withContext:(NSData *)context
 invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler
{
    NSLog(@"Accepting invitation from: %@", peerID.displayName);
    
    
      MCSession *session = [[MCSession alloc] initWithPeer:self.localPeerID
                                          securityIdentity:nil
                                      encryptionPreference:MCEncryptionNone];
      session.delegate = self;
    self.session = session;
    
      invitationHandler(YES, session); // automatically accept invitations
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"error: %@", error);
}

#pragma mark - MCNearbyServiceBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"error: %@", error);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Found peer: %@ info: %@", peerID.displayName, info);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        PeerAnnotation *annotation = [[PeerAnnotation alloc] initWithPeer:peerID discoveryInfo:info];
        
        [self.mapView addAnnotation:annotation];
        [self.mapView addOverlay:annotation.overlay];
    });
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Lost peer: %@", peerID.displayName);
    
    NSArray *annotations = [self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if (evaluatedObject == self.mapView.userLocation) {
            return NO;
        }
        return [((PeerAnnotation *)evaluatedObject).peerID isEqual:peerID];
    }]];
    
    for (PeerAnnotation *annotationToRemove in annotations) {
        [self.mapView removeOverlay:annotationToRemove.overlay];
        [self.mapView removeAnnotation:annotationToRemove];
    }
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"Session: %@ with peer: %@ state: %d", session, peerID.displayName, state);
    
    if (state == MCSessionStateConnected)
    {
        // This is not main thread!
        dispatch_async(dispatch_get_main_queue(), ^{
            PeerAnnotation *annotation = [self.mapView.selectedAnnotations firstObject];
            NSMutableDictionary *info = [annotation.discoveryInfo mutableCopy];
            info[@"proximity"] = @"Connected";
            annotation.discoveryInfo = [info copy];
        });
    }
    
    // start iBeacon distance measurement
    if (state == MCSessionStateConnected && self.initializer) {
        // tell the other one to start iBeacon
        [self sendStartBeaconMessageToPeer:peerID];
    }
    
}

- (void)sendStartBeaconMessageToPeer:(MCPeerID *)peerID
{
    NSLog(@"sendStartBeaconMessageToPeer: %@", peerID.displayName);
    
    NSDictionary *object = @{@"action": @"start"};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    NSError *error = nil;
    if (![self.session sendData:data
                        toPeers:@[peerID]
                       withMode:MCSessionSendDataReliable
                          error:&error]) {
        NSLog(@"[Error] %@", error);
    }
}

- (void)sendBeaconStartedMessageToPeer:(MCPeerID *)peerID
{
    NSLog(@"sendBeaconStartedMessageToPeer: %@", peerID.displayName);
    
    id <NSSecureCoding> object = @{@"status": @"started",
                                   @"region": self.beaconRegion};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    NSError *error = nil;
    if (![self.session sendData:data
                        toPeers:@[peerID]
                       withMode:MCSessionSendDataReliable
                          error:&error]) {
        NSLog(@"[Error] %@", error);
    }
}



- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    unarchiver.requiresSecureCoding = YES;
//    id object = [unarchiver decodeObject];
//    [unarchiver finishDecoding];
    NSLog(@"received: %@", dict);
    
    if ([dict[@"action"] isEqualToString:@"start"]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.peerToAnswer = peerID;
            [self startBeaconing];
        });
    }
    else if ([dict[@"status"] isEqualToString:@"started"])
    {
        // This is not main thread!
        dispatch_async(dispatch_get_main_queue(), ^{
            
            PeerAnnotation *annotation = [self.mapView.selectedAnnotations firstObject];
            NSMutableDictionary *info = [annotation.discoveryInfo mutableCopy];
            info[@"proximity"] = @"iBeacon";
            annotation.discoveryInfo = [info copy];
            
            [(CLBeaconRegion *)dict[@"region"] setNotifyEntryStateOnDisplay:YES];
            self.peerBeaconTable[ peerID ] = dict[@"region"];
            
            [self updateAnnotationView:self.selectedAnnotationView forBeaconRegion:dict[@"region"]];
            
            [self startRangingForRegion:dict[@"region"]];
        });
    }
}

// Must be here in order to start a session
- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

#pragma mark - beacon stuff

- (void)startBeaconing
{
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"FC335F6F-996A-47F5-8E26-BADBA8D4149A"] major:1 minor:1 identifier:@"com.tomkraina.demo"];
    
    if (self.peerToAnswer) {
        [self sendBeaconStartedMessageToPeer:self.peerToAnswer];
    }
    
    self.peripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:nil
                                                                   options:nil];
}

- (void)stopBeaconing
{
    [self.peripheralManager stopAdvertising];
    
    [self setAdvertisingiBeacon:NO];
}

// FC335F6F-996A-47F5-8E26-BADBA8D4149A
- (void)startRangingForRegion:(CLBeaconRegion *)region
{
    region = [[CLBeaconRegion alloc] initWithProximityUUID:region.proximityUUID major:[region.major doubleValue] minor:[region.minor doubleValue] identifier:region.identifier];
    
    NSLog(@"startRangingForRegion: %@", region);
    
//    [self.session disconnect];
//    [self.browser stopBrowsingForPeers];
//    [self.advertiser stopAdvertisingPeer];
    
    [self.locationManager startRangingBeaconsInRegion:region];
    NSLog(@"Started ranging for region: %@", region);
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"didRangeBeacons: %@", beacons);
    
    CLBeacon *beacon = [beacons firstObject];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        PeerAnnotation *annotation = (PeerAnnotation *) [self.mapView.selectedAnnotations firstObject];
        
        NSMutableDictionary *dict = [annotation.discoveryInfo mutableCopy];
        dict[@"proximity"] = [NSString stringWithFormat:@"iBeacon: %@", [self formatiBeaconProximity:beacon]];
        annotation.discoveryInfo = [dict copy];
    });
}

- (NSString *)formatiBeaconProximity:(CLBeacon *)beacon
{
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityImmediate:
            proximity = @"Immediate";
            break;
            
        case CLProximityNear:
            proximity = @"Near";
            break;
            
        case CLProximityFar:
            proximity = @"Far";
            break;
            
        default:
            proximity = @"Unknown";
            break;
    }
    
    NSString *output = [NSString stringWithFormat:@"%@ +/-%.2fm", proximity ,beacon.accuracy];
    return output;
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"rangingBeaconsDidFailForRegion: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion: %@, error: %@", region, error);
    
    [(UIButton *)self.selectedAnnotationView.rightCalloutAccessoryView setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"didEnterRegion: %@", region);
    
    // Post local notification
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Your buddy is nearby!";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    
    // try make a network request
    NSError *error;
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://placekitten.com/g/200/300"] options:NSDataReadingUncached error:&error];
    UIImage *image = [UIImage imageWithData:imageData];
    NSLog(@"Image downloaded: %@, error: %@", image, error);
    
    // TODO: check if I can turn on iBeacon or MP Connectivity here
    [self startBeaconing];
    
    [self.advertiser startAdvertisingPeer];
    [self.browser startBrowsingForPeers];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"didExitRegion: %@", region);
}

#pragma mark - CBPeripheralManagerDelegate

-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    NSLog(@"peripheralManagerDidUpdateState: %d", peripheral.state);
    
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Powered On... Staring iBeacon");
        
//        [self.session disconnect];
//        [self.browser stopBrowsingForPeers];
//        [self.advertiser stopAdvertisingPeer];
        
        [self.peripheralManager startAdvertising:self.peripheralData];
    }
    else if (peripheral.state == CBPeripheralManagerStatePoweredOff) {
        NSLog(@"Powered Off");
        [self.peripheralManager stopAdvertising];
        [self setAdvertisingiBeacon:NO];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"Started iBeaconing (error: %@)", error);
    NSLog(@"Started iBeaconing for region: %@", self.beaconRegion);
    
    if (error == nil) {
        [self setAdvertisingiBeacon:YES];
    }
}

@end
