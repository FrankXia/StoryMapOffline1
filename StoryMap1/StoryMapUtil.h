//
//  StoryMapUtil.h
//  StoryMap1
//
//  Created by Frank on 9/6/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StoryMapUtil : NSObject

extern NSString* STORY_MAP_OFFLINE_FOLDER_NAME;
extern NSString* STORY_MAP_TILES_FOLDER_NAME;
extern NSString* STORY_MAP_PHOTOS_FOLDER_NAME;

+(NSString*)getCacheRootPath;
//+(NSString*)getLibraryRootPath;
+(NSString*)getDocumentRootPath;
+(void)createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath;

@end
