//
//  ThumbnailView.m
//  StoryMap1
//
//  Created by Frank on 8/28/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "ThumbnailView.h"
#import "StoryMapUtil.h"

@interface ThumbnailView()

@property (nonatomic, strong) POIInfo *poiInfo;
@property (nonatomic, strong) NSString *storyMapFolderName;
@property (nonatomic, strong) NSString *photoFolderName;
@property (nonatomic) BOOL firstTime;

@end

@implementation ThumbnailView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        UITapGestureRecognizer *oneTouch=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
        [oneTouch setNumberOfTouchesRequired:1];
        [self addGestureRecognizer:oneTouch];
        
        self.backgroundColor = [UIColor lightGrayColor];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 132, 92)];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:self.imageView];
        
        self.numBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(4, 4, 27, 18)];
        self.numBackgroundView.backgroundColor = [UIColor redColor];
        [self addSubview:self.numBackgroundView];
        
        self.numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 25, 16)];
        self.numberLabel.backgroundColor = [UIColor clearColor];
        self.numberLabel.textAlignment = NSTextAlignmentCenter;
        self.numberLabel.font = [UIFont systemFontOfSize:12];
        self.numberLabel.textColor = [UIColor whiteColor];
        [self addSubview:self.numberLabel];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 97, 133, 33)];
        self.titleLabel.font = [UIFont systemFontOfSize:12];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.numberOfLines = 0;
        [self addSubview:self.titleLabel];
        self.firstTime = YES;
        
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    if (self.delegate && self.firstTime) {
        NSLog(@"######## Thumbnail view drawRect called ... ");
        [self.delegate thumbnailViewWillAppear:self.poiInfo.index];
        self.firstTime = NO;
    }
}


-(void)updateWithPOIInfo: (POIInfo*)info storyMapFolder:(NSString*)name andPhotoFolder:(NSString*)folderName;
{
    self.poiInfo = info;
    self.photoFolderName = folderName;
    self.storyMapFolderName = name;
    
    if (self.poiInfo.name) {
        self.titleLabel.text = self.poiInfo.name;
    }
    
    if(self.poiInfo) {
        self.numberLabel.text = [NSString stringWithFormat:@"%d",self.poiInfo.index];
        NSLog(@"thumb nail number=%d, label text=%@", self.poiInfo.index, self.numberLabel.text);

        BOOL found = NO;
        NSString *rootPath = [StoryMapUtil getCacheRootPath];
        NSString *photoFileName = [NSString stringWithFormat:@"%@/%@/%@/%@",rootPath, self.storyMapFolderName, self.photoFolderName, self.poiInfo.thumbnail_url_local];

        if(self.poiInfo.thumbnail_url_local) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:photoFileName]) {
                self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:photoFileName]];
                found = YES;
            }
        }
        if (!found) {
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:self.poiInfo.thumbnail_url]];
            self.imageView.image = [UIImage imageWithData:data];
            [data writeToFile:photoFileName atomically:YES];
            
            NSLog(@"POI index=%d, loaded/saved", info.index);
        }
    }
    
    if(self.poiInfo.icon_color && [[self.poiInfo.icon_color lowercaseString] isEqualToString:@"b"]) { // blue
        self.numBackgroundView.backgroundColor = [UIColor blueColor];
    }else if(self.poiInfo.icon_color && [[self.poiInfo.icon_color lowercaseString] isEqualToString:@"g"]) { // blue
        self.numBackgroundView.backgroundColor = [UIColor greenColor];
    }else { // red
        self.numBackgroundView.backgroundColor = [UIColor redColor];
    }
}

-(void)handleTap:(id)sender
{
    NSLog(@"handleTap");
    self.backgroundColor = [UIColor whiteColor];
    if(self.delegate) {
        [self.delegate thumbnailViewSelected:self.poiInfo.index];
    }
}

-(int)getThumbnailIndex
{
    return self.poiInfo.index;
}

-(void)setCurrentPhotoSelected:(BOOL)selected;
{
    //NSLog(@"setCurrentPhotoSelected %@", selected?@"true":@"false");
    self.backgroundColor = selected?[UIColor whiteColor]:[UIColor lightGrayColor];
}


@end
