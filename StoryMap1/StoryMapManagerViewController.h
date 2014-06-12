//
//  ConfigViewController.h
//  StoryMap1
//
//  Created by Frank on 8/26/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadMapStoryPage.h"
#import "StoryMapInfo.h"

@protocol StoryMapManagerViewControllerDelegate;

@interface StoryMapManagerViewController : UIViewController <LoadMapStoryPageResponseDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, weak) id <StoryMapManagerViewControllerDelegate> delegate;

@property (nonatomic, strong) IBOutlet UITextField* storyMapUrlField;
@property (nonatomic, strong) IBOutlet UIButton *goButton;
@property (nonatomic, strong) IBOutlet UITableView *storyMapView;
@property (nonatomic, strong) IBOutlet UILabel *storyMapTitle;

@property (nonatomic, weak) StoryMapInfo *currentSelectedStoryMap;

- (IBAction)goButtonClicked:(id)sender;
- (void)reachabilityChanged:(NSNotification*)note;

@end

@protocol StoryMapManagerViewControllerDelegate <NSObject>
- (void) loadStoryMapWithWebmap:(NSString*)webmapId andUrl:(NSString*)url;
- (void) loadStoryMapWithStoryMapInfo:(StoryMapInfo*)storyMapInfo;
- (void) removeStoryMap:(StoryMapInfo*)StoryMapInfo;
@end
