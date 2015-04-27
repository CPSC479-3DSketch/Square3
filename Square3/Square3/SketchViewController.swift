//
//  SketchViewController.swift
//  Square3
//
//  Created on 4/6/15.
//

import UIKit

class SketchViewController: UIViewController {

    var drawingColor: UIColor = UIColor.blackColor()
    
    var shapes: [Shape] = []
    var shapeInProgress: Shape?
    
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var colorSlider: UISlider!
    @IBOutlet weak var colorSwatch: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // make the slider blank
        colorSlider.setMaximumTrackImage(UIImage(), forState: .Normal)
        colorSlider.setMinimumTrackImage(UIImage(), forState: .Normal)
        colorSlider.setThumbImage(UIImage(named: "slider-handle"), forState: .Normal)
        
        // make the color swatch a circle
        colorSwatch.layer.cornerRadius = colorSwatch.frame.width / 2
        
        // preset the color based on the slider
        drawingColor = UIColor(hue: CGFloat(colorSlider.value)/359.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        colorSwatch.backgroundColor = drawingColor
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        shapeInProgress = Shape()
        shapeInProgress?.color = drawingColor
        
        if let touch = touches.first as? UITouch {
            let currentPoint = touch.locationInView(view)
            shapeInProgress?.sketchyRepresentation.append(currentPoint)
        }
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if let touch = touches.first as? UITouch {
            
            // Draw the strokes on the tempImageView
            UIGraphicsBeginImageContext(view.frame.size)
            let context = UIGraphicsGetCurrentContext()
            tempImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
            
            if let lastPoint = shapeInProgress?.sketchyRepresentation.last {
                CGContextMoveToPoint(context, lastPoint.x, lastPoint.y)
                CGContextAddLineToPoint(context, touch.locationInView(view).x, touch.locationInView(view).y)
                CGContextSetLineCap(context, kCGLineCapRound)
                CGContextSetLineWidth(context, 2)

                CGContextSetStrokeColorWithColor(context, drawingColor.CGColor)
                CGContextSetBlendMode(context, kCGBlendModeNormal)
                CGContextStrokePath(context)

                // draw the stroke on the temporary context
                tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
                
                UIGraphicsEndImageContext()
            }
            
            // append the progress
            let currentPoint = touch.locationInView(view)
            shapeInProgress?.sketchyRepresentation.append(currentPoint)
        }
        
        
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if let touch = touches.first as? UITouch {
            let currentPoint = touch.locationInView(view)
            shapeInProgress?.sketchyRepresentation.append(currentPoint)
        }
        
        
        // Merge tempImageView into mainImageView
        // Modified from http://www.raywenderlich.com/87899/make-simple-drawing-app-uikit-swift
        UIGraphicsBeginImageContext(imageView.frame.size)
        imageView.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height), blendMode: kCGBlendModeNormal, alpha: 1.0)
        tempImageView.image?.drawInRect(CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height), blendMode: kCGBlendModeNormal, alpha: 1.0)
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        tempImageView.image = nil
        
        
        if let shapeToAdd = shapeInProgress {
            shapes.append(shapeToAdd)
        }
        shapeInProgress = nil
    }
    
    @IBAction func clear(sender: UIButton) {
        shapes = []
        shapeInProgress = nil
        tempImageView.image = nil
        imageView.image = nil
    }

    @IBAction func colorChanged(sender: UISlider) {
        drawingColor = UIColor(hue: CGFloat(sender.value)/359.0, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        colorSwatch.backgroundColor = drawingColor
    }
    

}

