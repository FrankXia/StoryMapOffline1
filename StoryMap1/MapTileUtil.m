//
//  MapTileUtil.m
//  StoryMap1
//
//  Created by Frank on 9/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <ArcGIS/ArcGIS.h>
#import "MapTileUtil.h"
#import "MapTile.h"

@implementation MapTileUtil

/**
 * zoom level 0 is the global view while maximum zoom level is the most detail one
 */
+(AGSEnvelope*) computeBoundingBoxWithX:(int)x y:(int)y andZoomLevel:(int)zoomLevel {
    // ------------------------------------------------------
    // NOTE: zoom is G-style
    // ------------------------------------------------------
    
    double lon;// = -180; // x
    double lonWidth;// = 360; // width 360
    
    //double lat = -90;  // y
    //double latHeight = 180; // height 180
    double lat;// = -1;
    double latHeight;// = 2;
    
    //int tilesAtThisZoom = 1 << (19 - zoomLevel);
    int tilesAtThisZoom = 1 << (zoomLevel);
    lonWidth = 360.0 / tilesAtThisZoom;
    lon = -180 + (x * lonWidth);
    latHeight = -2.0 / tilesAtThisZoom;
    lat = 1 + (y * latHeight);
    
    // convert lat and latHeight to degrees in a transverse mercator projection
    // note that in fact the coordinates go from about -85 to +85 not -90 to 90!
    latHeight += lat;
    latHeight = (2 * atan(exp(M_PI * latHeight))) - (M_PI / 2);
    latHeight *= (180 / M_PI);
    
    lat = (2 * atan(exp(M_PI * lat))) - (M_PI / 2);
    lat *= (180 / M_PI);
    
    latHeight -= lat;
    
    if (lonWidth < 0) {
        lon = lon + lonWidth;
        lonWidth = -lonWidth;
    }
    
    if (latHeight < 0) {
        lat = lat + latHeight;
        latHeight = -latHeight;
    }
    
    AGSSpatialReference *spatialRef = [[AGSSpatialReference alloc] initWithWKID:4326];
    return [[AGSEnvelope alloc] initWithXmin:lon ymin:lat xmax:lon+lonWidth ymax:lat+latHeight spatialReference:spatialRef];
}

/**
 * find immediate map tile that covers the given envelope with given col/x and row/y
 **/
+(MapTile*) findImmediateMapTileWithX:(int)x y:(int)y zoomLevel:(int)zoom andEnvelope:(AGSEnvelope*) customBounds
{
    // starting from top tile
    AGSEnvelope *bbox = [MapTileUtil computeBoundingBoxWithX:x y:y andZoomLevel:zoom];
    if (![bbox containsEnvelope:customBounds])
        return nil;
    
    AGSEnvelope *topLeft = [MapTileUtil computeBoundingBoxWithX:2*x y:2*y andZoomLevel:zoom+1];   // top left
    if ([topLeft containsEnvelope:customBounds])
    {
        return [MapTileUtil findImmediateMapTileWithX:2*x y:2*y zoomLevel:zoom+1 andEnvelope:customBounds];
    }
    
    AGSEnvelope *topRight = [MapTileUtil computeBoundingBoxWithX:2*x+1 y:2*y andZoomLevel:zoom+1]; // top right
    if ([topRight containsEnvelope:customBounds])
    {
        return [MapTileUtil findImmediateMapTileWithX:2*x+1 y:2*y zoomLevel:zoom+1 andEnvelope:customBounds];
    }
    
    AGSEnvelope *bottomLeft = [MapTileUtil computeBoundingBoxWithX:2*x y:2*y+1 andZoomLevel:zoom+1];   // bottom left
    if ([bottomLeft containsEnvelope:customBounds])
    {
        return [MapTileUtil findImmediateMapTileWithX:2*x y:2*y+1 zoomLevel:zoom+1 andEnvelope:customBounds];
    }
    
    AGSEnvelope *bottomRight = [MapTileUtil computeBoundingBoxWithX:2*x+1 y:2*y+1 andZoomLevel:zoom+1];    // bottom right
    if ([bottomRight containsEnvelope:customBounds])
    {
        return [MapTileUtil findImmediateMapTileWithX:2*x+1 y:2*y+1 zoomLevel:zoom+1 andEnvelope:customBounds];
    }
    
    MapTile *mapTile = [[MapTile alloc] init];
    mapTile.col = x;
    mapTile.row = y;
    mapTile.zoomLevel = zoom;
    mapTile.boundingBox = bbox;
    
    return mapTile;
}

/**
 * find all 4 subtiles from a given tile
 */
+(NSArray*) findSubTiles:(MapTile*) gTile
{
    // this is the incoming Tile (parent Tile)
    int x = gTile.col;
    int y = gTile.row;
    int zoom = gTile.zoomLevel;
    
    if (zoom >= 19)     // no more subtiles
        return nil;
    
    // array of 4 to hold on
    NSMutableArray *subTiles = [[NSMutableArray alloc] initWithCapacity:4];
    
    AGSEnvelope *topLeft = [MapTileUtil computeBoundingBoxWithX:2*x y:2*y andZoomLevel:zoom+1];  // top left
    [subTiles addObject: [[MapTile alloc] initWithCol:2*x row:2*y zoomLevel:zoom+1 andEnvelope:topLeft]];
    
    AGSEnvelope *topRight = [MapTileUtil computeBoundingBoxWithX:2*x+1 y:2*y andZoomLevel:zoom+1];   // top right
    [subTiles addObject: [[MapTile alloc] initWithCol:2*x+1 row:2*y zoomLevel:zoom+1 andEnvelope:topRight]];
    
    AGSEnvelope *bottomLeft = [MapTileUtil computeBoundingBoxWithX:2*x y:2*y+1 andZoomLevel:zoom+1];   // bottom left
    [subTiles addObject:[[MapTile alloc] initWithCol:2*x row:2*y+1 zoomLevel:zoom+1 andEnvelope:bottomLeft]];
    
    AGSEnvelope *bottomRight = [MapTileUtil computeBoundingBoxWithX:2*x+1 y:2*y+1 andZoomLevel:zoom+1];   // bottom right
    [subTiles addObject:[[MapTile alloc] initWithCol:2*x+1 row:2*y+1 zoomLevel:zoom+1 andEnvelope:bottomRight]];
    
    return subTiles;
}


@end
