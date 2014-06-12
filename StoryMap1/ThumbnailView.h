//
//  ThumbnailView.h
//  StoryMap1
//
//  Created by Frank on 8/28/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POIInfo.h"

@protocol ThumbnailViewDelegate;

@interface ThumbnailView : UIView

@property (nonatomic, weak) id <ThumbnailViewDelegate> delegate;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *numberLabel;
@property (nonatomic, strong) UIView *numBackgroundView;

-(void)updateWithPOIInfo: (POIInfo*)info storyMapFolder:(NSString*)name andPhotoFolder:(NSString*)folderName;
-(int)getThumbnailIndex;
-(void)setCurrentPhotoSelected:(BOOL)selected;

@end

@protocol ThumbnailViewDelegate <NSObject>
- (void)thumbnailViewSelected:(int)thumbnailIndex;
- (void)thumbnailViewWillAppear:(int)thumbnailIndex;
@end