//
//  Shape.swift
//  Square3
//
//  Created by Harry Shamansky on 4/14/15.
//

import UIKit

class Shape: NSObject {
   
    // Two representations of the 2D shape. Both are arrays of cartesian points.
    // if exactRepresentation is nil, the exact shape has not yet been determined, or
    // cannot be determined.
    var sketchyRepresentation: [CGPoint] = []
    var exactRepresentation: [CGPoint]?
    
    // A boolean to determine whether the user wants to view her original sketch
    // or an exact representation of it
    var showExactRepresentation: Bool = false
    
    // the shape's color, since this is super easy to add.
    var color: UIColor = UIColor.grayColor()
    
    // an enumeration to determine the shape's type, if known
    var knownType: ShapeType = .Unknown
    
    // The path of extrusion. For now, this should be a single-element array or nil
    // if the shape has not yet been extruded. I made it an array, though, to allow
    // for non-linear extrusion in the future.
    var extrusionPath: [CGPoint]?
    
}

// an enumeration of common shapes based on the algorithm found here
// http://web.ist.utl.pt/mjf/publications/2004-1999/pdf/grec99.pdf
enum ShapeType: Int {
    case Unknown
    case Square
    case Rectangle
    case Circle
    case Ellipse
    case Triangle
    case Diamond
}