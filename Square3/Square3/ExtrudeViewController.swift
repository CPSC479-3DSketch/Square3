//
//  ExtrudeViewController.swift
//  Square3
//
//  Created on 4/6/15.
//

import UIKit
import SceneKit

class ExtrudeViewController: UIViewController {

    @IBOutlet weak var sceneView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.sceneSetup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: Scene
    // Based on http://www.raywenderlich.com/83748/beginning-scene-kit-tutorial
    func sceneSetup() {
        // 1
        let scene = SCNScene()
        
        // 2
        let boxGeometry = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: boxGeometry)
        scene.rootNode.addChildNode(boxNode)
        
        // 3
        sceneView.scene = scene
        
        // 4
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 50)
        scene.rootNode.addChildNode(cameraNode)
    }

}

