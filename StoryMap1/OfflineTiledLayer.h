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

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "StoryMapInfo.h"
#import "TileServiceInfo.h"

@interface OfflineTiledLayer : AGSTiledServiceLayer   {
@protected
	NSString* _dataFramePath;
	AGSTileInfo* _tileInfo;
	AGSEnvelope* _fullEnvelope;
	AGSUnits _units;
}

@property (nonatomic,strong,readwrite) NSString* dataFramePath;

@property (nonatomic, strong) TileServiceInfo *tileServiceInfo;

- (id)initWithDataFramePath: (NSString *)path error:(NSError**)outError ;
- (id)initWithDataFramePath: (NSString *)path fullEnvelope:(AGSEnvelope*)envelope tileInfo:(AGSTileInfo*)tileinfo units:(AGSUnits)units andTileServiceInfo:(TileServiceInfo*)serviceInfo;

@end
