//
//  MyLayerDelegate.m
//  TableOfContentsSample
//
//  Created by Frank on 3/12/13.
//
//

#import "MyLayerDelegate.h"

@implementation MyLayerDelegate


- (void) layerDidLoad:		(AGSLayer *) 	layer
{
    NSLog(@"Layer did load %@", layer);
}


- (void) layer:		(AGSLayer *) 	layer
didFailToLoadWithError:		(NSError *) 	error
{
    NSLog(@"Layer failed to load");
}
@end
