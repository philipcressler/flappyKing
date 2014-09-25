//
//  GameViewController.swift
//  FlappyKing
//
//  Created by Philip Cressler on 9/23/14.
//  Copyright (c) 2014 Philip Cressler. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView.showsFPS = true
        skView.showsNodeCount = true
        //skView.showsPhysics = true
        
        if skView.scene == nil {
            let scene = GameScene(size: skView.bounds.size)
            skView.presentScene(scene)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
        } else {
            return Int(UIInterfaceOrientationMask.All.toRaw())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
