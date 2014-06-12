//
//  ThumbnailViewController.m
//  StoryMap1
//
//  Created by Frank on 8/27/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "ThumbnailViewController.h"
#import "StoryMapUtil.h"

@interface ThumbnailViewController ()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *numberLabel;
@property (nonatomic, strong) IBOutlet UIView *numBackgroundView;

@property (nonatomic, strong) POIInfo *poiInfo;
@property (nonatomic, strong) NSString *storyMapFolderName;
@property (nonatomic, strong) NSString *photoFolderName;

-(void)handleTap:(id)sender;

@end

@implementation ThumbnailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UITapGestureRecognizer *oneTouch=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [oneTouch setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:oneTouch];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)updateWithPOIInfo: (POIInfo*)info storyMapFolder:(NSString*)name andPhotoFolder:(NSString*)folderName
{
    self.poiInfo = info;
    self.photoFolderName = folderName;
    self.storyMapFolderName = name;
    
    [self updateUI];
}

-(int)getThumbnailIndex
{
    return self.poiInfo.index;
}

-(void)setCurrentPhotoSelected:(BOOL)selected;
{
    self.isPhotoSelected = selected;
    self.view.backgroundColor = selected?[UIColor whiteColor]:[UIColor lightGrayColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self updateUI];
}

- (void)updateUI {
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
    self.view.backgroundColor = [UIColor whiteColor];
    if(self.delegate) {
        [self.delegate thumbnailViewSelected:self.poiInfo.index];
    }
}


@end
