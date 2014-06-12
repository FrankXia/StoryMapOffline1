//
//  StoryMapViewController.h
//  StoryMap1
//
//  Created by Frank on 8/26/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import "StoryMapManagerViewController.h"
#import "ThumbnailView.h"

@interface StoryMapViewController : UIViewController <AGSMapViewTouchDelegate, AGSWebMapDelegate,StoryMapManagerViewControllerDelegate,ThumbnailViewDelegate, AGSLayerDelegate, UIWebViewDelegate,AGSMapViewCalloutDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;

@property (nonatomic, strong) IBOutlet UIView *imageTileDescView;
@property (nonatomic, strong) IBOutlet UILabel *imageTitle;
@property (nonatomic, strong) IBOutlet UILabel *imageDescription;
@property (nonatomic, strong) IBOutlet UIWebView *imageDescView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIButton *upButton;
@property (nonatomic, strong) IBOutlet UIButton *downButton;

@property (nonatomic, strong) IBOutlet UILabel *storyMapTitle;
@property (nonatomic, strong) IBOutlet UILabel *storyMapDescription;

@property (nonatomic, strong) IBOutlet UILabel *aStoryMapLabel;

@property (nonatomic, strong) IBOutlet UIButton *configButton;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) IBOutlet UIView *statusView;
@property (nonatomic, strong) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) IBOutlet UIButton *tocButton;

- (IBAction)swipeLeftRecognizer:(id)sender;
- (IBAction)swipeRightRecognizer:(id)sender;
- (IBAction)presentConfigView:(id)sender;
- (IBAction)updownButtonClicked:(id)sender;
- (IBAction)tocButtonClicked:(id)sender;


@end
