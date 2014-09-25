//
//  GameScene.swift
//  FlappyKing
//
//  Created by Philip Cressler on 9/23/14.
//  Copyright (c) 2014 Philip Cressler. All rights reserved.
//


import SpriteKit

// king
var king:SKSpriteNode = SKSpriteNode()

// Score
var score:Int = 0
var label_score:SKLabelNode = SKLabelNode()

//ScoreBoard
var scoreboard:SKSpriteNode = SKSpriteNode()

// Best Score
var bestScore:Int = 0
var label_bestScore:SKLabelNode = SKLabelNode()
var label_scoreboard:SKLabelNode = SKLabelNode()

// Instructions
var instructions:SKSpriteNode = SKSpriteNode()

// Background
let background:SKNode = SKNode()
let background_speed:Float = 100

// Pipe Origin
let pipe_origin_x:CGFloat = 382.0

// Time Values
var delta:NSTimeInterval = NSTimeInterval(0)
var last_update_time:NSTimeInterval = NSTimeInterval(0)

// Floor height
let floor_distance:CGFloat = 72.0

// Physics Categories
let FSBoundaryCategory:UInt32 = 1 << 0
let FSPlayerCategory:UInt32   = 1 << 1
let FSPipeCategory:UInt32     = 1 << 2
let FSGapCategory:UInt32      = 1 << 3

// Game states
enum FSGameState: Int {
    case FSGameStateStarting
    case FSGameStatePlaying
    case FSGameStateEnded
}
var state:FSGameState = .FSGameStateStarting

// Sounds
let scoreSound = SKAction.playSoundFileNamed("score.mp3", waitForCompletion: false)
let thumpSound = SKAction.playSoundFileNamed("thump.mp3", waitForCompletion: false)
let whirpSound = SKAction.playSoundFileNamed("whirp.mp3", waitForCompletion: false)

// #pragma mark - Math functions
extension Float {
    static func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if(value > max) {
            return max
        } else if(value < min) {
            return min
        } else {
            return value
        }
    }
    
    static func range(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF) * (max - min) + min
    }
}

extension CGFloat{
    func degrees_to_radians() ->CGFloat{
        return CGFloat(M_PI) * self / 180
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // #pragma mark - SKScene Initializacion
    override init(size: CGSize) {
        super.init(size: size)
        
        //get best score
        var highscore = NSUserDefaults.standardUserDefaults().integerForKey("highScore")

        self.initWorld()
        self.initBackground()
        self.initking()
        self.initHUD()
    }
    
    // #pragma mark - Init Physics
    func initWorld() {
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0, -5)
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRectMake(0, floor_distance, self.size.width, self.size.height - floor_distance))
        self.physicsBody?.categoryBitMask = FSBoundaryCategory
        self.physicsBody?.collisionBitMask = FSPlayerCategory
    }
    
    // #pragma mark - Init King
    func initking() {
        king = SKSpriteNode(imageNamed: "king1")
        king.position = CGPointMake(100, CGRectGetMidY(self.frame))
        king.physicsBody = SKPhysicsBody(circleOfRadius: king.size.width / 2.5)
        king.physicsBody?.categoryBitMask = FSPlayerCategory
        king.physicsBody?.contactTestBitMask = FSPipeCategory | FSGapCategory | FSBoundaryCategory
        king.physicsBody?.collisionBitMask = FSPipeCategory | FSBoundaryCategory
        king.physicsBody?.restitution = 0.0
        king.physicsBody?.allowsRotation = false
        // 1
        king.physicsBody?.affectedByGravity = false
        king.zPosition = 50
        self.addChild(king)
        
        let textureFloat: SKTexture = SKTexture(imageNamed: "king1")
        let textureUp: SKTexture = SKTexture(imageNamed: "king2")
        let textureDown: SKTexture = SKTexture(imageNamed: "king3")
        let float = SKAction.setTexture(textureFloat)
        let up = SKAction.setTexture(textureUp)
        let down = SKAction.setTexture(textureDown)
       
       // king.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(textures, timePerFrame: 0.1)))
    }
    
    // #pragma mark - Background Functions
    func initBackground() {
        
        self.addChild(background)
        var i = 0;
        for(i = 0; i < 2; i++){
            let tile = SKSpriteNode(imageNamed: "new_bg1")
            tile.anchorPoint = CGPointZero
            tile.position = CGPointMake(CGFloat(i) * 640.0, 0)
            tile.name = "new_bg1"
            tile.zPosition = 10
            background.addChild(tile)
        }
        
    }
    
    func moveBackground() {
        let posX : Float = -background_speed * Float(delta)
        background.position = CGPointMake(background.position.x + CGFloat(posX), 0)
    
        background.enumerateChildNodesWithName("new_bg1") { (node, stop) in
            let background_screen_position: CGPoint = background.convertPoint(node.position, toNode: self)
            
            if background_screen_position.x <= -node.frame.size.width {
                node.position = CGPointMake(node.position.x + (node.frame.size.width * 2), node.position.y)
            }
            
        }
    }
    
    // #pragma mark - Pipes Functions
    func initPipes() {
        
        let bottom:SKSpriteNode = self.getPipeWithSize(CGSizeMake(62, Float.range(40, max: 360)), side: false)
        bottom.position = self.convertPoint(CGPointMake(pipe_origin_x, CGRectGetMinY(self.frame) + bottom.size.height/2 + floor_distance), toNode: background)
        bottom.physicsBody = SKPhysicsBody(rectangleOfSize: bottom.size)
        bottom.physicsBody?.categoryBitMask = FSPipeCategory;
        bottom.physicsBody?.contactTestBitMask = FSPlayerCategory;
        bottom.physicsBody?.collisionBitMask = FSPlayerCategory;
        bottom.physicsBody?.dynamic = false
        bottom.zPosition = 20
        background.addChild(bottom)
        
    
        let threshold:SKSpriteNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSizeMake(10, 100))
        threshold.position = self.convertPoint(CGPointMake(pipe_origin_x, floor_distance + bottom.size.height + threshold.size.height/2), toNode: background)
        threshold.physicsBody = SKPhysicsBody(rectangleOfSize: threshold.size)
        threshold.physicsBody?.categoryBitMask = FSGapCategory
        threshold.physicsBody?.contactTestBitMask = FSPlayerCategory
        threshold.physicsBody?.collisionBitMask = 0
        threshold.physicsBody?.dynamic = false
        threshold.zPosition = 20
        background.addChild(threshold)
        
        let topSize:CGFloat = self.size.height - bottom.size.height - threshold.size.height - floor_distance
        
        let top:SKSpriteNode = self.getPipeWithSize(CGSizeMake(62, topSize), side: true)
        top.position = self.convertPoint(CGPointMake(pipe_origin_x, CGRectGetMaxY(self.frame) - top.size.height/2), toNode: background)
        top.physicsBody = SKPhysicsBody(rectangleOfSize: top.size)
        top.physicsBody?.categoryBitMask = FSPipeCategory;
        top.physicsBody?.contactTestBitMask = FSPlayerCategory;
        top.physicsBody?.collisionBitMask = FSPlayerCategory;
        top.physicsBody?.dynamic = false
        top.zPosition = 20
        background.addChild(top)
  
    }
    
    func getPipeWithSize(size: CGSize, side: Bool) -> SKSpriteNode {

        let textureSize: CGRect = CGRectMake(0,0,size.width,size.height)
        let backgroundCGImage: CGImageRef = UIImage(named:"pipe2").CGImage
    
        
        UIGraphicsBeginImageContext(size)
        let context:CGContextRef = UIGraphicsGetCurrentContext()        
        CGContextDrawTiledImage(context, textureSize, backgroundCGImage)
        let tiledBackground:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let backgroundTexture:SKTexture = SKTexture(CGImage: tiledBackground.CGImage)
        let pipe:SKSpriteNode = SKSpriteNode(texture: backgroundTexture)
        pipe.zPosition = 1
        
        let cap:SKSpriteNode = SKSpriteNode(imageNamed: "top_of_pipe")
        cap.position = CGPointMake(0, side ? -pipe.size.height/2 + cap.size.height/2 : pipe.size.height/2 - cap.size.height/2)
        cap.zPosition = 5
        pipe.addChild(cap)
        
            if side == true {
            let angle:CGFloat = 180.0
            cap.zRotation = angle.degrees_to_radians()
            }
            
            return pipe
    }
    
    // #pragma mark - Game Over helpers
    func gameOver() {
        
        state = .FSGameStateEnded
        
        //save highest score
        if(score > bestScore){
            bestScore = score
        }
        var defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(bestScore, forKey:"highScore")
        defaults.synchronize()
        
        king.physicsBody?.categoryBitMask = 0
        king.physicsBody?.collisionBitMask = FSBoundaryCategory
        bestScore = NSUserDefaults.standardUserDefaults().integerForKey("highScore")
        
        
        label_bestScore = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label_bestScore.text = "High Score:\(bestScore)"
        label_bestScore.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)-75)
        label_bestScore.fontColor = SKColor.whiteColor()
        label_bestScore.zPosition = 50
        
        label_scoreboard = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label_scoreboard.text = "Score:\(score)"
        label_scoreboard.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
        label_scoreboard.fontColor = SKColor.redColor()
        label_scoreboard.zPosition = 50
        
        self.addChild(label_scoreboard)
        self.addChild(label_bestScore)
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: Selector("restartGame"), userInfo: nil, repeats: false)
    }
    
    //func needs to be implemented
    func initScoreboard(){
      //scoreboard = SKSpriteNode(imageNamed: "panel_beige")
      //scoreboard.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
      //scoreboard.zPosition = 50
        label_scoreboard = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label_scoreboard.text = "\(score)"
        label_scoreboard.position = CGPointMake(scoreboard.position.x, scoreboard.position.y)
        label_scoreboard.fontColor = SKColor.redColor()
        label_scoreboard.zPosition = 50
        
        self.addChild(label_scoreboard)
        
        
       // self.addChild(scoreboard)
        
    }
    
    func restartGame() {
        
        state = .FSGameStateStarting
        king.removeFromParent()
        background.removeAllChildren()
        background.removeFromParent()
        label_scoreboard.removeFromParent()
        label_bestScore.removeFromParent()
        
        instructions.hidden = false
        self.removeActionForKey("generator")
        
        score = 0
        label_score.text = "0"
        
        
        self.initking()
        self.initBackground()
    }
    
    // #pragma mark - SKPhysicsContactDelegate
    func didBeginContact(contact: SKPhysicsContact!) {
        let collision:UInt32 = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask)
        
        if collision == (FSPlayerCategory | FSGapCategory) {
            self.runAction(scoreSound)
            score++
            label_score.text = "\(score)"
        }
        
        if collision == (FSPlayerCategory | FSPipeCategory) {
            self.runAction(thumpSound)
            self.gameOver()
        }
        
        if collision == (FSPlayerCategory | FSBoundaryCategory) {
            if king.position.y < 150 {
                self.runAction(thumpSound)
                self.gameOver()
            }
        }
    }
    
    // #pragma mark - Touch Events
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if state == .FSGameStateStarting {
            state = .FSGameStatePlaying
            
            instructions.hidden = true
            
            self.runAction(whirpSound)
            king.physicsBody?.affectedByGravity = true
            king.physicsBody?.applyImpulse(CGVectorMake(0, 25))
            
            self.runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock { self.initPipes()}])), withKey: "generator")
        }
            
        else if state == .FSGameStatePlaying {
            self.runAction(whirpSound)
            king.physicsBody?.applyImpulse(CGVectorMake(0, 25))
        }
    }
    
    // #pragma mark - Frames Per Second
    override func update(currentTime: CFTimeInterval) {
        if last_update_time == 0.0 {
            delta = 0
        } else {
            delta = currentTime - last_update_time
        }
        
        last_update_time = currentTime
        //
        let textureFloat: SKTexture = SKTexture(imageNamed: "king1")
        let textureUp: SKTexture = SKTexture(imageNamed: "king2")
        let textureDown: SKTexture = SKTexture(imageNamed: "king3")
        let float = SKAction.setTexture(textureFloat)
        let up = SKAction.setTexture(textureUp)
        let down = SKAction.setTexture(textureDown)
        let fallDownTextures = [textureFloat, textureDown]
        let animateFall = SKAction.animateWithTextures(fallDownTextures, timePerFrame: 2.0)
        //
        
        
        if state != .FSGameStateEnded {
            self.moveBackground()
            
            let velocity_x = king.physicsBody?.velocity.dx
            let velocity_y = king.physicsBody?.velocity.dy
            
            if king.physicsBody?.velocity.dy > 280 {
                king.physicsBody?.velocity = CGVectorMake(velocity_x!, 280)
            }
            if king.physicsBody?.velocity.dy > 0 {
                king.runAction(up)
            }
            if king.physicsBody?.velocity.dy < 0 {
                king.runAction(float)
            }

           // king.zRotation = Float.clamp(-1, max: 0.0, value: velocity_y! * (velocity_y < 0 ? 0.003 : 0.001))
        } else {
            
            king.zRotation = CGFloat(M_PI)
            king.removeAllActions()
        }
    }
    
    func initHUD() {
        
        
        label_score = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        label_score.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMaxY(self.frame) - 100)
        label_score.text = "0"
        label_score.zPosition = 50
        label_score.fontColor = UIColor(red: 245/255, green: 202/255, blue: 84/255, alpha: 1.0)
        self.addChild(label_score)
        
        
        instructions = SKSpriteNode(imageNamed: "TapToStart")
        instructions.position = CGPointMake(102.5, CGRectGetMidY(self.frame) - 35)
            //CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - 10)
        instructions.zPosition = 50
        self.addChild(instructions)
    }
    
}

