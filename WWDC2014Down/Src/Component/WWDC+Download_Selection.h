//
//  WWDC+Download_Selection.h
//  WWDCDown
//
//  Created by @iosxtools on Twitter on 14-6-10.
//  Copyright (c) 2014年 http://www.iosxtools.com. All rights reserved.
//

#import "WWDC.h"

@interface WWDC (Download_Selection)
@property (nonatomic, assign) BOOL isSelectedHD;
@property (nonatomic, assign) BOOL isSelectedSD;
@property (nonatomic, assign) BOOL isSelectedPDF;
- (BOOL)downSelected;
@end
