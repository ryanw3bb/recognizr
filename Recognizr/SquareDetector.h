//
//  SquareDetector.h
//  Recognizr
//
//  Created by Ryan on 11/03/2018.
//  Copyright © 2018 Ryan Webb. All rights reserved.
//

#import <opencv2/highgui/cap_ios.h>
#import <Foundation/Foundation.h>
#import "CVImageTools.h"

@interface SquareDetector : NSObject <CvVideoCameraDelegate>

@property (nonatomic) CvVideoCamera* videoCamera;
@property (nonatomic) UIImage* finalImage;

- (instancetype)initWithCameraView:(UIImageView *)view scale:(CGFloat)scale image:(UIImage *)image;
- (void)startCapture;
- (void)stopCapture;
- (NSArray *)detectedSquares;

@end
