// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import <UIKit/UIKit.h>

@interface LoadingView : UIView
{

}

+ (id)loadingViewInView:(UIView *)aSuperview  withText:(NSString*)text;
- (void)removeView;

@end


/*

INSERT INTO StoryMap1 ("INDEX", NAME, DESCRIPTION, LAT, LON, URL, URL_LOCAL, THUMBNAIL_URL, THUMBNAIL_URL_LOCAL, ICON_COLOR) VALUES (13, 'Ronald Reagan (1981)', '<font color="darkgray"><b>ATTEMPTED ASSASSINATION</b> -- On March 30, 1981, as he returned to his limousine after a speech at the Hilton Washington Hotel in the capital, Reagan and three other men were shot and wounded by John Hinckley, Jr.. Reagan was struck by a single bullet which broke a rib, punctured a lung, and caused serious internal bleeding. He was rushed to nearby George Washington University Hospital for emergency surgery and was then hospitalized for about two weeks. Upon release, he resumed a light workload for several months as he recovered. He was the first sitting president to survive being shot in an attempted assassination.<br><br>Hinckley was immediately subdued and arrested at the scene. Later, he claimed to have wanted to kill the president to impress the teen actress Jodie Foster. He was deemed mentally ill and was confined to an institution. Besides Reagan, White House Press Secretary James Brady, Secret Service agent Tim McCarthy, and D.C. police officer Thomas Delahanty were also wounded in the attack. All three survived, but Brady suffered brain damage and was permanently disabled. <a href="http://en.wikipedia.org/wiki/Reagan_assassination_attempt" target="_blank">More Info</a></font>', 38.916411, -77.045837, 'http://upload.wikimedia.org/wikipedia/commons/7/70/Reagan_assassination_attempt_3.jpg', 'uploadwikimediaorgwikipediacommons770Reagan_assassination_attempt_3jpg.jpg', 'http://upload.wikimedia.org/wikipedia/commons/thumb/1/16/Official_Portrait_of_President_Reagan_1981.jpg/220px-Official_Portrait_of_President_Reagan_1981.jpg', 'uploadwikimediaorgwikipediacommonsthumb116Official_Portrait_of_President_Reagan_1981jpg220px-Official_Portrait_of_President_Reagan_1981jpg.jpg', 'b')

*/