//
//  CV.m
//  Square3
//
//  Created by Nicholas Gonzalez on 4/27/15.
//  Copyright (c) 2015 CPSC479. All rights reserved.
//

#import "CV.h"
#import "Shape.h"
#include <stack>
#include <vector>
#include <stdio.h>
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
//    [CV findShapeInContour: [CV convertShapeToUglyVector: shape]: shape];
    [CV segmentedLeastSquares:shape];
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
    shape.exactRepresentation = [[NSMutableArray alloc] init];
    for(int j = 0; j < polygonApproximation.size(); j++) {
        NSLog(@"       (%d, %d)", polygonApproximation[j].x, polygonApproximation[j].y);
        CGPoint point;
        point.x = polygonApproximation[j].x;
        point.y = polygonApproximation[j].y;
        [shape.exactRepresentation addObject:[NSValue valueWithCGPoint:point]];
//        [shape setShapeName: polygonApproximation.size() > 12 ? 365 : polygonApproximation.size()];
    }
    
    int threshold = (int) contour.size()*.15 <= 2 ? 3 : (int) contour.size()*.15;
    
    NSLog(@"-----> Threshold = %d.", threshold);
    if(polygonApproximation.size() > 0) {
        int polygonIndex = 0;
        int lastCornerMatch = -1;
        for(int i = 0; i < contour.size(); i++) {
            if(polygonApproximation[polygonIndex].x == contour[i].x &&
               polygonApproximation[polygonIndex].y == contour[i].y) {
                if(lastCornerMatch == -1 && i > threshold) {
                    CGPoint start;
                    start.x = contour[i/2].x;
                    start.y = contour[i/2].y;
                    [shape.exactRepresentation insertObject:[NSValue valueWithCGPoint:start] atIndex:polygonIndex++];
                    NSLog(@"-----> Here, added start to representation.");
                }
                
                if(i - lastCornerMatch > threshold) {
                    CGPoint newCorner;
                    newCorner.x = contour[i/2].x;
                    newCorner.y = contour[i/2].y;
                    [shape.exactRepresentation insertObject:[NSValue valueWithCGPoint:newCorner] atIndex:polygonIndex];
                    NSLog(@"-----> Here, added new corner at index %d.", polygonIndex);
                    polygonIndex++;
                }
                
                lastCornerMatch = i;
                polygonIndex++;
            }
        }
        
        if(contour.size() - lastCornerMatch > threshold) {
            CGPoint end;
            end.x = contour[contour.size()-1].x;
            end.y = contour[contour.size()-1].y;
            
            [shape.exactRepresentation addObject:[NSValue valueWithCGPoint:end]];
            NSLog(@"-----> Here, added end to representation.");
        }
        
//        NSLog(@"-----> Polygon has %ld corners", (unsigned long)shape.exactRepresentation.count);
//        for(int i = 0; i < shape.exactRepresentation.count; i++) {
//            NSLog(@"      %@", shape.exactRepresentation[i]);
//        }
//
//        
//        for(int i =0; i < shape.exactRepresentation.count; i++) {
//            CGPoint p1 = [shape.exactRepresentation[i] CGPointValue];
//            for(int j = i + 1; j < shape.exactRepresentation.count; j++) {
//                CGPoint p2 = [shape.exactRepresentation[j] CGPointValue];
//                if(p1.x == p2.x && p1.y == p2.y) {
//                    NSLog(@"      %@", shape.exactRepresentation[i]);
//
//                    [shape.exactRepresentation removeObjectAtIndex:j];
//                }
//            }
//        }
        
        NSLog(@"-----> Polygon has %ld corners", (unsigned long)shape.exactRepresentation.count);
        for(int i = 0; i < shape.exactRepresentation.count; i++) {
            NSLog(@"      %@", shape.exactRepresentation[i]);
        }

        
        shape.sketchyRepresentation = shape.exactRepresentation;
        
    }
}


+ (void) segmentedLeastSquares: (Shape *) shape {
    // sort the point with x1 < x2 < ... < xn
    [shape.sketchyRepresentation sortedArrayUsingComparator:^NSComparisonResult(NSValue *obj1, NSValue *obj2) {
        CGPoint p1 = [obj1 CGPointValue];
        CGPoint p2 = [obj2 CGPointValue];
        if (p1.x == p2.x) {
            if(p1.y < p2.y) {
                return NSOrderedAscending;
            } else {
                return NSOrderedDescending;
            }
        } else if (p1.x < p2.x) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    
    // create arrays that hold least square calculations
    shape.exactRepresentation = [[NSMutableArray alloc] init];
    
    // CODE FROM https://github.com/kartikkukreja/blog-codes/blob/master/src/Segmented%20Least%20Squares%20Problem.cpp
    // WAS EDITED AND REFACTORED TO USED IN THIS PROJECT

    int numPoints = shape.sketchyRepresentation.count;
    NSLog(@"Size of sketchy: %d, numPoints = %d", shape.sketchyRepresentation.count, numPoints);
    NSMutableArray *points = [[NSMutableArray alloc] init];
    
    [points addObject: [NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)]];
    [points addObjectsFromArray:shape.sketchyRepresentation];
    
     NSLog(@"Size of points: %d, numPoints = %d", points.count, numPoints);
    
    
    long long cumulative_x[numPoints], cumulative_y[numPoints], cumulative_xy[numPoints], cumulative_xSqr[numPoints];
    
    double slope[numPoints][numPoints], intercept[numPoints][numPoints], E[numPoints][numPoints];
    memset( slope, 0, (numPoints)*(numPoints)*sizeof(double));
    memset( intercept, 0, (numPoints)*(numPoints)*sizeof(double));
    memset( E, 0, (numPoints)*(numPoints)*sizeof(double));
    
    
    // OPT[i] is the optimal solution (minimum cost) for the points {points[1], points[2], ..., points[i]}
    double OPT[numPoints + 1];
    
    // [opt_segment[i], i] is the last segment in the optimal solution
    // for the points {points[1], points[2], ..., points[i]}
    int opt_segment[numPoints + 1];
    
    long long x_sum, y_sum, xy_sum, xsqr_sum, num, denom;
    
    // precompute the error terms
    cumulative_x[0] = cumulative_y[0] = cumulative_xy[0] = cumulative_xSqr[0] = 0;
    for (int j = 1; j <= numPoints; j++)	{
        CGPoint currentPoint = [points[j] CGPointValue];
        cumulative_x[j] = cumulative_x[j-1] + currentPoint.x;
        cumulative_y[j] = cumulative_y[j-1] + currentPoint.y;
        cumulative_xy[j] = cumulative_xy[j-1] + currentPoint.x * currentPoint.y;
        cumulative_xSqr[j] = cumulative_xSqr[j-1] + currentPoint.x * currentPoint.x;
        
        for (int i = 1; i <= j; i++)	{
            int interval = j - i + 1;
            x_sum = cumulative_x[j] - cumulative_x[i-1];
            y_sum = cumulative_y[j] - cumulative_y[i-1];
            xy_sum = cumulative_xy[j] - cumulative_xy[i-1];
            xsqr_sum = cumulative_xSqr[j] - cumulative_xSqr[i-1];
            
            num = interval * xy_sum - x_sum * y_sum;
            if (num == 0)
                slope[i][j] = 0.0;
            else {
                denom = interval * xsqr_sum - x_sum * x_sum;
                slope[i][j] = (denom == 0) ? std::numeric_limits<double>::infinity() : (num / double(denom));
            }
            intercept[i][j] = (y_sum - slope[i][j] * x_sum) / double(interval);
            
            E[i][j] = 0.0;
            for (int k = i; k <= j; k++)	{
                CGPoint point = [points[k] CGPointValue];
                double tmp = point.y - slope[i][j] * point.x - intercept[i][j];
                E[i][j] += tmp * tmp;
            }
        }
    }
    
    OPT[0] = opt_segment[0] = 0;
    double mx, cost = 850;
    int i, j, k;
    for (j = 1; j <= numPoints; j++)	{
        for (i = 1, mx = std::numeric_limits<double>::infinity(), k = 0; i <= j; i++)	{
            double tmp = E[i][j] + OPT[i-1];
            if (tmp < mx)	{
                mx = tmp;
                k = i;
            }
        }
        OPT[j] = mx + cost;
        opt_segment[j] = k;
    }
    
    std::stack <int> segments;
    for (i = numPoints, j = opt_segment[numPoints]; i > 0; i = j-1, j = opt_segment[i])	{
        segments.push(i);
        segments.push(j);
    }
    
    shape.exactRepresentation = [[NSMutableArray alloc] init];
    NSLog(@"Composed of %lu Segments", segments.size()/2);
    while (!segments.empty())	{
        i = segments.top(); segments.pop();
        j = segments.top(); segments.pop();
        NSLog(@"Segment (y = %lf * x + %lf) from points %d to %d with square error %lf.\n",
               slope[i][j], intercept[i][j], i, j, E[i][j]);
        
        
        [shape.exactRepresentation addObject: points[i]];
        [shape.exactRepresentation addObject: points[j]];
    }
//    shape.sketchyRepresentation = shape.exactRepresentation;
    NSLog(@"\n");

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
