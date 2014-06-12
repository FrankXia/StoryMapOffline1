//
//  StoryMapDatabase.h
//  StoryMap1
//
//  Created by Frank on 8/29/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StoryMapInfo.h"
#import "POIInfo.h" 
#import "TrackInfo.h"
#import "TileServiceInfo.h"

@interface StoryMapDatabase : NSObject

@property (nonatomic, strong) NSArray *storyMapInfos;
@property (nonatomic, strong) NSArray *storyMapTrackInfos;
@property (nonatomic, strong) NSArray *tileServiceInfos;

+ (StoryMapDatabase*)sharedStoryMapDatabase;

- (void) readStoryMapInfoFromDatabase;
- (void) readStoryMapTrackInfoFromDatabase;

- (BOOL) addStoryMap:(StoryMapInfo*)storyMapInfo;
- (BOOL) removeStoryMap:(NSString*)storyMapUrl andStoryTable:(NSString*)name ;
- (BOOL) updateStoryMapInfo:(StoryMapInfo*)storyMapInfo withBaseMapIndex:(int)index;
- (BOOL) updateStoryMapInfo:(StoryMapInfo*)storyMapInfo withEnvelope:(NSString*)envelopeJson;
- (BOOL) updateStoryMapInfo:(StoryMapInfo*)storyMapInfo withTile:(NSString*)title andDescription:(NSString*)description;

- (BOOL) addStoryMapTrack:(TrackInfo*)trackInfo;
- (BOOL) removeStoryMapTracks:(NSString*)storyMapName;

- (BOOL) createStoryMapTable:(NSString*)name;
- (BOOL) addPOI:(POIInfo*)poiInfo toTable:(NSString*)name;
- (NSArray*) readPOIInfoFromDatabase:(NSString*)tableName;

- (void) readTileServiceInfoFromDatabase;

- (BOOL) addTileService:(TileServiceInfo*)tileServiceInfo;
- (BOOL) removeTileService:(NSString*)serviceUrl;


@end
