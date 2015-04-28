//
//  SketchViewController.m
//  Square3
//
//  Created on 4/27/15.
//

#import "SketchViewController.h"
#import "Shape.h"
#import "CV.h"

@interface SketchViewController ()

@end

@implementation SketchViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Make the slider blank
    [self.colorSlider setMaximumTrackImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [self.colorSlider setMinimumTrackImage:[[UIImage alloc] init] forState:UIControlStateNormal];
    [self.colorSlider setThumbImage:[UIImage imageNamed:@"slider-handle"] forState:UIControlStateNormal];
    
    // Make the color swatch a circle
    [self.colorSwatch.layer setCornerRadius:(self.colorSwatch.frame.size.width / 2)];
    
    // Preset the color based on the slider
    self.drawingColor = [UIColor colorWithHue:(self.colorSlider.value / 359.0) saturation:1.0 brightness:1.0 alpha:1.0];
    [self.colorSwatch setBackgroundColor:self.drawingColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.shapeInProgress = [[Shape alloc] init];
    self.shapeInProgress.color = self.drawingColor;
    
    UITouch *touch = (UITouch *)[[touches allObjects] firstObject];
    CGPoint currentPoint = [touch locationInView:self.view];
    
    self.shapeInProgress.sketchyRepresentation = [[NSMutableArray alloc] init];
    [self.shapeInProgress.sketchyRepresentation addObject:[NSValue valueWithCGPoint:currentPoint]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = (UITouch *)[[touches allObjects] firstObject];
    
    // Draw the strokes on the tempImageView
    UIGraphicsBeginImageContext(self.view.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.tempImageView.image drawInRect:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    
    CGPoint lastPoint = [((NSValue *)self.shapeInProgress.sketchyRepresentation.lastObject) CGPointValue];
    CGContextMoveToPoint(context, lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(context, [touch locationInView:(self.view)].x, [touch locationInView:(self.view)].y);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, 2);
    
    CGContextSetStrokeColorWithColor(context, self.drawingColor.CGColor);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextStrokePath(context);
    
    // draw the stroke on the temporary context
    self.tempImageView.image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // append the progress
    CGPoint currentPoint = [touch locationInView:(self.view)];
    [self.shapeInProgress.sketchyRepresentation addObject:[NSValue valueWithCGPoint:currentPoint]];

}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = (UITouch *)[[touches allObjects] firstObject];
    CGPoint currentPoint = [touch locationInView:self.view];
    
    [self.shapeInProgress.sketchyRepresentation addObject:[NSValue valueWithCGPoint:currentPoint]];
    
    // Merge tempImageView into mainImageView
    // Modified from http://www.raywenderlich.com/87899/make-simple-drawing-app-uikit-swift
    UIGraphicsBeginImageContext(self.imageView.frame.size);
    [self.imageView.image drawInRect:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];
    [self.tempImageView.image drawInRect:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height) blendMode:kCGBlendModeNormal alpha:1.0];

    [self.imageView setImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    [self.tempImageView setImage:nil];

    Shape *shapeToAdd = self.shapeInProgress;
    if (shapeToAdd) { // ensure it's not nil
        [CV generateExactRepresentation:shapeToAdd];
        [[Data sharedData] addShape:shapeToAdd];
    }

    self.shapeInProgress = nil;
    
}

- (IBAction)clearCanvas:(id)sender {
    self.shapeInProgress = nil;
    [self.tempImageView setImage:nil];
    [self.imageView setImage:nil];
    
}

- (IBAction)colorChanged:(id)sender {
    UISlider *slider = sender;
    self.drawingColor = [UIColor colorWithHue:slider.value / 359.0 saturation:1.0 brightness:1.0 alpha:1.0];
    [self.colorSwatch setBackgroundColor:self.drawingColor];
}

@end
