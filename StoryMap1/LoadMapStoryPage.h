//
//  DriveTime.h
//  FEMADemo
//
//  Created by Frank on 3/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LoadMapStoryPageResponseDelegate;

@interface LoadMapStoryPage : NSObject <NSURLConnectionDataDelegate>

@property (nonatomic, weak) id <LoadMapStoryPageResponseDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *responses;

- (void) startWithRequest:(NSMutableURLRequest *) request;

@end


@protocol LoadMapStoryPageResponseDelegate <NSObject>
- (void)didReceiveResponseFromServer:(NSString*)webmapId;
- (void)didReceiveErrorFromServer:(NSString*)errorResponse;
@end
