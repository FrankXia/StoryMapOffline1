//
//  POIInfo.h
//  StoryMap1
//
//  Created by Frank on 8/30/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface POIInfo : NSObject

@property (nonatomic) int index; // not guranntee to have, some story maps have, some don't 
@property (nonatomic) double lat;
@property (nonatomic) double lon;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *icon_color;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *thumbnail_url;

@property (nonatomic, strong) NSString *url_local;
@property (nonatomic, strong) NSString *thumbnail_url_local;

@end
