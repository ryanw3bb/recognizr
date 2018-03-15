//
//  SquareDetectorController.m
//  Recognizr
//
//  Created by Ryan on 11/03/2018.
//  Copyright © 2018 Ryan Webb. All rights reserved.
//

#import "MainViewController.h"

int const MAX_UNDETECTED_FRAMES = 5;
bool const DRAW_FRAME = false;
bool const DRAW_CORNERS = false;

@interface MainViewController()

@property (nonatomic) IBOutlet UIImageView *cvView;
@property (nonatomic) IBOutlet UIImageView *camView;
@property (nonatomic) IBOutlet UIImageView *rectView;
@property (nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) SquareDetector *squareDetector;
@property (nonatomic) int undetectedFrameCount;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage* img = [UIImage imageNamed:@"dog-marker.jpg"];
    self.squareDetector = [[SquareDetector alloc] initWithCameraView:_cvView scale:2.0 image:img];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.squareDetector startCapture];
    
    // layer video feed on top of cv view
    AVCaptureSession *session = self.squareDetector.videoCamera.captureSession;
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewLayer.frame = _camView.bounds;
    [_camView.layer addSublayer:previewLayer];
    
    float fps = 1.0f / 30.0f;
    [NSTimer scheduledTimerWithTimeInterval:fps target:self selector:@selector(update:) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.squareDetector stopCapture];
}

- (void)update:(NSTimer*)t
{
    [_rectView.layer setSublayers:nil];
    NSArray *points = [self.squareDetector.detectedSquares copy];
    
    if([points count] <= 0)
    {
        _undetectedFrameCount ++;
        
        if(_undetectedFrameCount > MAX_UNDETECTED_FRAMES || _imageView.image == nil)
        {
            _imageView.image = nil;
        }
        
        return;
    }
    
    _undetectedFrameCount = 0;
    
    // apply the warped image
    _imageView.image = [self.squareDetector finalImage];
    
    CGPoint p0 = CGPointMake([points[0] CGPointValue].x * _rectView.bounds.size.width, [points[0] CGPointValue].y * _rectView.bounds.size.height);
    CGPoint p1 = CGPointMake([points[1] CGPointValue].x * _rectView.bounds.size.width, [points[1] CGPointValue].y * _rectView.bounds.size.height);
    CGPoint p2 = CGPointMake([points[2] CGPointValue].x * _rectView.bounds.size.width, [points[2] CGPointValue].y * _rectView.bounds.size.height);
    CGPoint p3 = CGPointMake([points[3] CGPointValue].x * _rectView.bounds.size.width, [points[3] CGPointValue].y * _rectView.bounds.size.height);
    
    if(DRAW_FRAME)
    {
        // draw a green frame
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:p0];
        [path addLineToPoint:p1];
        [path addLineToPoint:p2];
        [path addLineToPoint:p3];
        [path addLineToPoint:p0];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = [path CGPath];
        shapeLayer.strokeColor = [[UIColor greenColor] CGColor];
        shapeLayer.lineWidth = 2.0;
        shapeLayer.fillColor = [[UIColor clearColor] CGColor];
        [_rectView.layer addSublayer:shapeLayer];
    }
    
    if(DRAW_CORNERS)
    {
        // draw coloured circles on corners
        [self drawCircle:[UIColor greenColor] point:p0];
        [self drawCircle:[UIColor blueColor] point:p1];
        [self drawCircle:[UIColor yellowColor] point:p2];
        [self drawCircle:[UIColor redColor] point:p3];
    }
}

-(void)drawCircle:(UIColor *)color point:(CGPoint)point
{
    int radius = 10;
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0 * radius, 2.0 * radius) cornerRadius:radius].CGPath;
    circle.position = CGPointMake(point.x - radius, point.y - radius);
    circle.fillColor = color.CGColor;
    
    [_rectView.layer addSublayer:circle];
}

@end
