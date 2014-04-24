//
//  PeerAnnotation.m
//  MPCTest
//
//  Created by Tom K on 3/30/14.
//  Copyright (c) 2014 Tom Kraina. All rights reserved.
//

#import "PeerAnnotation.h"

#import <MultipeerConnectivity/MCPeerID.h>
#import <MapKit/MKCircle.h>

@interface PeerAnnotation ()
//@property (copy, nonatomic, readwrite) NSString *subtitle;
@property (strong, nonatomic, readwrite) MKCircle *overlay;
@end

@implementation PeerAnnotation

- (instancetype)initWithPeer:(MCPeerID *)peerID discoveryInfo:(NSDictionary *)info
{
    self = [super init];
    if (self) {
        _peerID = peerID;
        _discoveryInfo = info;
    }
    
    return self;
}

- (MKCircle *)overlay
{
    if (!_overlay) {
        _overlay = [MKCircle circleWithCenterCoordinate:self.coordinate radius:self.radius];
    }
    
    return _overlay;
}

- (CLLocationDistance)radius
{
    return [self.discoveryInfo[@"a"] doubleValue];
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.discoveryInfo[@"lat"] doubleValue], [self.discoveryInfo[@"long"] doubleValue]);
}

- (NSString *)title
{
    return self.peerID.displayName;
}

- (NSString *)subtitle
{
    return self.discoveryInfo[@"proximity"];
}

- (BOOL)isEqual:(PeerAnnotation *)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return [self.peerID isEqual:object.peerID];
}

- (NSUInteger)hash
{
    return [self.peerID hash];
}

+ (NSSet *)keyPathsForValuesAffectingRadius
{
    return [NSSet setWithObject:@"discoveryInfo"];
}

+ (NSSet *)keyPathsForValuesAffectingSubtitle
{
    return [NSSet setWithObject:@"discoveryInfo"];
}

//+ (BOOL)automaticallyNotifiesObserversForSubtitle;
//{
//    return NO;
//}

- (void)setDiscoveryInfo:(NSDictionary *)discoveryInfo
{
    if (_discoveryInfo == discoveryInfo) {
        return;
    }

//    NSLog(@"%@ subtitle changing: %@ -> %@",self.title, _discoveryInfo[@"proximity"], discoveryInfo[@"proximity"]);
    
//    [self willChangeValueForKey:@"coordinate"];
//    [self willChangeValueForKey:@"title"];
//    [self willChangeValueForKey:@"subtitle"];
    
    _discoveryInfo = discoveryInfo;
//    self.subtitle = discoveryInfo[@"proximity"];

    //    [self didChangeValueForKey:@"coordinate"];
//    [self didChangeValueForKey:@"title"];
//    [self didChangeValueForKey:@"subtitle"];
}

@end
