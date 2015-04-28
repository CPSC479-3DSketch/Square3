//
//  CV.m
//  Square3
//
//  Created by Nicholas Gonzalez on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import "CV.h"
#import "Shape.h"
#include <vector>
#import <opencv2/opencv.hpp>

@implementation CV

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


+ (NSMutableArray *)convertUIImageToShapes: (UIImage *)image {
    NSMutableArray *shapes = [[NSMutableArray alloc] init];
    [CV findShapesInContours:[CV getContoursFromCVMatrix:[CV cvMatFromUIImage:image]]];
    return shapes;
}

+ (void) generateExactRepresentation: (Shape *) shape {
    [CV findShapeInContour: [CV convertShapeToUglyVector: shape]: shape];
}



+ (std::vector<std::vector<cv::Point>>)getContoursFromCVMatrix: (cv::Mat) mat {
    // Convert to grayscale
    cv::Mat grayscaleMat;
    cv::cvtColor(mat, grayscaleMat, CV_BGR2GRAY);
    
    // Convert to binary image using Canny
    cv::Mat binaryMat;
    cv::Canny(grayscaleMat, binaryMat, 0, 50, 5);
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(binaryMat.clone(), contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);
    return contours;
}

+ (std::vector<cv::Point>) convertShapeToUglyVector: (Shape *) shape{
    std::vector<cv::Point> contours;
    
    for(int i = 0; i < shape.sketchyRepresentation.count; i++) {
        CGPoint point = [shape.sketchyRepresentation[i] CGPointValue];
        
        cv::Point *temp = new cv::Point();
        temp->x = point.x;
        temp->y = point.y;
        
        contours.push_back(*temp);
    }

    
    return contours;
}


+ (void)findShapeInContour: (std::vector<cv::Point>) contour: (Shape *) shape {
    NSLog(@"-----> Contour has %ld points", contour.size());
    std::vector<cv::Point> polygonApproximation;
    cv::approxPolyDP(cv::Mat(contour), polygonApproximation, cv::arcLength(cv::Mat(contour), true) * 0.02, true);
    if (std::fabs(cv::contourArea(contour)) < 100)
        return;
    NSLog(@"-----> Polygon has %ld corners", polygonApproximation.size());
    for(int j = 0; j < polygonApproximation.size(); j++) {
        NSLog(@"       (%d, %d)", polygonApproximation[j].x, polygonApproximation[j].y);
        CGPoint point;
        point.x = polygonApproximation[j].x;
        point.y = polygonApproximation[j].y;
        [shape.exactRepresentation addObject:[NSValue valueWithCGPoint:point]];
//        [shape setShapeName: polygonApproximation.size() > 12 ? 365 : polygonApproximation.size()];
    }
}

+ (void)findShapesInContours: (std::vector<std::vector<cv::Point>>) contours {
    NSLog(@"%ld", contours.size());
    std::vector<cv::Point> polygonApproximation;
    for(int i = 0; i < contours.size(); i++) {
        cv::approxPolyDP(cv::Mat(contours[i]), polygonApproximation, cv::arcLength(cv::Mat(contours[i]), true) * 0.02, true);
        if (std::fabs(cv::contourArea(contours[i])) < 100)
            continue;
        NSLog(@"%ld", polygonApproximation.size());
        for(int j = 0; j < polygonApproximation.size(); j++) {
            NSLog(@"(%d, %d)", polygonApproximation[j].x, polygonApproximation[j].y);
        }
    }
}



@end
