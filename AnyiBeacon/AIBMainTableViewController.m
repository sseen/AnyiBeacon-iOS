//
//  AIBMainTableViewController.m
//  AnyiBeacon
//
//  Created by jaume on 30/04/14.
//  Copyright (c) 2014 Sandeep Mistry. All rights reserved.
//

#import "AIBMainTableViewController.h"
#import "AIBBeaconRegionAny.h"
#import "AIBUtils.h"
#import "AIBDetailViewController.h"

#define  kCellIdentifier @"cellBeaconIdentifier"

@import CoreLocation;

@interface AIBMainTableViewController ()<CLLocationManagerDelegate>

@property(nonatomic, strong) NSDictionary*		beaconsDict;
@property(nonatomic, strong) CLLocationManager* locationManager;
@property(nonatomic, strong) NSArray*            listUUID;
@property(nonatomic, strong) NSMutableArray*	logListUUID;
@property(nonatomic)         BOOL                sortByMajorMinor;
@property(nonatomic)		 BOOL				isStartLog;
@property(nonatomic, retain) CLBeacon*			selectedBeacon;

@property(nonatomic, strong) UITextView *tvLog;

@end

@implementation AIBMainTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
	
	self.locationManager = [[CLLocationManager alloc] init];
	self.locationManager.delegate = self;
	
	self.listUUID=[[NSArray alloc] init];
	self.beaconsDict=[[NSMutableDictionary alloc] init];
	self.sortByMajorMinor=NO;
    
    self.tvLog = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 80)];
    self.tvLog.font = [UIFont systemFontOfSize:12];
    self.tvLog.textColor = [UIColor blackColor];
    self.logListUUID = [NSMutableArray array];
	
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@ "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];//iBeaconConfiguration.uuid
    CLBeaconRegion *one = [[CLBeaconRegion alloc] initWithUUID:uuid identifier:@"any"];
    // let beaconRegion: CLBeaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: "tw.darktt.beaconDemo")
	// AIBBeaconRegionAny *beaconRegionAny = [[AIBBeaconRegionAny alloc] initWithIdentifier:@"Any"];
	[self.locationManager requestWhenInUseAuthorization];
	[self.locationManager startRangingBeaconsInRegion:one];
		
	self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Order by major/minor" style:UIBarButtonItemStylePlain target:self action:@selector(changeOrdenation)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"start" style:UIBarButtonItemStylePlain target:self action:@selector(logBeacons)];
}

- (void) showAddAlert {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Add"
                                                                                     message: @"Input username and password"
                                                                                 preferredStyle:UIAlertControllerStyleAlert];
       [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
           textField.placeholder = @"uuid";
           textField.textColor = [UIColor blueColor];
           textField.clearButtonMode = UITextFieldViewModeWhileEditing;
           textField.borderStyle = UITextBorderStyleRoundedRect;
       }];
       [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
           NSArray * textfields = alertController.textFields;
           UITextField * namefield = textfields[0];
           UITextField * passwordfiled = textfields[1];
           NSLog(@"%@:%@",namefield.text,passwordfiled.text);

       }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action) {

                                                          NSLog(@"cancel btn");

                                                          [alertController dismissViewControllerAnimated:YES completion:nil];

    }]];
       [self presentViewController:alertController animated:YES completion:nil];

}

- (void) changeOrdenation{
	_sortByMajorMinor=!_sortByMajorMinor;
	if (_sortByMajorMinor){
		self.navigationItem.rightBarButtonItem.title=@"Order by distance";
	} else {
		self.navigationItem.rightBarButtonItem.title=@"Order by major/minor";
	}
}

- (void)logBeacons {
    _isStartLog = !_isStartLog;
    if (_isStartLog) {
        self.navigationItem.leftBarButtonItem.title=@"Stop";
        [_logListUUID removeAllObjects];
    } else {
        self.navigationItem.leftBarButtonItem.title=@"Start";
        NSString *content = @"";
        for (CLBeacon *one in _logListUUID) {
            NSString *new = [[NSString alloc] initWithFormat:@"time:%@, major:%@, minor:%@, rssi:%d\n",
                        one.timestamp, one.major, one.minor, one.rssi];
            content = [content stringByAppendingString:new];
        }
        _tvLog.text = content;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"locationManagerDidChangeAuthorizationStatus: %d", status);
    
    [UIAlertController alertControllerWithTitle:@"Authoritzation Status changed"
                                        message:[[NSString alloc] initWithFormat:@"Location Manager did change authorization status to: %d", status]
                                 preferredStyle:UIAlertControllerStyleAlert];
    
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    NSLog(@"locationManager:%@ didRangeBeacons:%@ inRegion:%@",manager, beacons, region);

    NSMutableArray* listUuid=[[NSMutableArray alloc] init];
	NSMutableDictionary* beaconsDict=[[NSMutableDictionary alloc] init];
	for (CLBeacon* beacon in beacons) {
		NSString* uuid=[beacon.proximityUUID UUIDString];
		NSMutableArray* list=[beaconsDict objectForKey:uuid];
		if (list==nil){
			list=[[NSMutableArray alloc] init];
			[listUuid addObject:uuid];
			[beaconsDict setObject:list forKey:uuid];
		}
		[list addObject:beacon];
	}
	[listUuid sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSString* string1=obj1;
		NSString* string2=obj2;
		return [string1 compare:string2];
	}];
	if (_sortByMajorMinor){
		for (NSString* uuid in listUuid){
			NSMutableArray* list=[beaconsDict objectForKey:uuid];
			[list sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				CLBeacon* b1=obj1;
				CLBeacon* b2=obj2;
				NSComparisonResult r=[b1.major compare:b2.major];
				if (r==NSOrderedSame){
					r=[b1.minor compare:b2.minor];
				}
				return r;
			}];
		}
	}
    if (_isStartLog) {
        for (CLBeacon *one in _beaconsDict.allValues[0]) {
            [_logListUUID addObject:one];
        }
    } else {
        _listUUID=listUuid;
    }
    _beaconsDict=beaconsDict;
	
	[self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
     NSLog(@"locationManager:%@ rangingBeaconsDidFailForRegion:%@ withError:%@", manager, region, error);
    
    [UIAlertController alertControllerWithTitle:@"Ranging Beacons fail"
                                        message:[[NSString alloc] initWithFormat:@"Ranging beacons fail with error: %@", error]
                                 preferredStyle:UIAlertControllerStyleAlert];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_listUUID count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	NSString* key=[_listUUID objectAtIndex:section];
    return _isStartLog ? _logListUUID.count : [[_beaconsDict objectForKey:key] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return [_listUUID objectAtIndex:section];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
	
    if (_isStartLog) {
        CLBeacon* beacon=_logListUUID[indexPath.row] ;
        cell.textLabel.text=[[NSString alloc] initWithFormat:@"M:%@ m:%@", beacon.major, beacon.minor];
        
        cell.detailTextLabel.text=[[NSString alloc] initWithFormat:@"Distance: %.2fm\trssi: %ddbm\tProximity: %@", beacon.accuracy,beacon.rssi, [AIBUtils stringForProximityValue:beacon.proximity]];
    } else {
        NSString* key=[_listUUID objectAtIndex:[indexPath indexAtPosition:0]];
        CLBeacon* beacon=[[_beaconsDict objectForKey:key] objectAtIndex:[indexPath indexAtPosition:1]];
        cell.textLabel.text=[[NSString alloc] initWithFormat:@"M:%@ m:%@", beacon.major, beacon.minor];
        
        cell.detailTextLabel.text=[[NSString alloc] initWithFormat:@"Distance: %.2fm\trssi: %ddbm\tProximity: %@", beacon.accuracy,beacon.rssi, [AIBUtils stringForProximityValue:beacon.proximity]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	NSString* key=[_listUUID objectAtIndex:[indexPath indexAtPosition:0]];
	_selectedBeacon=[[_beaconsDict objectForKey:key] objectAtIndex:[indexPath indexAtPosition:1]];

    AIBDetailViewController* detail=[self.storyboard instantiateViewControllerWithIdentifier:@"detail"];
	detail.beacon=_selectedBeacon;
	[self.navigationController pushViewController:detail animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.distribution = UIStackViewDistributionFill;
    [stackView addArrangedSubview:_tvLog];
    
    UIButton *btOne = [[UIButton alloc] initWithFrame:CGRectZero];
    [btOne setTitle:@"Add" forState:UIControlStateNormal];
    [btOne addTarget:self action:@selector(showAddAlert) forControlEvents:UIControlEventTouchUpInside];
    
    [stackView addArrangedSubview:btOne];
    
    return stackView;
}


@end
