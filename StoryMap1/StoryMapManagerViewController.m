//
//  ConfigViewController.m
//  StoryMap1
//
//  Created by Frank on 8/26/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

/**
 
 8 story maps using tour templates from storymaps.esri.com
 
 http://ugis.esri.com/IETour/
 http://esripm.maps.arcgis.com/apps/MapTour/index.html?appid=fb8e06dbdc1a4a318e5acb916d085a24&webmap=fc38818b884545b796402843993000f0
 http://storymaps.esri.com/stories/2013/maptour-sandiego-transportation/
 http://story.maps.arcgis.com/apps/MapTour/index.html?appid=f90046e0ce8e44e2a128f0325fccb2af&webmap=051d2c8302a747ce8335a0a1f106fc86
 http://storymaps.esri.com/stories/maptour-palmsprings/
 http://downloads2.esri.com/agol/pub/redlandsguide/index.html
 http://storymaps.esri.com/stories/highline/
 http://storymaps.esri.com/stories/malltour/
 
 **/

#import "StoryMapManagerViewController.h"
#import "LoadMapStoryPage.h"
#import "StoryMapDatabase.h"
#import "Reachability.h"

@interface StoryMapManagerViewController ()


@property (nonatomic, strong) LoadMapStoryPage *loadMapStoryStartPage;
@property (nonatomic, weak) NSArray *storyMapInfos;
@property (nonatomic) BOOL loadingIndexPage;

@end

@implementation StoryMapManagerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.storyMapInfos = [[StoryMapDatabase sharedStoryMapDatabase] storyMapInfos];
    self.storyMapView.delegate = self;
    self.storyMapView.dataSource = self;
    self.storyMapUrlField.delegate = self;
    
    if ([self.storyMapInfos count]==0) {
        // default story map url
        self.storyMapTitle.text = @"A walk on the High Line";
        self.storyMapUrlField.text = @"http://storymaps.esri.com/stories/highline/";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [[StoryMapDatabase sharedStoryMapDatabase] readStoryMapInfoFromDatabase];
    
    self.storyMapInfos = [StoryMapDatabase sharedStoryMapDatabase].storyMapInfos;
    [self.storyMapView reloadData];
    if (self.currentSelectedStoryMap) {
        self.storyMapTitle.text = self.currentSelectedStoryMap.title;
        self.storyMapUrlField.text = self.currentSelectedStoryMap.url;
    }
}

#pragma mark
#pragma mark NSNotifications

-(void)reachabilityChanged:(NSNotification*)note
{
    NSLog(@"reachabilityChanged ****** ");
    Reachability * reach = [note object];
    self.storyMapUrlField.enabled = [reach isReachable];
}

- (IBAction)goButtonClicked:(id)sender {
    [self.storyMapUrlField resignFirstResponder];
    
    NSString *urlstring = self.storyMapUrlField.text;
    if (urlstring && ![urlstring isEqualToString:@""])
    {
        // check to see if the url is entered by user or from the existing table/local disk
        StoryMapInfo* storyMapInfo = nil;
        for (StoryMapInfo *info in self.storyMapInfos){
            if([info.url isEqualToString:urlstring]) {
                storyMapInfo = info;
                break;
            }
        }
        
        if(storyMapInfo) {
            self.currentSelectedStoryMap = storyMapInfo;
            if(self.delegate) {
                storyMapInfo.offline = YES;
                [self.delegate loadStoryMapWithStoryMapInfo:storyMapInfo];
            }
        }else {
            urlstring = [urlstring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (![urlstring  hasPrefix:@"http://"] ) {
//                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Invalid story map web url (it should start with http://)." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//                [alertView show];
                // assume the text from url field is a webmap id
                NSString *webmapId = urlstring;
                if(self.delegate) {
                    [self.delegate loadStoryMapWithWebmap:webmapId andUrl:self.storyMapUrlField.text];
                }
                return;
            }
            
            if ([urlstring hasSuffix:@"index.html"]) {
                [self loadStoryMapIndexPage:urlstring];
            }
            else if ([urlstring hasSuffix:@"/"]) {
                [self loadStoryMapIndexPage:[NSString stringWithFormat:@"%@index.html", urlstring]];
            }
            else if ([urlstring rangeOfString:@"&webmap="].location != NSNotFound) {
                int index = [urlstring rangeOfString:@"&webmap="].location;
                NSString *webmapId = [urlstring substringFromIndex:index+8];
                if(self.delegate) {
                    [self.delegate loadStoryMapWithWebmap:webmapId andUrl:self.storyMapUrlField.text];
                }
            }else if ([urlstring rangeOfString:@"?webmap="].location != NSNotFound) {
                int index = [urlstring rangeOfString:@"?webmap="].location;
                NSString *webmapId = [urlstring substringFromIndex:index+8];
                if(self.delegate) {
                    [self.delegate loadStoryMapWithWebmap:webmapId andUrl:self.storyMapUrlField.text];
                }
            }
            else {
                urlstring = [NSString stringWithFormat:@"%@/index.html", urlstring];
                [self loadStoryMapIndexPage:urlstring];
            }            
        }
    }
}

- (void) loadStoryMapIndexPage:(NSString*)urlstring
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:urlstring];
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        //NSLog(@"url=%@", urlstring);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                NSLog(@"Error loading index page. %@", [error localizedDescription]);
            }else{
                [self extractWebmapIdFromHtmlDoc:data];
            }
        });
    });
}

- (void)extractWebmapIdFromHtmlDoc:(NSData*)data
{
    NSString *finalResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"final response=>%@", finalResponse);
    
    finalResponse = [finalResponse lowercaseString];
    BOOL webmapIdIndex1 = [finalResponse rangeOfString:@"webmap :"].location != NSNotFound;
    BOOL webmapIdIndex2 = [finalResponse rangeOfString:@"webmap:"].location != NSNotFound;
    if (webmapIdIndex1 || webmapIdIndex2 ) {
        NSString *ss = nil;
        if (webmapIdIndex1) {
            ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap :"].location + 8];
        }else {
            ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap:"].location + 7];
        }
        
        int end =  [ss rangeOfString:@","].location;
        ss = [ss substringToIndex:end];
        ss = [ss stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        ss = [ss substringToIndex:ss.length-1];
        ss = [ss substringFromIndex:1];
        
        [self didReceiveResponseFromServer:ss];
    }else {
        // let's check keyword: webmapid or webap_id (like in case of Redlands Tour)
        webmapIdIndex1 = [finalResponse rangeOfString:@"webmapid="].location != NSNotFound;
        webmapIdIndex2 = [finalResponse rangeOfString:@"webmapid ="].location != NSNotFound;
        BOOL webmapIdIndex3 = [finalResponse rangeOfString:@"webmap_id="].location != NSNotFound;
        BOOL webmapIdIndex4 = [finalResponse rangeOfString:@"webmap_id ="].location != NSNotFound;
        
        if (webmapIdIndex1 || webmapIdIndex2 || webmapIdIndex3 || webmapIdIndex4 ) {
            NSString *ss = nil;
            if (webmapIdIndex1) {
                ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmapid="].location + 9];
            }else if(webmapIdIndex2) {
                ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmapid ="].location + 10];
            }else if (webmapIdIndex3) {
                ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap_id="].location + 10];
            }else if(webmapIdIndex4) {
                ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap_id ="].location + 11];
            }
            
            int end =  [ss rangeOfString:@";"].location;
            ss = [ss substringToIndex:end];
            ss = [ss stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            ss = [ss substringToIndex:ss.length-1];
            ss = [ss substringFromIndex:1];
            
            [self didReceiveResponseFromServer:ss];
        }else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Couldn't find web map id from the story map." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

- (void) loadStoryMapIndexPage0:(NSString*)urlstring
{
    if(self.loadingIndexPage)return;
    
    self.loadingIndexPage = YES;
//    NSString *urlEncodedString = [urlstring stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    NSURL *serviceUrl = [[NSURL alloc] initWithString:urlEncodedString];
    NSURL *serviceUrl = [[NSURL alloc] initWithString:urlstring];
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:serviceUrl];
    
    if(self.loadMapStoryStartPage==nil) {
        self.loadMapStoryStartPage = [[LoadMapStoryPage alloc] init];
        self.loadMapStoryStartPage.delegate = self;
    }
    
    [self.storyMapUrlField resignFirstResponder];
    [self.loadMapStoryStartPage startWithRequest:req];
}

#pragma mark
#pragma LoadMapStoryPageResponseDelegate

- (void)didReceiveResponseFromServer:(NSString*)webmapId {
    NSLog(@"webmap id=>%@", webmapId);
    if(webmapId && self.delegate) {
        [self.delegate loadStoryMapWithWebmap:webmapId andUrl:self.storyMapUrlField.text];
    }
    self.loadingIndexPage = NO;
}
- (void)didReceiveErrorFromServer:(NSString*)serverResponse {
    self.loadingIndexPage = NO;
}

#pragma mark Table view methods

//one section in this table
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


//the section in the table is as large as the number of attributes the feature has
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"# of story maps=%d, %d", [self.storyMapInfos count], [[StoryMapDatabase sharedStoryMapDatabase].storyMapInfos count]);
	return [self.storyMapInfos count];
}


//called by table view when it needs to draw one of its rows
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//static instance to represent a single kind of cell. Used if the table has cells formatted differently
    static NSString *DetailsViewControllerCellIdentifier = @"DetailsViewControllerCellIdentifier";
    
	//as cells roll off screen get the reusable cell, if we can't create a new one
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:DetailsViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DetailsViewControllerCellIdentifier];
    }
        
    StoryMapInfo *info = [self.storyMapInfos objectAtIndex:indexPath.row];
    cell.textLabel.text = info.title;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    StoryMapInfo *info = [self.storyMapInfos objectAtIndex:indexPath.row];
    self.storyMapUrlField.text = info.url;
    self.storyMapTitle.text = info.title;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"editingStyle");
    StoryMapInfo *mapInfo = [self.storyMapInfos objectAtIndex:indexPath.row];
    [self.delegate removeStoryMap:mapInfo];
    
    if ([self.storyMapUrlField.text isEqualToString:mapInfo.url]) {
        self.storyMapUrlField.text = @"";
    }
    
    self.storyMapInfos = [StoryMapDatabase sharedStoryMapDatabase].storyMapInfos;
    [self.storyMapView reloadData];
}

#pragma mark
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.storyMapTitle.text = @"";
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.storyMapTitle.text = @"";
    return YES;
}

@end
