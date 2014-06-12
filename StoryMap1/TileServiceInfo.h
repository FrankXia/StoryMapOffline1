//
//  TileServiceInfo.h
//  StoryMap1
//
//  Created by Frank on 8/30/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TileServiceInfo : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *url_local;
@property (nonatomic, strong) NSString *tileInfo;
@property (nonatomic, strong) NSString *envelope;
@property (nonatomic, strong) NSString *fullEnvelope;
@property (nonatomic, strong) NSString *units;
@property (nonatomic, strong) NSString *format;
@property (nonatomic, strong) NSString *type;

@end
