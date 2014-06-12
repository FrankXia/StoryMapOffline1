//
//  MapTile.m
//  StoryMap1
//
//  Created by Frank on 9/3/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "MapTile.h"

@implementation MapTile

-(id)initWithCol:(int)x row:(int)y zoomLevel:(int)level andEnvelope:(AGSEnvelope*)envelope
{
    self = [super init];
    if (self) {
        self.col = x;
        self.row = y;
        self.zoomLevel = level;
        self.boundingBox = envelope;
    }
    
    return self;
}

@end
