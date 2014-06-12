//
//  MapTileUtil.h
//  StoryMap1
//
//  Created by Frank on 9/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapTile.h"
#import <ArcGIS/ArcGIS.h>

@interface MapTileUtil : NSObject

+(AGSEnvelope*) computeBoundingBoxWithX:(int)x y:(int)y andZoomLevel:(int)zoomLevel;
+(MapTile*) findImmediateMapTileWithX:(int)x y:(int)y zoomLevel:(int)zoom andEnvelope:(AGSEnvelope*) customBounds;
+(NSArray*) findSubTiles:(MapTile*) gTile;

@end
