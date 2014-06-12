//
//  ThumbnailViewController.h
//  StoryMap1
//
//  Created by Frank on 8/27/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POIInfo.h"

@protocol ThumbnailViewControllerDelegate;

@interface ThumbnailViewController : UIViewController

@property (nonatomic, weak) id <ThumbnailViewControllerDelegate> delegate;


@property (nonatomic) BOOL isPhotoSelected;

-(void)updateWithPOIInfo: (POIInfo*)info storyMapFolder:(NSString*)name andPhotoFolder:(NSString*)folderName;
-(int)getThumbnailIndex;
-(void)setCurrentPhotoSelected:(BOOL)selected;

@end

@protocol ThumbnailViewControllerDelegate <NSObject>
- (void)thumbnailViewSelected:(int)thumbnailIndex;
@end
