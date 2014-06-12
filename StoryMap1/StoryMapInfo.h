//
//  StoryMap.h
//  StoryMap1
//
//  Created by Frank on 8/30/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StoryMapInfo : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *webmapId;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *poiTableName;
@property (nonatomic, strong) NSString *folderName;

@property (nonatomic, strong) NSString *tileServiceUrl1; // as a link to tile service layer 
@property (nonatomic, strong) NSString *tileServiceUrl2; // as a link to tile service layer
@property (nonatomic, strong) NSString *tileServiceUrl3; // as a link to tile service layer
@property (nonatomic, strong) NSString *tileServiceUrl4; // as a link to tile service layer

@property (nonatomic) BOOL topTileLoaded1;
@property (nonatomic) BOOL topTileLoaded2;
@property (nonatomic) BOOL topTileLoaded3;
@property (nonatomic) BOOL topTileLoaded4;


@property (nonatomic) BOOL offline; // transit variable

@property (nonatomic, strong) NSString *envelope;    // initial extent
@property (nonatomic, strong) NSString *comment;

@end
