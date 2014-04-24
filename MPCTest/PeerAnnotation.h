//
//  PeerAnnotation.h
//  MPCTest
//
//  Created by Tom K on 3/30/14.
//  Copyright (c) 2014 Tom Kraina. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MKAnnotation.h>
@class MCPeerID;
@class MKCircle;

@interface PeerAnnotation : NSObject <MKAnnotation>

@property (strong, nonatomic) MCPeerID *peerID;
@property (strong, nonatomic) NSDictionary *discoveryInfo;

@property (strong, nonatomic, readonly) MKCircle *overlay;
@property (nonatomic, readonly) CLLocationDistance radius;

- (instancetype)initWithPeer:(MCPeerID *)peerID discoveryInfo:(NSDictionary *)info;

@end
