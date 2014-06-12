//
//  StoryMapViewController.m
//  StoryMap1
//
//  Created by Frank on 8/26/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "StoryMapViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "StoryMapManagerViewController.h"
#import "LoadMapStoryPage.h"
#import "ThumbnailViewController.h" 
#import "ThumbnailView.h"   
#import "LoadingView.h"
#import "StoryMapDatabase.h"
#import "MapTile.h"
#import "MapTileUtil.h"
#import "OfflineTiledLayer.h"
#import "StoryMapUtil.h"
#import "Reachability.h"
#import "CustomCalloutViewController.h"
#import "TOCViewController.h"
#import "AboutViewController.h"

@interface StoryMapViewController ()


@property (nonatomic, strong) AGSWebMap *webMap;

@property (nonatomic, strong) AGSFeatureLayer *poiLayer;

@property (nonatomic, strong) StoryMapManagerViewController *configViewController;
@property (nonatomic, strong) UIPopoverController *configPopoverController;

@property (nonatomic, strong) NSString *nameFieldName;
@property (nonatomic, strong) NSString *descFieldName;
@property (nonatomic, strong) NSString *urlFieldName;
@property (nonatomic, strong) NSString *thumbnailUrlFieldName;
@property (nonatomic, strong) NSString *iconColorFieldName;
@property (nonatomic, strong) NSString *latFieldName;
@property (nonatomic, strong) NSString *lonFieldName;
@property (nonatomic, strong) NSString *indexFieldName;

@property (nonatomic, strong) NSString *urlLocalFieldName;
@property (nonatomic, strong) NSString *thumbnailUrlLocalFieldName;

@property (nonatomic, strong) NSMutableArray *thumbnailViews;
@property (nonatomic, strong) StoryMapInfo *currentStoryMapInfo;
@property (nonatomic) int currentZoomLevel;

@property (nonatomic, strong) LoadingView *loadingView;

@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic) BOOL graphicsLayerLoaded;
@property (nonatomic) BOOL thumbnailViewsCreated;
@property (nonatomic) BOOL imageDescViewContainerVisible;
@property (nonatomic) BOOL poiDownloaded;
@property (nonatomic) BOOL pictureDownloadStarted;

@property (nonatomic, strong) CustomCalloutViewController *customCalloutViewController;

@property (nonatomic, strong) AGSGraphicsLayer *highlightGraphicsLayer;
@property (nonatomic) int currentIndex;

@property (nonatomic, strong) TOCViewController *tocViewController;
@property (nonatomic, strong) UIPopoverController *tocPopoverController;

@property (nonatomic, strong) AboutViewController *aboutViewController;
@property (nonatomic, strong) UIPopoverController *aboutPopoverController;

@property (nonatomic) int mapZoomCount;

@end


#define THUMBNAIL_VIEW_WIDTH 140
#define THUMBNAIL_VIEW_HEIGHT 130
#define THUMBNAIL_VIEW_TOP 20
#define THUMBNAIL_VIEW_GAP 15

#define LAST_STORY_MAP_URL @"LastStoryMapUrl"

@implementation StoryMapViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
	// create storymaps folder if it is not created yet
    [StoryMapUtil createDirectory:STORY_MAP_OFFLINE_FOLDER_NAME atFilePath:[StoryMapUtil getDocumentRootPath]];

    // Set the client ID
    NSError *error;
    NSString* clientID = @"geJN8J01JYEyW9P9";
    [AGSRuntimeEnvironment setClientID:clientID error:&error];
    if(error){
        // We had a problem using our client ID
        NSLog(@"Error using client ID : %@",[error localizedDescription]);
    }
    
    self.currentZoomLevel = -1;
    
    self.tocButton.hidden = YES;
    self.scrollView.delegate = self;
    
    
    // make our status view look good
	self.statusView.layer.cornerRadius = 6;
	self.statusView.layer.borderColor = [UIColor whiteColor].CGColor;
	self.statusView.layer.borderWidth = 1;
	self.statusView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.5];
    
    
    self.customCalloutViewController = [[CustomCalloutViewController alloc] initWithNibName:@"CustomCalloutViewController" bundle:nil];
    self.mapView.calloutDelegate = self;
    self.mapView.callout.customView = self.customCalloutViewController.view;
    
    self.imageDescView.alpha = 0.75f;
    self.imageDescView.backgroundColor = [UIColor clearColor];
    [self.imageDescView setOpaque:NO];
    self.imageDescView.delegate = self;
    
    self.imageDescViewContainerVisible = NO;
    self.upButton.hidden = YES;
    self.downButton.hidden = NO;
    
    self.imageDescription.hidden = YES;
    
    
    // set default field names
    self.nameFieldName = @"NAME";
    self.descFieldName = @"DESCRIPTION";
    self.urlFieldName = @"URL";
    self.thumbnailUrlFieldName = @"THUMBNAIL_URL";
    self.iconColorFieldName = @"ICON_COLOR";
    self.indexFieldName = @"INDEX";
    self.latFieldName = @"LAT";
    self.lonFieldName = @"LON";
    self.urlLocalFieldName = @"URL_LOCAL";
    self.thumbnailUrlLocalFieldName = @"THUMBNAIL_URL_LOCAL";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapZoomingEnded:) name:AGSMapViewDidEndZoomingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPanningEnded:) name:AGSMapViewDidEndPanningNotification object:nil];
    
    self.thumbnailViews = [[NSMutableArray alloc] initWithCapacity:30];
    
    self.mapView.touchDelegate = self;
//    self.scrollView.backgroundColor = [UIColor lightGrayColor];

    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
        self.configViewController = [[StoryMapManagerViewController alloc] initWithNibName:@"StoryMapManagerViewController" bundle:nil];
        self.configViewController.delegate = self;
        self.configPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.configViewController];
        self.configPopoverController.popoverContentSize = CGSizeMake(548, 350);
    }
    
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftRecognizer:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.imageView addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightRecognizer:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.imageView addGestureRecognizer:swipeRight];
    
    [[StoryMapDatabase sharedStoryMapDatabase] readStoryMapInfoFromDatabase];
    [[StoryMapDatabase sharedStoryMapDatabase] readTileServiceInfoFromDatabase];
    [[StoryMapDatabase sharedStoryMapDatabase] readStoryMapTrackInfoFromDatabase];
    
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapStoryMapLabelRecognizer:)];
    [self.aStoryMapLabel addGestureRecognizer:tapGestureRecognizer];
    
//    [self createStoryMapInfo];
//    self.currentStoryMapInfo.webmapId = @"7fca9543e4d14ae7a9d5aba6f113bb3b";
//    self.currentStoryMapInfo.url = @"http://storymaps.esri.com/stories/highline/";
//    [self createNewStoryMap];
//    [self loadWebmap];

    
    // download icons images
//    NSString *rootPath = [StoryMapUtil getRootPath];
//
//    for (int i=15; i<100; i++) {
//        NSString *urlstring = [NSString stringWithFormat:@"http://storymaps.esri.com/templates/mapTour/resources/markers/red/NumberIcon%d.png", i];
//        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
//        NSString *fileName = [NSString stringWithFormat:@"%@/NumberIcon%d.png", rootPath, i];
//        [data writeToFile:fileName atomically:YES];
//    }
//    
//    for (int i=1; i<100; i++) {
//        NSString *urlstring = [NSString stringWithFormat:@"http://storymaps.esri.com/templates/mapTour/resources/markers/blue/NumberIconb%d.png", i];
//        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
//        NSString *fileName = [NSString stringWithFormat:@"%@/NumberIcon%d.png", rootPath, i];
//        [data writeToFile:fileName atomically:YES];
//    }
//    for (int i=1; i<186; i++) {
//        NSString *urlstring = [NSString stringWithFormat:@"http://ugis.esri.com/IETour/resources/markers/blue/NumberIconb%d.png", i];
//        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
//        NSString *fileName = [NSString stringWithFormat:@"%@/NumberIconb%d.png", rootPath, i];
//        [data writeToFile:fileName atomically:YES];
//    }

//
//    for (int i=1; i<100; i++) {
//        NSString *urlstring = [NSString stringWithFormat:@"http://www.arcgis.com/apps/MapTour/resources/markers/green/NumberIcong%d.png", i];
//        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
//        NSString *fileName = [NSString stringWithFormat:@"%@/NumberIcon%d.png", rootPath, i];
//        [data writeToFile:fileName atomically:YES];
//    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastStoryMapUrl = [defaults objectForKey:LAST_STORY_MAP_URL];
    BOOL found=NO;
    
    if (lastStoryMapUrl) {
        //load last story map
        for (StoryMapInfo *info in [StoryMapDatabase sharedStoryMapDatabase].storyMapInfos) {
            if ([lastStoryMapUrl isEqualToString:info.url]) {
                info.offline = YES;
                found = YES;
                [self loadStoryMapWithStoryMapInfo:info];
            }
        }
    }
    
    if(!found){
        // first time use or no default story map
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Welcome to Story Map Offline"
                                                     message:@"Tap Esri icon on the upper right corner to add a new story map or select an existing one. Tap \"A story map\" label on the upper right corner to view more detailed description of the app."
                                                    delegate:nil
                                           cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.aStoryMapLabel.textColor = [UIColor whiteColor];
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.aStoryMapLabel.textColor = [UIColor redColor];
        });
    };
    
    [reach startNotifier];
    
    NSLog(@"cache root folder=%@, cache folder=%@", [StoryMapUtil getCacheRootPath], [[NSFileManager defaultManager] fileExistsAtPath:[StoryMapUtil getCacheRootPath]]?@"true":@"false");
}



#pragma mark
#pragma mark NSNotifications

-(void)reachabilityChanged:(NSNotification*)note
{
    NSLog(@"****** reachabilityChanged");
    Reachability * reach = [note object];
    if([reach isReachable])
    {
        self.aStoryMapLabel.textColor = [UIColor whiteColor];
    }
    else
    {
        self.aStoryMapLabel.textColor = [UIColor redColor];
    }
    
    if (self.configViewController) {
        [self.configViewController reachabilityChanged:note];
    }
}

- (void)mapZoomingEnded:(id)sender
{
    NSLog(@"mapZoomingEnded %@", self.mapView.spatialReference);
    self.mapZoomCount++;
    [self mapExtentChanged];
}
-(void)mapPanningEnded:(id)sender
{
    NSLog(@"mapPannningEnded %@", self.mapView.spatialReference);
    [self mapExtentChanged];
}
- (void)mapExtentChanged
{
    if (!self.currentStoryMapInfo.offline) {
        self.tocButton.hidden = YES;
    }
    NSLog(@"self.tocButton.hidden=%@", self.tocButton.hidden?@"true":@"false");
    
    if (!self.currentStoryMapInfo.offline) {
        NSLog(@"%@, scale=%f", self.mapView.visibleAreaEnvelope, self.mapView.mapScale);
        AGSEnvelope *extent = self.mapView.visibleAreaEnvelope;
        self.currentZoomLevel = [self findCurrentZoomLevel];
        
        AGSGeometryEngine *engine = [AGSGeometryEngine defaultGeometryEngine];
        AGSEnvelope *envelope = (AGSEnvelope*)[engine projectGeometry:extent toSpatialReference: [[AGSSpatialReference alloc] initWithWKID:4326] ];
        MapTile *tile = [MapTileUtil findImmediateMapTileWithX:0 y:0 zoomLevel:0 andEnvelope:envelope];
        NSLog(@"****  envelope=%@, current zoom level=%d, tile col=%d, row=%d,zoom=%d", envelope, self.currentZoomLevel, tile.col, tile.row, tile.zoomLevel);
        [self loadSubtiles:tile withinEnvelope:envelope];
    }else {
        self.poiDownloaded = YES;
    }
    
    if (!self.graphicsLayerLoaded && self.mapView.spatialReference && self.poiDownloaded) {
        [self createTrackLayers];
        [self createPOIGraphics];
    }
    
    NSLog(@"mapExtentChanged %@", self.mapView.visibleAreaEnvelope);
}

-(void)updateStatus:(NSString*)status showActivity:(BOOL)activity{
	
	if (status.length > 0){
		self.statusView.hidden = NO;
		
		// animate in...
		if (!CGAffineTransformEqualToTransform(self.statusView.transform, CGAffineTransformIdentity)){
            [UIView beginAnimations:@"statusIn" context:nil];
            [UIView setAnimationDuration:0.25];
            self.statusView.transform = CGAffineTransformIdentity;
            [UIView commitAnimations];
        }
	}
	
	self.statusLabel.text = status;
	if (activity){
		[self.activityIndicator startAnimating];
	}
	else {
		[self.activityIndicator stopAnimating];
	}
    
}

-(void)updateStatusToEmpty{
	[self updateStatus:@"" showActivity:NO];
	
	// animate out
	[UIView beginAnimations:@"statusOut" context:nil];
	[UIView setAnimationDuration:0.25];
	self.statusView.transform = CGAffineTransformMakeTranslation(self.statusView.frame.size.width + 400, 0);
	[UIView commitAnimations];
}


#pragma mark
#pragma mark Downloading photos and tiles

-(void)loadTopLevelTiles:(MapTile*)tile serviceInfo:(TileServiceInfo*)tileServiceInfo
{
    if (tile.zoomLevel > 4) {
        return;
    }
    
    if (tile.zoomLevel <= 4) {
        NSArray *subtiles = [MapTileUtil findSubTiles:tile];
        for (int i=0; i<[subtiles count]; i++) {
            MapTile *t = [subtiles objectAtIndex:i];
            [self loadTopLevelTiles:t serviceInfo:tileServiceInfo];
        }
    }
    
    // load the tile
    [self downloadSingleTile:tile andTileServiceInfo:tileServiceInfo];
}

-(void)loadSubtiles:(MapTile*)tile withinEnvelope:(AGSEnvelope*)envelope
{
    // to be safe, we wouldn't go any further than current zoom level
    if (tile.zoomLevel > self.currentZoomLevel) {
        return;
    }
    
    if (![tile.boundingBox intersectionWithEnvelope:envelope]) {
        return;
    }
    
    if (tile.zoomLevel < self.currentZoomLevel) {
        NSArray *subtiles = [MapTileUtil findSubTiles:tile];
        for (int i=0; i<[subtiles count]; i++) {
            MapTile *t = [subtiles objectAtIndex:i];
            [self loadSubtiles:t withinEnvelope:envelope];
        }
        return;
    }
    
    // load the tile
    if (self.currentStoryMapInfo.tileServiceUrl1) {
        if (![self.currentStoryMapInfo.tileServiceUrl1 isEqualToString:@""]) {
            TileServiceInfo *serviceInfo = [self findTiledServiceInfo:self.currentStoryMapInfo.tileServiceUrl1];
            [self downloadSingleTile:tile andTileServiceInfo:serviceInfo];
        }
    }
    if (self.currentStoryMapInfo.tileServiceUrl2) {
        if (![self.currentStoryMapInfo.tileServiceUrl2 isEqualToString:@""]) {
            TileServiceInfo *serviceInfo = [self findTiledServiceInfo:self.currentStoryMapInfo.tileServiceUrl2];
            [self downloadSingleTile:tile andTileServiceInfo:serviceInfo];
        }
    }
    if (self.currentStoryMapInfo.tileServiceUrl3) {
        if (![self.currentStoryMapInfo.tileServiceUrl3 isEqualToString:@""]) {
            TileServiceInfo *serviceInfo = [self findTiledServiceInfo:self.currentStoryMapInfo.tileServiceUrl3];
            [self downloadSingleTile:tile andTileServiceInfo:serviceInfo];
        }
    }
    if (self.currentStoryMapInfo.tileServiceUrl4) {
        if (![self.currentStoryMapInfo.tileServiceUrl4 isEqualToString:@""]) {
            TileServiceInfo *serviceInfo = [self findTiledServiceInfo:self.currentStoryMapInfo.tileServiceUrl4];
            [self downloadSingleTile:tile andTileServiceInfo:serviceInfo];
        }
    }
}

- (void)downloadSingleTile:(MapTile*)tile andTileServiceInfo:(TileServiceInfo*)tileServiceInfo
{
    NSString *urlstring = [NSString stringWithFormat:@"%@/tile/%d/%d/%d", tileServiceInfo.url, tile.zoomLevel,  tile.row, tile.col];
    if ([tileServiceInfo.type isEqualToString:@"osm"]) {
        urlstring = [NSString stringWithFormat:@"%@/%d/%d/%d.png", tileServiceInfo.url, tile.zoomLevel, tile.col, tile.row];
    }
    NSLog(@"tile url=%@, format=%@", urlstring, tileServiceInfo.format);
    
    NSString *rootPath = [StoryMapUtil getCacheRootPath];
    
    //Level ('L' followed by 2 decimal digits)
    NSString *decLevel = [NSString stringWithFormat:@"L%02d",tile.zoomLevel];
    //Row ('R' followed by 8 hex digits)
    NSString *hexRow = [NSString stringWithFormat:@"R%08x",tile.row];
    //Column ('C' followed by 8 hex digits)
    NSString *hexCol = [NSString stringWithFormat:@"C%08x",tile.col];
    
    BOOL isDir;
    NSString *dirPath = [NSString stringWithFormat:@"%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,tileServiceInfo.url_local];
    NSString* dir = [NSString stringWithFormat:@"%@/%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,tileServiceInfo.url_local,decLevel];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
        [StoryMapUtil createDirectory:decLevel atFilePath:dirPath];
    }
    
    dirPath = dir;
    dir = [NSString stringWithFormat:@"%@/%@",dirPath,hexRow];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
        [StoryMapUtil createDirectory:hexRow atFilePath:dirPath];
    }
    
    NSString* tileFileName = [NSString stringWithFormat:@"%@/%@.%@", dir, hexCol, tileServiceInfo.format];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:tileFileName]) return;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:urlstring];
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        [data writeToFile:tileFileName atomically:YES];
    });
    
//    NSLog(@"tile image path=%@", tileFileName);
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
//    [data writeToFile:tileFileName atomically:YES];
    
}

-(int)findCurrentZoomLevel
{
    AGSTileInfo *tileInfo = nil;
    if (self.currentStoryMapInfo && self.currentStoryMapInfo.tileServiceUrl1) {
        NSArray *tileInfos = [[StoryMapDatabase sharedStoryMapDatabase] tileServiceInfos];
        for (int i=0; [tileInfos count]; i++) {
            TileServiceInfo *info = [tileInfos objectAtIndex:i];
            if ([info.url isEqualToString:self.currentStoryMapInfo.tileServiceUrl1]) {
                //NSLog(@"tile info=>%@",info.tileInfo);
                tileInfo =  [[AGSTileInfo alloc] initWithJSON: [info.tileInfo ags_JSONValue]];
                break;
            }
        }
    }
    int currentZoomLevel = -1;
    if (tileInfo) {
        for(int i=0; i<[tileInfo.lods count]; i++) {
            AGSLOD *lod = [[tileInfo lods] objectAtIndex:i];
            if(lod.scale <= self.mapView.mapScale) {
                currentZoomLevel = lod.level;
                break;
            }
        }
    }
//    NSString* jsonString = @"{\"firstName\":\"Frank\", \"lastName\":\"Xia\"}";
//    id jsonObject = [jsonString ags_JSONValue];
//    NSLog(@"current zoom level=%d, testing=%@", currentZoomLevel, jsonObject);
    
    
    return currentZoomLevel;
}

-(void)downloadPOIFeaturesAndSave2SQLite
{
    NSArray *graphics = self.poiLayer.graphics;
    AGSSpatialReference *spatialReference = [[AGSSpatialReference alloc] initWithWKID:4326];
    
    POIInfo *firstInfo = nil;
    
    int thumbnailIndex = 1;
    for (int i=0; i<[graphics count]; i++) {
        AGSGraphic *feature = [graphics objectAtIndex:i];
        AGSPoint *point = (AGSPoint*)feature.geometry;
        AGSPoint *latlon = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:point toSpatialReference:spatialReference];
        
        NSString *title = [feature attributeAsStringForKey:self.nameFieldName];
        NSString *thumbnailUrl = [feature attributeAsStringForKey:self.thumbnailUrlFieldName];
        NSString *iconColor = [feature attributeAsStringForKey:self.iconColorFieldName];
        NSLog(@"i=%d, color=%@,thumbnail image url=%@, title=%@", i, iconColor, thumbnailUrl, title);
        
        POIInfo *info = [[POIInfo alloc] init];
        info.index = thumbnailUrl?(thumbnailIndex++):0;
        info.name = [title stringByReplacingOccurrencesOfString:@"'" withString:@"''"]; // escape single quote
        info.description = [[feature attributeAsStringForKey:self.descFieldName] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]; // escape single quote
        info.url = [feature attributeAsStringForKey:self.urlFieldName];
        info.icon_color = iconColor?iconColor:@"R";
        info.thumbnail_url = thumbnailUrl?thumbnailUrl:@"";
        info.url_local = @"";
        info.thumbnail_url_local = @"";
        
        BOOL exists;
        //        double lat = [feature attributeAsDoubleForKey:self.latFieldName exists:&exists];
        //        if (exists) {
        //            info.lat = lat;
        //        }else {
        info.lat = latlon.y;
        //        }
        //        double lon = [feature attributeAsDoubleForKey:self.lonFieldName exists:&exists];
        //        if (exists) {
        //            info.lon = lon;
        //        }else{
        info.lon = latlon.x;
        //        }
        
        if(self.indexFieldName) {
            int index = [feature attributeAsIntegerForKey:self.indexFieldName exists:&exists];
            if(exists) {
                info.index = index;
            }
        }
        if (thumbnailUrl) {
            NSString *thumbnailUrlLocal = [self generateLocalUrl:thumbnailUrl];
            info.thumbnail_url_local = thumbnailUrlLocal;
        }
        if (info.url) {
            NSString *urlLocal = [self generateLocalUrl:info.url];
            info.url_local = urlLocal;
        }
        NSLog(@"i=%d, index=%d, thumbnail image url=%@, local=%@", i, info.index, info.thumbnail_url, info.thumbnail_url_local);
        
        
        [[StoryMapDatabase sharedStoryMapDatabase] addPOI:info toTable:self.currentStoryMapInfo.folderName];
        
        /*
         if (title && thumbnailUrl)
         {
         ThumbnailViewController *thumbnailViewController = [[ThumbnailViewController alloc] initWithNibName:@"ThumbnailViewController" bundle:nil];
         [thumbnailViewController updateWithIndex:i title:title andThumbnailUrl:thumbnailUrl];
         thumbnailViewController.delegate = self;
         float x = i*(w+gap);
         CGRect frame = CGRectMake(x, y, w, h);
         thumbnailViewController.view.frame = frame;
         self.thumbnailViewController = thumbnailViewController;
         [self.thumbnailViews addObject:thumbnailViewController];
         [self.scrollView addSubview:thumbnailViewController.view];
         thumbnailCount++;
         }
         */
        
        if(i==0 && info.url){
            firstInfo = info;
        }
    }
    
    if (firstInfo) {
        [self downloadPhotoAndSave2LocalDriveWithUrl:firstInfo.url updateUI:YES];
    }
    self.poiDownloaded = YES;
}

- (void)createThumbnailView:(POIInfo*)info thumbnailCount:(int)thumbnailCount
{
    float x = thumbnailCount*(THUMBNAIL_VIEW_WIDTH+THUMBNAIL_VIEW_GAP);
    CGRect frame = CGRectMake(x, THUMBNAIL_VIEW_TOP, THUMBNAIL_VIEW_WIDTH, THUMBNAIL_VIEW_HEIGHT);
    ThumbnailView *thumbnailView = [[ThumbnailView alloc] initWithFrame:frame];
    
    thumbnailView.delegate = self;
    [thumbnailView updateWithPOIInfo:info storyMapFolder:self.currentStoryMapInfo.folderName andPhotoFolder:STORY_MAP_PHOTOS_FOLDER_NAME];
    [self.thumbnailViews addObject:thumbnailView];
    [self.scrollView addSubview:thumbnailView];
}

- (void)createThumbnailView1:(POIInfo*)info thumbnailCount:(int)thumbnailCount
{   
    ThumbnailViewController *thumbnailViewController = [[ThumbnailViewController alloc] initWithNibName:@"ThumbnailViewController" bundle:nil];
    [thumbnailViewController updateWithPOIInfo:info storyMapFolder:self.currentStoryMapInfo.folderName andPhotoFolder:STORY_MAP_PHOTOS_FOLDER_NAME];
    [self.thumbnailViews addObject:thumbnailViewController.view];
    [self.scrollView addSubview:thumbnailViewController.view];
}

-(void) createThumbnailViews
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = [NSString stringWithFormat:@"Creating thumbnail views ... ..."];
        [self updateStatus:msg showActivity:YES];
    });
    
    NSString *tableName = self.currentStoryMapInfo.folderName;
    NSArray *poiInfos = [[StoryMapDatabase sharedStoryMapDatabase] readPOIInfoFromDatabase:tableName];
    NSLog(@"createThumbnailViews: POIInfos # of POIs=%d", [poiInfos count]);
    
    POIInfo *firstPOIInfo = nil;
    int thumbnailCount = 0;
    int count=0;
    double xmin,ymin,xmax,ymax;
    for (POIInfo *info in poiInfos) {
        if (count==0) {
            xmin = info.lon; xmax = info.lon;
            ymin = info.lat; ymax = info.lat;
        }else {
            if (xmin > info.lon) {
                xmin = info.lon;
            }
            if(xmax < info.lon){
                xmax = info.lon;
            }
            if(ymin > info.lat) {
                ymin = info.lat;
            }
            if(ymax < info.lat) {
                ymax = info.lat;
            }
        }
        
        if(count==0) {
            firstPOIInfo = info;
        }
        count++;
        
        if (info.index==0) {
            if([info.thumbnail_url isEqualToString:@""]) {
                continue;
            }else {
                thumbnailCount++;
            }
        }
        
        [self createThumbnailView:info thumbnailCount:thumbnailCount];
        thumbnailCount++;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *msg = [NSString stringWithFormat:@"Creating thumbnail view ... %d", thumbnailCount];
            [self updateStatus:msg showActivity:YES];
        });
    }
    
    [self.scrollView setContentSize:CGSizeMake((thumbnailCount+1)*(THUMBNAIL_VIEW_WIDTH +THUMBNAIL_VIEW_GAP), THUMBNAIL_VIEW_HEIGHT)];
    //[self.scrollView scrollRectToVisible:CGRectMake(0, 0, 200, THUMBNAIL_VIEW_HEIGHT) animated:YES];
    
    
    if (firstPOIInfo && firstPOIInfo.url_local) {
        self.currentIndex = firstPOIInfo.index;
        NSString *photoFileName = [NSString stringWithFormat:@"%@/%@/%@/%@",[StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName, STORY_MAP_PHOTOS_FOLDER_NAME,  firstPOIInfo.url_local];
        if ([[NSFileManager defaultManager] fileExistsAtPath:photoFileName]) {
            self.imageView.image = [UIImage imageWithContentsOfFile:photoFileName];
            if (firstPOIInfo.description) {
                self.imageDescription.text = [self removeHyperlink:firstPOIInfo.description];
                [self.imageDescView loadHTMLString:[self convert2HtmlDoc:firstPOIInfo.description] baseURL:nil];
                self.imageTileDescView.hidden = NO;
            }
            if (firstPOIInfo.name) {
                self.imageTitle.text = firstPOIInfo.name;
                self.imageTileDescView.hidden = NO;
            }
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = [NSString stringWithFormat:@"Initializing thumbnail views in the bottom scroll view ... ..."];
        [self updateStatus:msg showActivity:YES];
    });
    
    NSLog(@"Done creating thumbnail views");
}

- (void)downloadPhotoAndSave2LocalDriveWithUrl:(NSString*)urlstring updateUI:(BOOL)updateImageView
{
    if (![Reachability reachabilityForInternetConnection]) {
        return;
    }
    
    if (updateImageView) {
        [self updateStatus:@"Downloading photo ... ..." showActivity:YES];
    }else {
        NSLog(@"Downloading picture in background ... %@", urlstring);
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        NSString *photoFileName = [self generateLocalUrl:urlstring];
        photoFileName = [NSString stringWithFormat:@"%@/%@/%@/%@",[StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName, STORY_MAP_PHOTOS_FOLDER_NAME,  photoFileName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:photoFileName]) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
            [data writeToFile:photoFileName atomically:YES];
            
            if (updateImageView) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.imageView.image = [UIImage imageWithData:data];
                    [self updateStatusToEmpty];
                });
            }
        }
    });

    
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlstring]];
//    self.imageView.image = [UIImage imageWithData:data];
//    
//    NSString *photoFileName = [self generateLocalUrl:urlstring];
//    photoFileName = [NSString stringWithFormat:@"%@/%@/%@/%@",[StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName, STORY_MAP_PHOTOS_FOLDER_NAME,  photoFileName];
//    if (![[NSFileManager defaultManager] fileExistsAtPath:photoFileName]) {
//        [data writeToFile:photoFileName atomically:YES];
//    }
}


#pragma mark
#pragma mark Create infos

- (void)createStoryMapInfo
{
    self.currentStoryMapInfo = [[StoryMapInfo alloc] init];
    self.currentStoryMapInfo.tileServiceUrl1 = @"";
    self.currentStoryMapInfo.tileServiceUrl2 = @"";
    self.currentStoryMapInfo.tileServiceUrl3 = @"";
    self.currentStoryMapInfo.tileServiceUrl4 = @"";
    self.currentStoryMapInfo.comment = @"";
    self.currentStoryMapInfo.envelope = @"";
    self.currentStoryMapInfo.title = @"Untitled";
}

-(void)createNewStoryMap
{
    StoryMapDatabase *database = [StoryMapDatabase sharedStoryMapDatabase];
    NSArray *storyMapInfos = [database storyMapInfos];
    NSString *newStoryMapFolderName = @"StoryMap";
    NSString *tmp = [NSString stringWithFormat:@"%@1", newStoryMapFolderName];

    int count=1;
    while (TRUE) {
        BOOL needsContinue = NO;
        for(StoryMapInfo *info in storyMapInfos) {
            if([tmp isEqualToString:info.folderName]) {
                tmp = [NSString stringWithFormat:@"%@%d", newStoryMapFolderName, ++count];
                needsContinue = YES;
                break;
            }
        }
        if(needsContinue==NO) {
            break;
        }
    }
    
    if(self.currentStoryMapInfo==nil) {
        [self createStoryMapInfo];
    }
    
    self.currentStoryMapInfo.folderName = tmp;
    self.currentStoryMapInfo.poiTableName = tmp;
    NSLog(@"story map folder=%@",self.currentStoryMapInfo.folderName);
    
    [[StoryMapDatabase sharedStoryMapDatabase] addStoryMap:self.currentStoryMapInfo];
    
    // create folders if necessary
    [self createStoryMapFolders:self.currentStoryMapInfo.folderName rootPath:[StoryMapUtil getCacheRootPath]];
}

/**
 * The directory structure for the photo caches: 
 * ---> .../Library/Caches
 *      .../Library/Caches/[storyMapName]
 *      .../Library/Caches/[storyMapName]/photos (folder)
 *      .../Library/Caches/[storyMapName]/trackLayerDescription1.json (optional)
 *      .../Library/Caches/[storyMapName]/trackLayerFeatures1.json (optional)
 *      .../Library/Caches/[storyMapName]/trackLayerDescription2.json (optional)
 *      .../Library/Caches/[storyMapName]/trackLayerFeatures2.json (optional)
**/
-(void)createStoryMapFolders:(NSString*)storyMapName rootPath:(NSString*)rootPath
{
    BOOL isDir;    
    NSString *dirFileName = [NSString stringWithFormat:@"%@/%@", rootPath, storyMapName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dirFileName isDirectory:&isDir] == NO) {
        [StoryMapUtil createDirectory:storyMapName atFilePath:rootPath];
    }
    NSLog(@"StoryMap folder = %@", [[NSFileManager defaultManager] fileExistsAtPath:dirFileName]?@"true":@"false");
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dirFileName]) {        
        NSString *photosFolderName = [NSString stringWithFormat:@"%@/%@", dirFileName, STORY_MAP_PHOTOS_FOLDER_NAME];
        if ([[NSFileManager defaultManager] fileExistsAtPath:photosFolderName isDirectory:&isDir] == NO) {
            [StoryMapUtil createDirectory:STORY_MAP_PHOTOS_FOLDER_NAME atFilePath:dirFileName];
        }
    }
}

/**
 * The directory structure for the tile caches: (so we can share tiles among all story maps if possible)
 * ---> .../Library/Caches
 *      .../Library/Caches/tiles/[tileserviceurl] (folder)
 *      .../Library/Caches/tiles/[tileserviceurl]/.../...
 **/
- (void) createCacheFolder:(AGSTiledMapServiceLayer*)baseMapService {
    NSLog(@"========== createCacheFolder ===========");
    
    NSString *tileServiceUrl = [baseMapService.URL absoluteString];
    NSString *serviceUrlLocal = [self convertUrl2Local:tileServiceUrl];

    NSString *tileFormat = ([[baseMapService.tileInfo.format lowercaseString] rangeOfString:@"png"].location == NSNotFound)?@"jpg":@"png";

    // add tile service/base map to the database if the base map doesn't exist in the database.
    TileServiceInfo* tileServiceInfo = [[TileServiceInfo alloc] init];
    tileServiceInfo.url = tileServiceUrl;
    tileServiceInfo.url_local = serviceUrlLocal;
    tileServiceInfo.tileInfo = [[baseMapService.tileInfo encodeToJSON] ags_JSONRepresentation];
    tileServiceInfo.units = [[baseMapService encodeToJSON] objectForKey:@"units"];
    tileServiceInfo.envelope = [[baseMapService.initialEnvelope encodeToJSON] ags_JSONRepresentation];
    tileServiceInfo.fullEnvelope = [[baseMapService.fullEnvelope encodeToJSON] ags_JSONRepresentation];
    tileServiceInfo.format = tileFormat;
    tileServiceInfo.type = @"ags";
    
    [self createTileCacheFolder:tileServiceUrl tileServiceInfo:tileServiceInfo];
}

- (void) createOSMCacheFolder:(AGSOpenStreetMapLayer*)baseMapService {
    NSLog(@"========== createOSMCacheFolder ===========");
    
    NSString *tileServiceUrl = @"http://a.tile.openstreetmap.org";
    NSString *serviceUrlLocal = [self convertUrl2Local:tileServiceUrl];
    
    NSString *tileFormat = ([[baseMapService.tileInfo.format lowercaseString] rangeOfString:@"png"].location == NSNotFound)?@"jpg":@"png";
    
    // add tile service/base map to the database if the base map doesn't exist in the database.
    TileServiceInfo* tileServiceInfo = [[TileServiceInfo alloc] init];
    tileServiceInfo.url = tileServiceUrl;
    tileServiceInfo.url_local = serviceUrlLocal;
    tileServiceInfo.tileInfo = [[baseMapService.tileInfo encodeToJSON] ags_JSONRepresentation];
    tileServiceInfo.units = @"meters";
    tileServiceInfo.envelope = [[baseMapService.initialEnvelope encodeToJSON] ags_JSONRepresentation];
    tileServiceInfo.fullEnvelope = [[baseMapService.fullEnvelope encodeToJSON] ags_JSONRepresentation];
    tileServiceInfo.format = tileFormat;
    tileServiceInfo.type = @"osm";
    
    [self createTileCacheFolder:tileServiceUrl tileServiceInfo:tileServiceInfo];
}

- (void)createTileCacheFolder:(NSString*)tileServiceUrl tileServiceInfo:(TileServiceInfo*)tileServiceInfo
{
    BOOL isDir;
    NSString *tilePath = [NSString stringWithFormat:@"%@/%@", [StoryMapUtil getCacheRootPath], STORY_MAP_TILES_FOLDER_NAME];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tilePath isDirectory:&isDir] == NO) {
        [StoryMapUtil createDirectory:STORY_MAP_TILES_FOLDER_NAME atFilePath:[StoryMapUtil getCacheRootPath]];
    }
    
    NSString *serviceUrlLocal = [self convertUrl2Local:tileServiceUrl];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tilePath]) {
        NSString *tileFolderName = [NSString stringWithFormat:@"%@/%@", tilePath, serviceUrlLocal];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tileFolderName isDirectory:&isDir] == NO) {
            [StoryMapUtil createDirectory:serviceUrlLocal atFilePath:tilePath];
        }
    }
    
    int updateBaseMapIndex = 1;
    if ([self.currentStoryMapInfo.tileServiceUrl1 isEqualToString:@""]) {
        self.currentStoryMapInfo.tileServiceUrl1 = tileServiceUrl;
    }else if ([self.currentStoryMapInfo.tileServiceUrl2 isEqualToString:@""]) {
        self.currentStoryMapInfo.tileServiceUrl2 = tileServiceUrl;
        updateBaseMapIndex = 2;
    }else if([self.currentStoryMapInfo.tileServiceUrl3 isEqualToString:@""]) {
        self.currentStoryMapInfo.tileServiceUrl3 = tileServiceUrl;
        updateBaseMapIndex = 3;
    }else if ([self.currentStoryMapInfo.tileServiceUrl4 isEqualToString:@""]) {
        self.currentStoryMapInfo.tileServiceUrl4 = tileServiceUrl;
        updateBaseMapIndex = 4;
    }else {
        NSLog(@"Warning: Exceeds the limit of 4 BaseMaps!");
        return;
    }
    self.tocButton.hidden = updateBaseMapIndex<=1;
    
    // add the story map if it is not in the database
    StoryMapDatabase *database = [StoryMapDatabase sharedStoryMapDatabase];
    BOOL success = NO;
    for (StoryMapInfo *info in database.storyMapInfos) {
        if ([info.url isEqualToString:self.currentStoryMapInfo.url]) {
            success = YES;
            break;
        }
    }
    
    if(!success) {
        success = [database addStoryMap:self.currentStoryMapInfo];
        if (success) {
            [database readStoryMapInfoFromDatabase];
        }
        NSLog(@"re-read story map infos. %@", success?@"true":@"false");
    }else { // update
        success = [database updateStoryMapInfo:self.currentStoryMapInfo withBaseMapIndex:updateBaseMapIndex];
        NSLog(@"Update tiled service url index=%d", updateBaseMapIndex);
    }
    

    
    success = NO;
    for (TileServiceInfo *info in database.tileServiceInfos) {
        NSLog(@"=>%@", info.url);
        NSLog(@"=>%@", tileServiceInfo.url);
        
        if ([info.url isEqualToString:tileServiceInfo.url]) {
            success = YES;
            break;
        }
    }
    if(!success){
        success = [database addTileService:tileServiceInfo];
        if (success) {
            [database readTileServiceInfoFromDatabase];
            
//            // download top level tiles
//            AGSEnvelope *envelope = [[AGSEnvelope alloc] initWithXmin:-180 ymin:-85.1 xmax:180 ymax:85.1 spatialReference:[[AGSSpatialReference alloc] initWithWKID:4326] ];
//            MapTile *topTile = [[MapTile alloc] initWithCol:0 row:0 zoomLevel:0 andEnvelope:nil];
//            [self loadTopLevelTiles:topTile serviceInfo:tileServiceInfo];
        }
        NSLog(@"add Tile Service info. %@", success?@"true":@"false");
    }
    
//    NSLog(@"tileInfo=%@", tileServiceInfo.tileInfo);
//    NSLog(@"Units=%@", tileServiceInfo.units);
//    NSLog(@"init envelope=%@", tileServiceInfo.envelope);
//    NSLog(@"full envelope=%@", tileServiceInfo.fullEnvelope);
//    NSLog(@"url=%@", tileServiceInfo.url);
//    NSLog(@"url_local=%@", tileServiceInfo.url_local);
}

- (NSString*)convertUrl2Local:(NSString*)tileServiceUrl {
    NSString *serviceUrlLocal = [tileServiceUrl  stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    serviceUrlLocal = [serviceUrlLocal stringByReplacingOccurrencesOfString:@"/" withString:@""];
    serviceUrlLocal = [serviceUrlLocal stringByReplacingOccurrencesOfString:@"." withString:@""];
    return serviceUrlLocal;
}

- (void) loadWebmap {
    
    if(self.webMap) {
        self.webMap = nil;
        self.poiLayer = nil;
        for (AGSLayer *layer in [self.mapView mapLayers]) {
            [self.mapView removeMapLayer:layer];
        }
        [self.mapView reset];
    }
    
    // Create a webmap using the ID
    self.webMap = [AGSWebMap webMapWithItemId:self.currentStoryMapInfo.webmapId credential:nil];
    
    // Set self as the webmap's delegate so that we get notified
    // if the web map opens successfully or if errors are encounterer
    self.webMap.delegate = self;
    
    // Open the webmap
    [self.webMap openIntoMapView:self.mapView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark
#pragma mark Help methods
#pragma mark

- (IBAction)tocButtonClicked:(id)sender
{
    if(!self.tocPopoverController) {
        //create the toc view controller
        self.tocViewController = [[TOCViewController alloc] initWithMapView:self.mapView];
        self.tocPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.tocViewController];
        self.tocViewController.popOverController = self.tocPopoverController;
        self.tocPopoverController.popoverContentSize = CGSizeMake(250, 150);
        self.tocPopoverController.passthroughViews = [NSArray arrayWithObject:self.mapView];
    }
    if(self.tocPopoverController.isPopoverVisible) {
        [self.tocPopoverController dismissPopoverAnimated:YES];
    }else {
        [self.tocPopoverController presentPopoverFromRect:self.tocButton.frame inView:self.mapView permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];
    }
}

- (IBAction)updownButtonClicked:(id)sender
{
    self.imageDescViewContainerVisible = !self.imageDescViewContainerVisible;
    if (self.imageDescViewContainerVisible) {
        self.imageTileDescView.hidden = NO;
        self.downButton.hidden = NO;
        self.upButton.hidden = YES;
    }else {
        self.imageTileDescView.hidden = YES;
        self.downButton.hidden = YES;
        self.upButton.hidden = NO;
    }
}

- (IBAction)presentConfigView:(id)sender {
    // open the popup view for the settings
    if (self.configPopoverController.isPopoverVisible) {
        [self.configPopoverController dismissPopoverAnimated:YES];
    } else {
        CGRect rect = self.configButton.frame;
        self.configViewController.currentSelectedStoryMap = self.currentStoryMapInfo;
        [self.configPopoverController presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

-(IBAction)swipeLeftRecognizer:(id)sender {
     NSLog(@"swipeLeftRecognizer");
    self.currentIndex++;
    if(self.currentIndex > [self.graphicsLayer.graphics count]) {
        self.currentIndex = 0;
    }
    
    [self setThumbnailViewStatus:self.currentIndex doScroll:YES];
    [self showFeature];
}

-(IBAction)swipeRightRecognizer:(id)sender {
     NSLog(@"swipeRightRecognizer");
    self.currentIndex--;
    if(self.currentIndex <0) {
        self.currentIndex = [self.graphicsLayer.graphics count];
    }
    
    [self setThumbnailViewStatus:self.currentIndex doScroll:YES];    
    [self showFeature];
}

-(void)tapStoryMapLabelRecognizer:(id)sender
{    
    NSLog(@"Info view");
    if(!self.aboutPopoverController) {
        self.aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
        self.aboutPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.aboutViewController];
        self.aboutPopoverController.popoverContentSize = CGSizeMake(300, 450);
    }
    if(self.aboutPopoverController.isPopoverVisible) {
        [self.aboutPopoverController dismissPopoverAnimated:YES];
    }else {
        [self.aboutPopoverController presentPopoverFromRect:self.aStoryMapLabel.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];
    }
}


-(void) showFeature
{
    if (self.currentIndex>0) {
        self.imageTileDescView.hidden = NO;
        self.imageDescViewContainerVisible = YES;
        self.downButton.hidden = !self.imageDescViewContainerVisible;
        self.upButton.hidden = self.imageDescViewContainerVisible;
    }
    
    AGSGraphic *feature;
    BOOL exists;
    for (int i=0; i<[self.graphicsLayer.graphics count]; i++) {
        AGSGraphic *f = [self.graphicsLayer.graphics objectAtIndex:i];
        int index = [f attributeAsIntegerForKey:self.indexFieldName exists:&exists];
        if (index == self.currentIndex && exists) {
            feature = f;
            break;
        }
    }
    if (!feature)return;
        
    self.imageTitle.text = [feature attributeAsStringForKey:self.nameFieldName];
    self.imageDescription.text = [self removeHyperlink:[feature attributeAsStringForKey:self.descFieldName]];
    [self.imageDescView loadHTMLString:[self convert2HtmlDoc:[feature attributeAsStringForKey:self.descFieldName]] baseURL:nil];
    NSString *urlstring = [feature attributeAsStringForKey:self.urlFieldName];
    NSLog(@"image url=%@", urlstring);
    
    
    NSString *photoFileName = [self generateLocalUrl:urlstring];
    photoFileName = [NSString stringWithFormat:@"%@/%@/%@/%@",[StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName, STORY_MAP_PHOTOS_FOLDER_NAME,  photoFileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:photoFileName]) {
        self.imageView.image = [UIImage imageWithContentsOfFile:photoFileName];
    }else {
        [self downloadPhotoAndSave2LocalDriveWithUrl:urlstring updateUI:YES];
    }
    
    [self.mapView centerAtPoint:(AGSPoint*)feature.geometry animated:YES];
    
    self.mapView.callout.customView = nil;
    self.mapView.callout.accessoryButtonHidden = YES;
    self.mapView.callout.title = [feature attributeAsStringForKey:self.nameFieldName];
    self.mapView.callout.detail = @"";
        
    CGPoint offset = CGPointMake(-1, -25);
    [self.mapView.callout showCalloutAt:(AGSPoint*)feature.geometry pixelOffset:offset animated:YES];

    
    NSString *iconColor = [feature attributeAsStringForKey:self.iconColorFieldName];
    AGSPictureMarkerSymbol *mSymbol = [self createPictureSymbolWithIconColor:iconColor index:self.currentIndex andScale:.70f];
    AGSGraphic *g = [[AGSGraphic alloc] initWithJSON:[feature encodeToJSON]];
    g.symbol = mSymbol;
    [self.highlightGraphicsLayer removeAllGraphics];
    [self.highlightGraphicsLayer addGraphic:g];
}


- (NSString*)generateLocalUrl:(NSString*)urlstring {
    NSString *photoFileName = [urlstring  stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    photoFileName = [photoFileName stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString *fileExt = @".jpg";
    if ([photoFileName rangeOfString:@".jpg"].location != NSNotFound) {
        fileExt = @".jpg";
    }else if([photoFileName rangeOfString:@".png"].location != NSNotFound){
        fileExt = @".png";
    }
    photoFileName = [photoFileName stringByReplacingOccurrencesOfString:@"." withString:@""];
    photoFileName = [NSString stringWithFormat:@"%@%@", photoFileName, fileExt];
    return photoFileName;
}

#pragma mark
#pragma mark - AGSWebMapDelegagte methods
#pragma mark

- (void) webMapDidLoad:(AGSWebMap *)webMap {
    NSLog(@"description=%@, title=%@", webMap.portalItem.snippet, webMap.portalItem.title);
    self.storyMapTitle.text = webMap.portalItem.title;
    self.storyMapDescription.text = webMap.portalItem.snippet;

    self.currentStoryMapInfo.title = [webMap.portalItem.title stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    self.currentStoryMapInfo.description = [webMap.portalItem.snippet stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
    [[StoryMapDatabase sharedStoryMapDatabase] updateStoryMapInfo:self.currentStoryMapInfo withTile:self.currentStoryMapInfo.title andDescription:self.currentStoryMapInfo.description];
}

- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error
{
    
    NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:@"Failed to load the webmap"
                                                delegate:nil
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
    
    [self updateStatusToEmpty];
}

- (void) webMap:(AGSWebMap *)webMap didLoadLayer:(AGSLayer *)layer {
    
    if ([layer isKindOfClass:[AGSFeatureLayer class]]) {
        AGSFeatureLayer *flayer = (AGSFeatureLayer*)layer;
        NSLog(@"is a Point layer?%@", (flayer.geometryType == AGSGeometryTypePoint)?@"true":@"false");
        NSLog(@"is a polyline layer?%@", (flayer.geometryType == AGSGeometryTypePolyline)?@"true":@"false");
        
        if(flayer.geometryType == AGSGeometryTypePoint) {
            NSLog(@"POI feature layer %@, # of features=%d, full envelope=%@", flayer.name, [flayer.graphics count], [flayer fullEnvelope]);
            if ([flayer.fields count] < 4 || self.poiLayer) {
                return;
            }

            // figure out name, description, url and thumbnail field names
            int fdNameCount = 0;
            for (int i=0; i<[flayer.fields count]; i++) {
                AGSField *f = [flayer.fields objectAtIndex:i];
                NSString *fdName = [f.name lowercaseString];
                if ([fdName isEqualToString:@"name"] || [fdName isEqualToString:@"title"] || [fdName isEqualToString:@"name-short"] || [fdName isEqualToString:@"name-long"]) {
                    self.nameFieldName = f.name;
                    fdNameCount++;
                }
                else if ([fdName isEqualToString:@"description"] || [fdName isEqualToString:@"caption"] || [fdName isEqualToString:@"snippet"] || [fdName isEqualToString:@"comment"]) {
                    self.descFieldName = f.name;
                    fdNameCount++;
                }
                else if ([fdName isEqualToString:@"url"] || [fdName isEqualToString:@"pic"] || [fdName isEqualToString:@"pic_url"] || [fdName isEqualToString:@"picture"]) {
                    self.urlFieldName = f.name;
                    fdNameCount++;
                }
                else if ([fdName isEqualToString:@"thumbnail"] || [fdName isEqualToString:@"thumb_url"] || [fdName isEqualToString:@"thumb"] || [fdName rangeOfString:@"thumb"].location != NSNotFound) {
                    self.thumbnailUrlFieldName = f.name;
                    fdNameCount++;
                }
                
                // optional
                else if ([fdName isEqualToString:@"index"]) {
                    self.indexFieldName = f.name;
                }
                else if ([fdName isEqualToString:@"icon_color"] || [fdName isEqualToString:@"color"] || [fdName isEqualToString:@"style"]) {
                    self.iconColorFieldName = f.name;
                }
                else if ([fdName rangeOfString:@"icon"].location != NSNotFound) {
                    self.iconColorFieldName = f.name;
                }
                else if ([fdName isEqualToString:@"lat"]) {
                    self.latFieldName = f.name;
                }
                else if ([fdName isEqualToString:@"lon"] ||  [fdName isEqualToString:@"long"]) {
                    self.lonFieldName = f.name;
                }
                
                NSLog(@"i=%d, field name=%@", i, fdName);
            }
            
            if(fdNameCount == 4) {
                self.poiLayer = flayer;
                self.currentIndex = 0;
                
                AGSQuery *q = [AGSQuery query];
                q.where = @"1=1";
                q.outFields = [NSArray arrayWithObject:@"*"];
                NSOperation *op = [self.poiLayer queryFeatures:q];
                [op setCompletionBlock: ^{
                    if([self.poiLayer.graphics count] > 0) {
                        [self downloadPOIFeaturesAndSave2SQLite];
                        [self createThumbnailViews];
                        
                        if ([self isEnvelopeValid:[self.poiLayer fullEnvelope]]) {
                            [self.mapView zoomToEnvelope:self.poiLayer.fullEnvelope animated:YES];
                        }
                        
                        NSLog(@"Done zoom to current POI envelope!");
                        
                    }else {
                        NSLog(@"Problem in loading POI features.");
                    }
                    NSLog(@"POI feature layer %@, # of features=%d, full envelope=%@", self.poiLayer.name, [self.poiLayer.graphics count], [self.poiLayer fullEnvelope]);
                }];                

            }else {
                UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:@"Failed to find 4 required fields (Name, Description, Photo URL and Thumbnail URL)."
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
            }
            
        }else if (flayer.geometryType == AGSGeometryTypePolyline) {
            // it is a track?
            NSDictionary *flayerJSON = [flayer encodeToJSON];
            NSLog(@"%@, polyline layer description=>%@", flayer.name, [flayerJSON ags_JSONRepresentation]);
            NSLog(@"# of features=%d", flayer.graphicsCount);
            
            
            AGSQuery *q = [AGSQuery query];
            q.where = @"1=1";
            q.outFields = [NSArray arrayWithObject:@"*"];
            NSOperation *op = [flayer queryFeatures:q];
            [op setCompletionBlock: ^{
                if([flayer.graphics count] > 0) {
                    NSString *features = @"{\"features\":[";
                    for (int k=0; k<flayer.graphicsCount; k++) {
                        if(k>0) {
                            features = [NSString stringWithFormat:@"%@,", features];
                        }
                        features = [NSString stringWithFormat:@"%@%@",features, [[[flayer.graphics objectAtIndex:0] encodeToJSON] ags_JSONRepresentation]];
                    }
                    features = [NSString stringWithFormat:@"%@]}", features];
                    NSLog(@"features=%@", features);
                    
                    [self createStoryMapFolders:self.currentStoryMapInfo.folderName rootPath:[StoryMapUtil getCacheRootPath]];
                    [self createTrackInfoWithName:flayer.name layerDesc:[flayerJSON ags_JSONRepresentation] andFeatures:features];
                    
                }else {
                    NSLog(@"Problem in loading track features.");
                }
            }];
            
        }
    }else if([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
        NSLog(@"didLoadLayer basemap");
        AGSTiledMapServiceLayer *baseMapService = (AGSTiledMapServiceLayer*)layer;
        [self createCacheFolder:baseMapService];
    }else if([layer isKindOfClass:[AGSOpenStreetMapLayer class]]) {
        NSLog(@"didLoadLayer OSM basemap");
        AGSOpenStreetMapLayer *baseMapService = (AGSOpenStreetMapLayer*)layer;
        [self createOSMCacheFolder:baseMapService];
    }
    
    NSLog(@"didLoadLayer visible extent=%@", self.mapView.visibleAreaEnvelope);
    if ([self isEnvelopeValid:self.mapView.visibleAreaEnvelope]) {
        [[StoryMapDatabase sharedStoryMapDatabase] updateStoryMapInfo:self.currentStoryMapInfo withEnvelope:[[self.mapView.visibleAreaEnvelope encodeToJSON] ags_JSONRepresentation]];
    }
}

- (void) createTrackInfoWithName:(NSString*)name  layerDesc:(NSString*)layerDescJson andFeatures:(NSString*)featuresJson
{
    TrackInfo* info = [[TrackInfo alloc] init];
    info.name = name;
    info.storyName = self.currentStoryMapInfo.folderName;
    info.layerDesc = [NSString stringWithFormat:@"%@_desc",[name stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    info.layerFeatures =  [NSString stringWithFormat:@"%@_features", info.layerDesc];
    
    NSError *error;
    NSString *layerInfoFile = [NSString stringWithFormat:@"%@/%@/%@.json", [StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName, info.layerDesc];
    [layerDescJson writeToFile:layerInfoFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    NSString *layerFeaturesFile = [NSString stringWithFormat:@"%@/%@/%@.json", [StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName, info.layerFeatures];
    [featuresJson writeToFile:layerFeaturesFile atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    [[StoryMapDatabase sharedStoryMapDatabase] addStoryMapTrack:info];
}

- (BOOL)isEnvelopeValid:(AGSEnvelope*)envelope
{
    if (envelope && ![envelope isKindOfClass: [NSNull class]]) {
        if (isnan(envelope.xmin) || isnan(envelope.ymin) || isnan(envelope.xmax) || isnan(envelope.ymax)) {
            return NO;
        }else {
            return YES;
        }
    }
    return NO;
}

- (void) webMap:(AGSWebMap *)webMap didFailToLoadLayer:(AGSWebMapLayerInfo *)layerInfo
      baseLayer:(BOOL) 	baseLayer
      federated:(BOOL) 	federated
      withError:(NSError *) 	error
{
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:[NSString stringWithFormat:@"The layer %@ cannot be displayed",layerInfo.title]
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
    
    // and skip loading this layer
    [self.webMap continueOpenAndSkipCurrentLayer];
    
}

#pragma mark 
#pragma mark AGSMapViewTouchDelegate

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {
    NSLog(@"didClickAtPoint %d", [[graphics allValues] count]);
    BOOL exists;
    
    NSArray *keys = [graphics allKeys];
    for (int i=0; i<[keys count]; i++) {
        BOOL found=NO;
        id key = [keys objectAtIndex:i];
        NSArray *graphicSet = [graphics objectForKey:key];
        
        for (int j=0; j<[graphicSet count]; j++) {
            AGSGraphic *graphic = [graphicSet objectAtIndex:j];        
            if([graphic.geometry isKindOfClass:[AGSPoint class]]) {
                for(int k=0; k<[self.graphicsLayer.graphics count]; k++) {
                    AGSGraphic *feature = [self.graphicsLayer.graphics objectAtIndex:k];
                    if([feature.geometry isKindOfClass:[AGSPoint class]]) {
                        int graphic_index = [graphic attributeAsIntegerForKey:self.indexFieldName exists:&exists];
                        int feature_index = [feature attributeAsIntegerForKey:self.indexFieldName exists:&exists];
                        if (graphic_index == feature_index) {
                            self.currentIndex = graphic_index;
                            [self setThumbnailViewStatus:graphic_index doScroll:YES];
                            [self showFeature];
                            found = YES;
                            break;
                        }
                    }
                }
            }
        }
        
        if(found) {
            break;
        }
    } 
}

// determine if we should show a callout
//- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic
//{
//    BOOL exists;
//    BOOL found=NO;
//    if([graphic.geometry isKindOfClass:[AGSPoint class]]) {
//        for(int k=0; k<[self.graphicsLayer.graphics count]; k++) {
//            AGSGraphic *feature = [self.graphicsLayer.graphics objectAtIndex:k];
//            if([feature.geometry isKindOfClass:[AGSPoint class]]) {
//                int graphic_index = [graphic attributeAsIntegerForKey:self.indexFieldName exists:&exists];
//                int feature_index = [feature attributeAsIntegerForKey:self.indexFieldName exists:&exists];
//                if (graphic_index == feature_index) {
//                    self.lastIndex = self.currentIndex;
//                    self.currentIndex = graphic_index;
//                    [self setThumbnailViewStatus:graphic_index doScroll:YES];
//                    [self showFeature];
//                    found = YES;
//                    break;
//                }
//            }
//        }
//    }
//    return found;
//}

#pragma mark
#pragma mark StoryMapManagerViewControllerDelegate

- (void) removeStoryMap:(StoryMapInfo*)storyMapInfo {
    NSLog(@"Remove story map:%@", storyMapInfo.title);
    
    if ([storyMapInfo.url isEqualToString:self.currentStoryMapInfo.url]) {
        [self resetCurrentStoryMap];
    }
    
    NSError *error;
    NSString *path =[NSString stringWithFormat:@"%@/%@", [StoryMapUtil getCacheRootPath], storyMapInfo.folderName];
    BOOL success = [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
    if(success) {
        [[StoryMapDatabase sharedStoryMapDatabase] removeStoryMap:storyMapInfo.url andStoryTable:storyMapInfo.poiTableName];

        if (storyMapInfo.tileServiceUrl1) {
            [self removeTileCache:storyMapInfo.tileServiceUrl1];
        }
        if (storyMapInfo.tileServiceUrl2) {
            [self removeTileCache:storyMapInfo.tileServiceUrl2];
        }
        if (storyMapInfo.tileServiceUrl3) {
            [self removeTileCache:storyMapInfo.tileServiceUrl3];
        }
        if (storyMapInfo.tileServiceUrl4) {
            [self removeTileCache:storyMapInfo.tileServiceUrl4];
        }
        
        [[StoryMapDatabase sharedStoryMapDatabase] removeStoryMapTracks:storyMapInfo.folderName];
    }

}
- (void) removeTileCache:(NSString*)tileServiceUrl
{
    BOOL found = NO;
    for (StoryMapInfo *info in [StoryMapDatabase sharedStoryMapDatabase].storyMapInfos) {
        if (info.tileServiceUrl1 && [info.tileServiceUrl1 isEqualToString:tileServiceUrl]) {
            found = YES;
        }
        if (info.tileServiceUrl2 && [info.tileServiceUrl2 isEqualToString:tileServiceUrl]) {
            found = YES;
        }
        if (info.tileServiceUrl3 && [info.tileServiceUrl3 isEqualToString:tileServiceUrl]) {
            found = YES;
        }
        if (info.tileServiceUrl4 && [info.tileServiceUrl4 isEqualToString:tileServiceUrl]) {
            found = YES;
        }
    }
    if (!found) {
        NSError *error;
        NSString *path =[NSString stringWithFormat:@"%@/%@/%@", [StoryMapUtil getCacheRootPath], STORY_MAP_TILES_FOLDER_NAME, [self convertUrl2Local:tileServiceUrl]];
        BOOL success = [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
        NSLog(@"%@, Remove tiles at%@",success?@"true":@"false", path);

        if(success) {
            success = [[StoryMapDatabase sharedStoryMapDatabase] removeTileService:tileServiceUrl];
            NSLog(@"Remove tile entry in the database, success=%@", success?@"true":@"false");
        }
    }
    
}

- (void)resetCurrentStoryMap {
    self.currentStoryMapInfo = nil;

    [self.thumbnailViews removeAllObjects];
    for(UIView *view in [self.scrollView subviews]) {
        [view removeFromSuperview];
    }
    
    if(self.graphicsLayer) {
        [self.graphicsLayer removeAllGraphics];
    }

    self.currentIndex = 0;
    self.graphicsLayerLoaded = NO;
    self.poiDownloaded = NO;
    self.thumbnailViewsCreated = NO;
    
    self.imageView.image = nil;
    self.storyMapDescription.text = @"";
    self.storyMapTitle.text = @"";
    self.imageTitle.text = @"";
    self.imageDescription.text = @"";
    self.imageTileDescView.hidden = YES;
    self.poiLayer = nil;
    self.pictureDownloadStarted = NO;

    NSLog(@"Reset map view");
    for (AGSLayer *layer in [self.mapView mapLayers]) {
        [self.mapView removeMapLayer:layer];
    }
    [self.mapView reset];
}

- (void)loadStoryMapWithWebmap:(NSString*)webmapId_ andUrl:(NSString *)url_
{
    if(webmapId_ && url_) {        
        [self resetCurrentStoryMap];

        if (self.configPopoverController.isPopoverVisible) {
            [self.configPopoverController dismissPopoverAnimated:YES];
        }
        
        NSString *msg = [NSString stringWithFormat:@"Initializing story map ... ..."];
        [self updateStatus:msg showActivity:YES];

        
        // re-create StoryMapInfo
        [self createStoryMapInfo];
        self.currentStoryMapInfo.webmapId = webmapId_;
        self.currentStoryMapInfo.url = url_;
        self.configViewController.currentSelectedStoryMap = self.currentStoryMapInfo;
 
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:self.currentStoryMapInfo.url forKey:LAST_STORY_MAP_URL];
        [defaults  synchronize];
        
        [self createNewStoryMap];
        [self loadWebmap];
    }
}

- (void) loadStoryMapWithStoryMapInfo:(StoryMapInfo *)storyMapInfo
{
    if (self.currentStoryMapInfo == storyMapInfo || [self.currentStoryMapInfo.url isEqualToString:storyMapInfo.url]) {
        if (self.configPopoverController.isPopoverVisible) {
            [self.configPopoverController dismissPopoverAnimated:YES];
        }
        return;
    }
    
    [self resetCurrentStoryMap];
    
    self.currentStoryMapInfo = storyMapInfo;
    self.storyMapTitle.text = self.currentStoryMapInfo.title;
    self.storyMapDescription.text = self.currentStoryMapInfo.description;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.currentStoryMapInfo.url forKey:LAST_STORY_MAP_URL];
    [defaults  synchronize];
    
    NSString *rootPath = [StoryMapUtil getCacheRootPath];
    
    // add base map layers
    int numBaseMaps = 0;
    if (storyMapInfo.tileServiceUrl1) {
        TileServiceInfo *info = [self findTiledServiceInfo:storyMapInfo.tileServiceUrl1];
        if (info) {
            NSLog(@"tile layer url=%@", info.url);
            NSString *dirPath = [NSString stringWithFormat:@"%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,info.url_local];
            [self addOfflineTiledLayer2Map:dirPath tileServiceInfo:info andLayerName:@"Tiled Layer 1"];
            numBaseMaps++;
        }else{
            NSLog(@"Warning: couldn't find tiled service info.");
        }
    }

    if (storyMapInfo.tileServiceUrl2 && [storyMapInfo.tileServiceUrl2 length]>5) {
        TileServiceInfo *info = [self findTiledServiceInfo:storyMapInfo.tileServiceUrl2];
        if (info) {
            NSLog(@"tile layer url=%@", info.url);
            NSString *dirPath = [NSString stringWithFormat:@"%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,info.url_local];
            [self addOfflineTiledLayer2Map:dirPath tileServiceInfo:info andLayerName:@"Tiled Layer 2"];
            numBaseMaps++;
        }else{
            NSLog(@"Warning: couldn't find tiled service info.");
        }
    }
    
    if (storyMapInfo.tileServiceUrl3 && [storyMapInfo.tileServiceUrl3 length]>5) {
        TileServiceInfo *info = [self findTiledServiceInfo:storyMapInfo.tileServiceUrl3];
        if (info) {
            NSLog(@"tile layer url=%@", info.url);
            NSString *dirPath = [NSString stringWithFormat:@"%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,info.url_local];
            [self addOfflineTiledLayer2Map:dirPath tileServiceInfo:info andLayerName:@"Tiled Layer 3"];
            numBaseMaps++;
        }else{
            NSLog(@"Warning: couldn't find tiled service info.");
        }
    }
    
    if (storyMapInfo.tileServiceUrl4 && [storyMapInfo.tileServiceUrl4 length]>5) {
        TileServiceInfo *info = [self findTiledServiceInfo:storyMapInfo.tileServiceUrl4];
        NSLog(@"tile layer url=%@", info.url);
        if (info) {
            NSString *dirPath = [NSString stringWithFormat:@"%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,info.url_local];
            [self addOfflineTiledLayer2Map:dirPath tileServiceInfo:info andLayerName:@"Tiled Layer 4"];
            numBaseMaps++;
        }else{
            NSLog(@"Warning: couldn't find tiled service info.");
        }
    }
    NSLog(@"# of tiled layers=%d", numBaseMaps);
    self.tocButton.hidden = numBaseMaps<=1;
}

-(TileServiceInfo*)findTiledServiceInfo:(NSString*)urlstring
{
    NSArray* tiledServiceInfos = [[StoryMapDatabase sharedStoryMapDatabase] tileServiceInfos];
    for (TileServiceInfo *info in tiledServiceInfos){
        if ([info.url isEqualToString:urlstring]) {
            return info;
        }
    }
    return nil;
}

- (void) addOfflineTiledLayer2Map:(NSString*)tilePath tileServiceInfo:(TileServiceInfo*)tileServiceInfo_ andLayerName:(NSString*)layerName
{
	NSError* err;
    AGSEnvelope *fullEnvelope = [[AGSEnvelope alloc] initWithJSON:[tileServiceInfo_.fullEnvelope ags_JSONValue]];
    AGSTileInfo *tileInfo = [[AGSTileInfo alloc] initWithJSON:[tileServiceInfo_.tileInfo ags_JSONValue]];
    NSString *lowerUnits = [tileServiceInfo_.units lowercaseString];
    AGSUnits units = AGSUnitsMeters;
    if([@"foot_us" isEqualToString:lowerUnits] || [@"foot" isEqualToString:lowerUnits]){
		units = AGSUnitsFeet;
	}else if([@"meter" isEqualToString:lowerUnits]){
		units = AGSUnitsMeters;
	}else if([@"degree" isEqualToString:lowerUnits]){
		units = AGSUnitsDecimalDegrees;
	}
    
    NSLog(@"full envelope=%@", fullEnvelope);
    NSLog(@"tile info=%@", tileInfo);
    NSLog(@"units=%d, full=%@", units, tileServiceInfo_.fullEnvelope);
    
	//Initialze the layer
	OfflineTiledLayer* tiledLyr = [[OfflineTiledLayer alloc] initWithDataFramePath:tilePath fullEnvelope:fullEnvelope tileInfo:tileInfo units:units andTileServiceInfo:tileServiceInfo_];
    tiledLyr.delegate = self;
    
	//If layer was initialized properly, add to the map
	if(tiledLyr!=nil){
        NSLog(@"Adding offline tiled service layer %@, map view=%@", tilePath, self.mapView);
		[self.mapView addMapLayer:tiledLyr withName:layerName];
	}else{
		//layer encountered an error
		NSLog(@"Error encountered: %@", err);
	}
}

#pragma mark
#pragma mark AGSLayerDelegate

- (void) layerDidLoad:(AGSLayer *) layer
{
    [self.configPopoverController dismissPopoverAnimated:YES];
    NSLog(@"%@ loaded, spatial reference: %@", layer.name, self.mapView.spatialReference);
    
    AGSEnvelope *initEnvelope = [[AGSEnvelope alloc] initWithJSON:[self.currentStoryMapInfo.envelope ags_JSONValue]];
    [self.mapView zoomToEnvelope:initEnvelope animated:YES];
    
    if (!self.thumbnailViewsCreated) {
        [self createThumbnailViews];
    }
}

-(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(NSString*)convert2HtmlDoc:(NSString*)text
{
    return [NSString stringWithFormat:@"<html><body bgcolor=\"#000000\" text=\"#FFFFFF\">%@</body></html>", text];
}

- (NSString*)removeHyperlink:(NSString*)text
{
    NSRange range1 = [text rangeOfString:@"<a "];
    if (range1.location == NSNotFound) {
        return text;
    }
    NSRange range2 = [text rangeOfString:@">"];
    if (range2.location == NSNotFound) {
        return text;
    }
    NSRange range3 = [text rangeOfString:@"</a>"];
    if (range3.location == NSNotFound) {
        return text;
    }
    
    NSString *text1 = [text substringToIndex:range1.location];
    NSString *text2 = [text substringFromIndex:range2.location + 1];
    text2 = [text2 substringToIndex:text2.length-2];

    return [NSString stringWithFormat:@"%@%@", text1, text2];
}

-(NSDictionary *)readJSONFile:(NSString*)filename
{
    NSError *error = nil;
    NSDictionary *jsonDictionary = nil;
    NSLog(@"%@ %@", filename, [[NSFileManager defaultManager] fileExistsAtPath:filename]?@"true":@"false");
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
		NSString *flDefinitionString = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
        
        jsonDictionary = (NSDictionary *)[flDefinitionString ags_JSONValue];
    }
    
	return jsonDictionary;
}


- (void) createRouteLayer
{
    NSString *layerInfoFile = [NSString stringWithFormat:@"%@/%@/routelayerinfo.json", [StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName];
    NSDictionary *layerInfo = [self readJSONFile:layerInfoFile];
    NSString *layerFeaturesFile = [NSString stringWithFormat:@"%@/%@/routelayer.json", [StoryMapUtil getCacheRootPath], self.currentStoryMapInfo.folderName];
    NSDictionary *layerFeatures = [self readJSONFile:layerFeaturesFile];
    
    if (layerFeatures && layerInfo) {
        AGSFeatureLayer *routeLayer = [[AGSFeatureLayer alloc] initWithLayerDefinitionJSON:layerInfo featureSetJSON:layerFeatures];
        [self.mapView addMapLayer:routeLayer withName:@"Route Layer"];
    }
}


- (void) createTrackLayers
{
    for (TrackInfo* trackInfo in [StoryMapDatabase sharedStoryMapDatabase].storyMapTrackInfos) {
        if ([trackInfo.storyName isEqualToString:self.currentStoryMapInfo.folderName]) {
            NSString *layerInfoFile = [NSString stringWithFormat:@"%@/%@/%@.json", [StoryMapUtil getCacheRootPath], trackInfo.storyName, trackInfo.layerDesc];
            NSDictionary *layerInfo = [self readJSONFile:layerInfoFile];
            NSString *layerFeaturesFile = [NSString stringWithFormat:@"%@/%@/%@.json", [StoryMapUtil getCacheRootPath], trackInfo.storyName, trackInfo.layerFeatures];
            NSDictionary *layerFeatures = [self readJSONFile:layerFeaturesFile];
            
            if (layerFeatures && layerInfo) {
                AGSFeatureLayer *routeLayer = [[AGSFeatureLayer alloc] initWithLayerDefinitionJSON:layerInfo featureSetJSON:layerFeatures];
                [self.mapView addMapLayer:routeLayer withName:trackInfo.name];
            }
        }
    }
}

-(void)createPOIGraphics {
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];

    self.highlightGraphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.highlightGraphicsLayer withName:@"Highlight Graphics Layer"];
    
    // add POI layer
    AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:4326];
    NSString *tableName = self.currentStoryMapInfo.folderName;
    NSArray *poiInfos = [[StoryMapDatabase sharedStoryMapDatabase] readPOIInfoFromDatabase:tableName];
    
    NSLog(@"createPOIGraphics ======POIInfos # of POIs=%d", [poiInfos count]);
    if ([poiInfos count]==0) {
        return;
    }
    self.graphicsLayerLoaded = YES;
    
    int count=0;
    double xmin,ymin,xmax,ymax;
    for (POIInfo *info in poiInfos) {
        if (count==0) {
            xmin = info.lon; xmax = info.lon;
            ymin = info.lat; ymax = info.lat;
        }else {
            if (xmin > info.lon) {
                xmin = info.lon;
            }
            if(xmax < info.lon){
                xmax = info.lon;
            }
            if(ymin > info.lat) {
                ymin = info.lat;
            }
            if(ymax < info.lat) {
                ymax = info.lat;
            }
        }
        count++;
        if (info.index==0) {
            continue;
        }
        
        AGSPictureMarkerSymbol *mSymbol = [self createPictureSymbolWithIconColor:info.icon_color index:info.index andScale:0.5f];
        NSLog(@"image size w=%f, h=%f", mSymbol.size.width, mSymbol.size.height);
        
        AGSPoint *point = [[AGSPoint alloc] initWithX:info.lon y:info.lat spatialReference:sr];
        point = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:point toSpatialReference:self.mapView.spatialReference];
        NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
        [attributes setObject:[NSNumber numberWithInt:info.index] forKey:self.indexFieldName];
        [attributes setObject:info.name forKey:self.nameFieldName];
        [attributes setObject:info.icon_color forKey:self.iconColorFieldName];
        [attributes setObject:info.description forKey:self.descFieldName];
        [attributes setObject:info.url forKey:self.urlFieldName];
        [attributes setObject:info.url_local forKey:self.urlLocalFieldName];
        [attributes setObject:info.thumbnail_url forKey:self.thumbnailUrlFieldName];
        [attributes setObject:info.thumbnail_url_local forKey:self.thumbnailUrlLocalFieldName];
        
        AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry:point symbol:mSymbol attributes:attributes infoTemplateDelegate:nil];
        [self.graphicsLayer addGraphic:graphic];
        NSLog(@"name=%@, x=%f, y=%f, icon color=%@", info.name, info.lon, info.lat, info.icon_color);
        
    }
    
    NSLog(@"xmin=%f, ymin=%f, xmax=%f, ymax=%f", xmin, ymin, xmax, ymax);
    AGSEnvelope *envelope = [[AGSEnvelope alloc] initWithXmin:xmin ymin:ymin xmax:xmax ymax:ymax spatialReference:sr];
    [self.mapView zoomToEnvelope:envelope animated:YES];
    
}

- (AGSPictureMarkerSymbol*)createPictureSymbolWithIconColor:(NSString*)icon_color index:(int)index andScale:(float)scale {
    NSString *imageFilePath = [NSString stringWithFormat:@"markerImages/red/NumberIcon%d.png", index];
    if ([[icon_color lowercaseString] isEqualToString:@"b"]) {
        imageFilePath = [NSString stringWithFormat:@"markerImages/blue2/NumberIconb%d.png",index];
    }else if ([[icon_color lowercaseString] isEqualToString:@"g"]) {
        imageFilePath = [NSString stringWithFormat:@"markerImages/green/NumberIcon%d.png",index];
    }
    UIImage *original = [UIImage imageNamed:imageFilePath];
    UIImage *image = [self imageWithImage:original scaledToSize:CGSizeMake(original.size.width*scale, original.size.height*scale)];
    AGSPictureMarkerSymbol *mSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:image];
    mSymbol.offset = CGPointMake(1, 8);
    return mSymbol;
}

#pragma mark
#pragma mark ThumbnailViewDelegate

- (void)thumbnailViewSelected:(int)thumbnailIndex
{
    self.currentIndex = thumbnailIndex;
    [self showFeature];
    
    NSLog(@"# of thumbnails=%d, current selection=%d", [self.thumbnailViews count], thumbnailIndex);
    [self setThumbnailViewStatus:thumbnailIndex doScroll:NO];
}

- (void)thumbnailViewWillAppear:(int)thumbnailIndex
{
    // start download all pictures
    if (!self.pictureDownloadStarted) {
        NSString *tableName = self.currentStoryMapInfo.folderName;
        NSArray *poiInfos = [[StoryMapDatabase sharedStoryMapDatabase] readPOIInfoFromDatabase:tableName];
        for (POIInfo *info in poiInfos) {
            [self downloadPhotoAndSave2LocalDriveWithUrl:info.url updateUI:NO];
        }
        self.pictureDownloadStarted = YES;
    }
    
    [self updateStatusToEmpty];
}

-(void)setThumbnailViewStatus:(int)selectedIndex doScroll:(BOOL)doscroll {
    for (ThumbnailView *view in self.thumbnailViews) {
        if ([view getThumbnailIndex] != selectedIndex) {
            [view setCurrentPhotoSelected:NO];
        }else {
            [view setCurrentPhotoSelected:YES];
        }
    }
    
    if(doscroll){
        if (selectedIndex > 2) {
            selectedIndex = selectedIndex - 2;
        }
        float x = selectedIndex*(THUMBNAIL_VIEW_WIDTH+THUMBNAIL_VIEW_GAP);
        CGRect frame = CGRectMake(x, 0, THUMBNAIL_VIEW_WIDTH*5, THUMBNAIL_VIEW_HEIGHT+40);
        [self.scrollView scrollRectToVisible:frame animated:YES];
    }
}

#pragma mark
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest %@, %d", request, navigationType);
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    }
    return YES;
}

#pragma mark
#pragma mark UIScrollWViewDelegate

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    NSLog(@"scrollViewDidScroll: ");
//}
//
//- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
//{
//    NSLog(@" ******* scrollViewDidScrollToTop: ********** ");
//}


@end
