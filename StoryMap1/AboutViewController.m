//
//  AboutViewController.m
//  StoryMap1
//
//  Created by Frank on 9/13/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@property (nonatomic, strong) IBOutlet UIWebView *aboutView;

@end

@implementation AboutViewController

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
    
    NSString *about = @"<html></body> <H2>Story Map Offline</H2> <p> This is an iOS native app for viewing and caching story maps that you created using one of the most popular story map templates.</p> <p>There are 3 popup windows/views: (1) an about window showing this document (tap 'A story map' on the upper right corner to show the window); (2) a story map list view (tap the Esri icon on the upper right corner to show the view); and (3) a base map TOC view (if there is more than one base map, a button will be displayed on the upper right corner of map view).</p> <p> The story map list view contains a story map url field and a table/list of cached story maps. <p/> <p>To add a new story map, you can either cut/paste a story map's url from your web browser to the story map url field, or you can directly type a story map url in the story map url field, and then tap the GO button, or you can simply type in the webmap id in the story map url field. The app will start caching contents as soon as it finds the intelligent webmap behind your story map. The app will get all story map pictures to the local storage but you may want to go through each individual picture at least once to make sure each one of them is indeed downloaded. The base map tiles you have viewed will be automatically cached too.<p/> <p>Swipe left/right on the current picture to go to previous/next photo. </p><p>To view a previously cached story map, tap on a table cell and then click on the GO button, the selected story map will be loaded immediately. </p> <p>You can delete a story map in the story map table by swiping to right on the cell, all the cached contents will be removed from your iPad. </p> <p> When your iPad is offline, the <font color=\"FF0000\">A story map</font> label will turn red. </p> </br>Please direct any technical questions to Frank Xia (fxia@esri.com).</body></html>";
    
    [self.aboutView loadHTMLString:about baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
