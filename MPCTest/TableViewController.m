//
//  TableViewController.m
//  MPCTest
//
//  Created by Tom K on 4/2/14.
//  Copyright (c) 2014 Tom Kraina. All rights reserved.
//

#import "TableViewController.h"
#import <MapKit/MapKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <CoreBluetooth/CoreBluetooth.h>


@interface TableViewController () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) NSMutableArray *rangedRegions;
@property (strong, nonatomic) NSArray *rangingRegions;

@property (nonatomic, getter = isRanging) BOOL ranging;

@property (strong, nonatomic) CLBeaconRegion *beaconRegion;

@end

@implementation TableViewController


#pragma mark - properties

- (NSMutableArray *)rangedRegions
{
    if (_rangedRegions == nil) {
        _rangedRegions = [NSMutableArray array];
    }
    
    return _rangedRegions;
}

- (CLLocationManager *)locationManager
{
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (CLBeaconRegion *)beaconRegion
{
    if (_beaconRegion == nil)
    {
        _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"FC335F6F-996A-47F5-8E26-BADBA8D4149A"] identifier:@"com.tomkraina.demo"];
    }
    
    return _beaconRegion;
}

#pragma mark - IBAction

- (IBAction)toggleRanging:(id)sender
{
    if (self.isRanging) {
        [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
        self.ranging = NO;
        [self.rangedRegions removeObject:self.beaconRegion];
        self.rangingRegions = nil;
    }
    else
    {
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
        self.ranging = YES;
        [self.rangedRegions addObject:self.beaconRegion];
    }
    
    [self updateRangingButton];
}
- (void)updateRangingButton
{
    [self.tableView reloadData];
    
    if (self.isRanging)
    {
        [self.navigationItem.rightBarButtonItem setTitle:@"Stop ranging"];
    }
    else
    {
        [self.navigationItem.rightBarButtonItem setTitle:@"Start ranging"];
    }
}

#pragma mark - UIViewController live cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

NS_ENUM(NSInteger, TableViewControllerSections) {
    TableViewControllerSectionRangedRegions,
    TableViewControllerSectionRangingRegions,
    TableViewControllerSectionCount
};

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return TableViewControllerSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case TableViewControllerSectionRangedRegions:
            return [self.rangedRegions count];
            break;
        
        case TableViewControllerSectionRangingRegions:
            return [self.rangingRegions count];
            break;
            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RegionCell" forIndexPath:indexPath];
    
    // Configure the cell...
    switch (indexPath.section) {
        case TableViewControllerSectionRangedRegions:
            [self configureRangedCell:cell atRow:indexPath.row];
            break;
        case TableViewControllerSectionRangingRegions:
            [self configureRangingCell:cell atRow:indexPath.row];
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)configureRangedCell:(UITableViewCell *)cell atRow:(NSInteger)row
{
    CLBeaconRegion *beaconRegion = self.rangedRegions[row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@, %@", [beaconRegion.proximityUUID UUIDString], beaconRegion.major, beaconRegion.minor];
}

- (void)configureRangingCell:(UITableViewCell *)cell atRow:(NSInteger)row
{
    CLBeacon *beacon = self.rangingRegions[row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@..., %@, %@", [[beacon.proximityUUID UUIDString] substringToIndex:6], beacon.major, beacon.minor];
    cell.detailTextLabel.text = [self formatiBeaconProximity:beacon];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case TableViewControllerSectionRangedRegions:
            return @"Ranged Regions";
            break;

        case TableViewControllerSectionRangingRegions:
            return @"Ranging...";
            break;
            
        default:
            return nil;
            break;
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"didRangeBeacons: %@", beacons);
    
    self.ranging = YES;
    [self updateRangingButton];
    
    self.rangingRegions = beacons;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:TableViewControllerSectionRangingRegions] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    self.ranging = NO;
    [self.rangedRegions removeObject:region];
    self.rangingRegions = nil;
    [self updateRangingButton];
}

@end
