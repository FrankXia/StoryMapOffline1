//
//  StoryMapUtil.m
//  StoryMap1
//
//  Created by Frank on 9/6/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "StoryMapUtil.h"

@implementation StoryMapUtil

NSString* STORY_MAP_OFFLINE_FOLDER_NAME  = @"storymaps";
NSString* STORY_MAP_TILES_FOLDER_NAME  = @"tiles";
NSString* STORY_MAP_PHOTOS_FOLDER_NAME = @"photos";

+(void)createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
{
    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
    NSError *error;
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
    }
}

+(NSString*)getDocumentRootPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *rootPath = [paths objectAtIndex:0];
    return rootPath;
}

+(NSString*)getLibraryRootPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *rootPath = [paths objectAtIndex:0];
    return rootPath;
}

//+(NSString*)getCacheRootPath
//{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
//    NSString *rootPath = [paths objectAtIndex:0];
//    return [NSString stringWithFormat:@"%@/Caches", rootPath]; // this folder gets cleaned up perioidcally
//}

+(NSString*)getCacheRootPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *rootPath = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%@", rootPath, STORY_MAP_OFFLINE_FOLDER_NAME];
}

@end
