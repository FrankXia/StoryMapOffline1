//
//  MapTile.h
//  StoryMap1
//
//  Created by Frank on 9/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface MapTile : NSObject

@property (nonatomic) int row;
@property (nonatomic) int col;
@property (nonatomic) int zoomLevel;

@property (nonatomic, strong) AGSEnvelope *boundingBox;


-(id)initWithCol:(int)x row:(int)y zoomLevel:(int)level andEnvelope:(AGSEnvelope*)envelope;

@end
