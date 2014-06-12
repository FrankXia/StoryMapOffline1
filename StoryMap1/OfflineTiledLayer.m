// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import "OfflineTiledLayer.h"
#import "OfflineTileOperation.h"
#import "OfflineCacheParserDelegate.h"
#import "StoryMapViewController.h"  
#import "StoryMapUtil.h"
#import "Reachability.h"

//Function to convert [UNIT] component in WKT to AGSUnits
int MakeAGSUnits(NSString* wkt){
	NSString* value ;
	BOOL _continue = YES;
 	NSScanner* scanner = [NSScanner scannerWithString:wkt];
	//Scan for the UNIT information in WKT. 
	//If WKT is for a Projected Coord System, expect two instances of UNIT, and use the second one
	while (_continue) {
		[scanner scanUpToString:@"UNIT[\"" intoString:NULL];
		[scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"UNIT[\""]];
		_continue = [scanner scanUpToString:@"\"" intoString:&value];
	}
	if([@"Foot_US" isEqualToString:value] || [@"Foot" isEqualToString:value]){
		return AGSUnitsFeet;
	}else if([@"Meter" isEqualToString:value]){
		return AGSUnitsMeters;
	}else if([@"Degree" isEqualToString:value]){
		return AGSUnitsDecimalDegrees;
	}else{
		//TODO: Not handling other units like Yard, Chain, Grad, etc
		return -1;
	}
}


@implementation OfflineTiledLayer

@synthesize dataFramePath=_dataFramePath;

-(AGSUnits)units{
	return _units;
}
 
-(AGSSpatialReference *)spatialReference{
	return _fullEnvelope.spatialReference;
}
 
-(AGSEnvelope *)fullEnvelope{
	return _fullEnvelope;
}
 
-(AGSEnvelope *)initialEnvelope{
	//Assuming our initial extent is the same as the full extent
	return _fullEnvelope;
}

-(AGSTileInfo*) tileInfo{
	return _tileInfo;
}


#pragma mark
#pragma mark create the layer with tile info,  full envelope, units and data frame path
#pragma mark

- (id)initWithDataFramePath: (NSString *)path fullEnvelope:(AGSEnvelope*)envelope tileInfo:(AGSTileInfo*)tileinfo units:(AGSUnits)units andTileServiceInfo:(TileServiceInfo*)serviceInfo {
	
	if (self = [super init]) {
		self.dataFramePath = path;
        _units = units;
        _tileInfo = tileinfo;
        _fullEnvelope = envelope;
        self.tileServiceInfo = serviceInfo;
        
        //Inform the superclass that we're done
        [super layerDidLoad];
    }
    
    return self;
}

#pragma mark
#pragma mark create the layer with conf.cdi and conf.xml file
#pragma mark

- (id)initWithDataFramePath: (NSString *)path error:(NSError**) outError {
	
	if (self = [super init]) {
		self.dataFramePath = path;
		
		//Parse the conf.cdi file			
		NSString* confCDI = [[NSBundle mainBundle] pathForResource:@"conf" ofType:@"cdi" inDirectory: _dataFramePath ];
		NSXMLParser*  xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:confCDI]];
		OfflineCacheParserDelegate* parserDelegate = [[OfflineCacheParserDelegate alloc] init];
		[xmlParser setDelegate:parserDelegate];
		[xmlParser parse];
		
		//Parse the conf.xml file
		NSString* confXML = [[NSBundle mainBundle] pathForResource:@"conf" ofType:@"xml" inDirectory: _dataFramePath];
		xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:confXML]];
		[xmlParser setDelegate:parserDelegate];
		[xmlParser parse];
		
		//If XML files were parsed properly...
		if([parserDelegate tileInfo]!= nil && [parserDelegate fullEnvelope]!=nil ){
			//... get the metadata
			_tileInfo = [parserDelegate tileInfo];
			_fullEnvelope = [parserDelegate fullEnvelope];
			_units = MakeAGSUnits(_fullEnvelope.spatialReference.wkt);
            //Now that we have all the information required...
            //Inform the superclass that we're done
			[super layerDidLoad];
		}else {
			//... return error
            if (outError != NULL) {
                *outError = [parserDelegate error];
            }

			return nil;
		}
    }
    return self;
}

- (void)downloadMissingTile:(AGSTileKey*)tile
{
    NSString *urlstring = [NSString stringWithFormat:@"%@/tile/%d/%d/%d", self.tileServiceInfo.url, tile.level,  tile.row, tile.column];
    if ([self.tileServiceInfo.type isEqualToString:@"osm"]) {
        urlstring = [NSString stringWithFormat:@"%@/%d/%d/%d.png", self.tileServiceInfo.url, tile.level, tile.column, tile.row];
    }
    NSLog(@"tile url=%@, format=%@", urlstring, self.tileServiceInfo.format);
    
    NSString *rootPath = [StoryMapUtil getCacheRootPath];
    
    //Level ('L' followed by 2 decimal digits)
    NSString *decLevel = [NSString stringWithFormat:@"L%02d",tile.level];
    //Row ('R' followed by 8 hex digits)
    NSString *hexRow = [NSString stringWithFormat:@"R%08x",tile.row];
    //Column ('C' followed by 8 hex digits)
    NSString *hexCol = [NSString stringWithFormat:@"C%08x",tile.column];
    
    BOOL isDir;
    NSString *dirPath = [NSString stringWithFormat:@"%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,self.tileServiceInfo.url_local];
    NSString* dir = [NSString stringWithFormat:@"%@/%@/%@/%@",rootPath, STORY_MAP_TILES_FOLDER_NAME,self.tileServiceInfo.url_local,decLevel];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
        [StoryMapUtil createDirectory:decLevel atFilePath:dirPath];
    }
    
    dirPath = dir;
    dir = [NSString stringWithFormat:@"%@/%@",dirPath,hexRow];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir]) {
        [StoryMapUtil createDirectory:hexRow atFilePath:dirPath];
    }
    
    NSString* tileFileName = [NSString stringWithFormat:@"%@/%@.%@", dir, hexCol, self.tileServiceInfo.format];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:tileFileName]) return;
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSURL *url = [NSURL URLWithString:urlstring];
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        [data writeToFile:tileFileName atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [super setTileData:data forKey:tile];
        });
    });
}

#pragma mark -
#pragma AGSTiledLayer (ForSubclassEyesOnly)

- (void)requestTileForKey:(AGSTileKey *)key{
    NSLog(@"tile key=%@", key);
    
    //Level ('L' followed by 2 decimal digits)
    NSString *decLevel = [NSString stringWithFormat:@"L%02d",key.level];
    //Row ('R' followed by 8 hex digits)
    NSString *hexRow = [NSString stringWithFormat:@"R%08x",key.row];
    //Column ('C' followed by 8 hex digits)
    NSString *hexCol = [NSString stringWithFormat:@"C%08x",key.column];    
    NSString *dir = [_dataFramePath stringByAppendingFormat:@"/%@/%@", decLevel, hexRow];
    NSLog(@"dir=%@",dir);
    
    
    //Check for PNG file
    NSString *tileImagePath = [NSString stringWithFormat:@"%@/%@.png", dir, hexCol];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:tileImagePath]) {
        NSLog(@"## tile image path=%@", tileImagePath);
        NSData *imageData= [NSData dataWithContentsOfFile:tileImagePath];
        [super setTileData: imageData  forKey:key];
    }else {
        //If no PNG file, check for JPEG file
        tileImagePath = [NSString stringWithFormat:@"%@/%@.jpg", dir, hexCol];;
        if ([[NSFileManager defaultManager] fileExistsAtPath:tileImagePath]) {
            NSLog(@"#### tile image path=%@", tileImagePath);
            NSData *imageData= [NSData dataWithContentsOfFile:tileImagePath];
            [super setTileData:imageData  forKey:key];
        }
        else {
            NSLog(@"Warning: No tile image found! %@", tileImagePath);
            if ([Reachability reachabilityForInternetConnection]) {
                [self downloadMissingTile:key];
            }        
        }        
    }
}


// The following code caused lot crashes on iPad simulator
/*
- (void)requestTileForKey:(AGSTileKey *)key{
    //Create an operation to fetch tile from local cache
	OfflineTileOperation *operation =
    [[OfflineTileOperation alloc] initWithTileKey:key
                                 dataFramePath:_dataFramePath
                                        target:self
                                        action:@selector(didFinishOperation:)];
    
   
	//Add the operation to the queue for execution
    [ [AGSRequestOperation sharedOperationQueue] addOperation:operation];
}

- (void)cancelRequestForKey:(AGSTileKey *)key{
    //Find the OfflineTileOperation object for this key and cancel it
    for(NSOperation* op in [AGSRequestOperation sharedOperationQueue].operations){
        if( [op isKindOfClass:[OfflineTileOperation class]]){
            OfflineTileOperation* offOp = (OfflineTileOperation*)op;
            if([offOp.tileKey isEqualToTileKey:key]){
                [offOp cancel];
            }
        }
    }
}

- (void) didFinishOperation:(OfflineTileOperation*)op {
    //... pass the tile's data to the super class
    [super setTileData: op.imageData  forKey:op.tileKey];
}
*/

#pragma mark -



@end

