//
//  DriveTime.m
//  FEMADemo
//
//  Created by Frank on 3/18/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "LoadMapStoryPage.h"

@implementation LoadMapStoryPage

@synthesize delegate;
@synthesize responses;

- (void) startWithRequest:(NSMutableURLRequest *) request
{
	NSLog(@"request is:%@",request);
	if (request)
	{
		[request setTimeoutInterval:30.0];
		NSURLConnection *mConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		[mConnection start];
	}
    responses = [[NSMutableArray alloc] initWithCapacity:5];
}

#pragma mark -
#pragma mark NSURLConnection Delegates

- (void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response
{
    NSLog(@"didReceiveResponse is:%@",response);
}

- (void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data
{
    NSString *myResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"===================================================================================");
//    NSLog(@"didReceiveData myResposne is:%@",myResponse);
    [responses addObject:myResponse];
    
    if ([myResponse rangeOfString:@"</html>"].location != NSNotFound) {
        NSString *finalResponse = @"";
        for (int i=0; i<[self.responses count]; i++) {
            finalResponse = [NSString stringWithFormat:@"%@%@", finalResponse, [responses objectAtIndex:i]];
        }
        finalResponse = [finalResponse lowercaseString];
        
        BOOL webmapIdIndex1 = [finalResponse rangeOfString:@"webmap :"].location != NSNotFound;
        BOOL webmapIdIndex2 = [finalResponse rangeOfString:@"webmap:"].location != NSNotFound;
        if (webmapIdIndex1 || webmapIdIndex2 ) {
            NSString *ss = nil;
            if (webmapIdIndex1) {
                ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap :"].location + 8];
            }else {
                ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap:"].location + 7];
            }
            
            int end =  [ss rangeOfString:@","].location;
            ss = [ss substringToIndex:end];
            ss = [ss stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            ss = [ss substringToIndex:ss.length-1];
            ss = [ss substringFromIndex:1];
            
            [self.delegate didReceiveResponseFromServer:ss];
        }else {
            // let's check keyword: webmapid or webap_id (like in case of Redlands Tour)
            webmapIdIndex1 = [finalResponse rangeOfString:@"webmapid="].location != NSNotFound;
            webmapIdIndex2 = [finalResponse rangeOfString:@"webmapid ="].location != NSNotFound;
            BOOL webmapIdIndex3 = [finalResponse rangeOfString:@"webmap_id="].location != NSNotFound;
            BOOL webmapIdIndex4 = [finalResponse rangeOfString:@"webmap_id ="].location != NSNotFound;
            
            if (webmapIdIndex1 || webmapIdIndex2 || webmapIdIndex3 || webmapIdIndex4 ) {
                NSString *ss = nil;
                if (webmapIdIndex1) {
                    ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmapid="].location + 9];
                }else if(webmapIdIndex2) {
                    ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmapid ="].location + 10];
                }else if (webmapIdIndex3) {
                    ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap_id="].location + 10];
                }else if(webmapIdIndex4) {
                    ss =  [finalResponse substringFromIndex: [finalResponse rangeOfString:@"webmap_id ="].location + 11];
                }
                
                int end =  [ss rangeOfString:@";"].location;
                ss = [ss substringToIndex:end];
                ss = [ss stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                ss = [ss substringToIndex:ss.length-1];
                ss = [ss substringFromIndex:1];
                
                [self.delegate didReceiveResponseFromServer:ss];
            }else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Couldn't find web map id from the story map." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection*) connection
{
    NSLog(@"connectionDidFinishLoading");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Got connection error" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alertView show];
}

@end
