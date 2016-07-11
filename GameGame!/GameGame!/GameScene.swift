//
//  GameScene.swift
//  SpriteKitSimpleGame
//
//  Created by Main Account on 10/30/15.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let Player      : UInt32 = 0b1      // 1
    static let Wall      : UInt32 = 0b10      // 2
    static let Pipes     : UInt32 = 0b11      // 3
    static let Score     : UInt32 = 0b111
    static let World     : UInt32 = 0b1111
    static let All       : UInt32 = UInt32.max
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // 1
    var player:SKSpriteNode?
    
    var piper1Texture:SKTexture?
    var piper2Texture:SKTexture?
    
    var movePipiesAndRemove:SKAction?
    
    var monstersDestroyed = 0
    
    var playerPosition = 0 // 1 = left 2 = right
    
    var skyColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)

    var moving:SKNode = SKNode()
    
    var pipes = SKNode()
    
    
    let kVerticalPipeGap = CGFloat(100)
    
    var score = 0
    var scoreLabelNode:SKLabelNode?
    
    var canRestart = false
    
    override func didMoveToView(view: SKView) {

        backgroundColor = skyColor
        physicsWorld.gravity = CGVectorMake(0,-0.5)
        
        
        addChild(moving)
        
        //create player
        let playerTexture1 = SKTexture(imageNamed: "Bird1")
        playerTexture1.filteringMode = SKTextureFilteringMode.Nearest

        let playerTexture2 = SKTexture(imageNamed: "Bird2")
        playerTexture2.filteringMode = SKTextureFilteringMode.Nearest

        let flap = SKAction.repeatActionForever(SKAction.animateWithTextures([playerTexture1,playerTexture2], timePerFrame: 0.2))
        player = SKSpriteNode(texture: playerTexture1)
        player?.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame))
        player?.runAction(flap)
        player?.physicsBody = SKPhysicsBody(circleOfRadius: (player?.size.height)!/2)
        player?.physicsBody?.dynamic = true
        player?.physicsBody?.allowsRotation = false;
        player?.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player?.physicsBody?.collisionBitMask = PhysicsCategory.Wall | PhysicsCategory.Pipes
        player?.physicsBody?.contactTestBitMask = PhysicsCategory.Wall | PhysicsCategory.Pipes
        addChild(player!)
        
        // Create ground
        let groundTexture = SKTexture(imageNamed: "Ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        
        let moveGroundSprite = SKAction.moveByX(-groundTexture.size().width*2, y: 0, duration: 0.1*Double(groundTexture.size().width)*2)
        let resetGroundSprite = SKAction.moveByX(groundTexture.size().width*2, y:0, duration: 0)
        let moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        for var i = 0; i <= 2 + Int(self.frame.width / (groundTexture.size().width * 2)); i += 1 {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPointMake(CGFloat(i) * sprite.size.width, sprite.size.height / 2)
            sprite.runAction(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        // add pipes
        moving.addChild(pipes)
        
        
        // Create skyline
        let skyLinTexture = SKTexture(imageNamed: "Skyline")
        skyLinTexture.filteringMode = SKTextureFilteringMode.Nearest
        let moveSkylineSprite = SKAction.moveByX(-skyLinTexture.size().width*2, y: 0, duration: 0.1*Double(skyLinTexture.size().width)*2)
        let resetSkylineSprite = SKAction.moveByX(skyLinTexture.size().width*2, y: 0, duration: 0)
        let moveSkylineSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkylineSprite, resetSkylineSprite]))
        
        for var i = 1; i <= 2 + Int(self.frame.size.width/(skyLinTexture.size().width)*2); i += 1 {
            let sprite = SKSpriteNode(texture: skyLinTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPointMake(CGFloat(i) * sprite.size.width/2, sprite.size.height / 2 + groundTexture.size().height * 2)
            sprite.runAction(moveSkylineSpritesForever)
            moving.addChild(sprite)
        }
        
        
        // Create ground physics container
        let dummy = SKNode()
        dummy.position = CGPointMake(0, groundTexture.size().height)
        dummy.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.width, groundTexture.size().height*2))
        dummy.physicsBody?.dynamic = false
        dummy.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        addChild(dummy)
        
        
        self.physicsWorld.contactDelegate = self
        
        // Create pipes
        piper1Texture  = SKTexture(imageNamed: "Pipe1")
        piper2Texture  = SKTexture(imageNamed: "Pipe2")
        piper1Texture?.filteringMode = SKTextureFilteringMode.Nearest
        piper2Texture?.filteringMode = SKTextureFilteringMode.Nearest
        
        let distanceToMove = self.frame.width * 2 * (piper1Texture?.size().width)!
        let movePipes = SKAction.moveByX(-distanceToMove, y: 0, duration: 0.01 * Double(distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipiesAndRemove = SKAction.sequence([movePipes,removePipes])
        
        let spawnAction = SKAction.performSelector(Selector("spawnPipes"), onTarget: self)
        let delayAction = SKAction.waitForDuration(2.0)
        let spawnThenDelay = SKAction.sequence([spawnAction,delayAction])
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
        
        scoreLabelNode = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        scoreLabelNode?.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.size.height * 3 / 4)
        scoreLabelNode?.zPosition = 100
        scoreLabelNode?.text = "\(self.score)"
        self.addChild(scoreLabelNode!)
        
    }
    
    func spawnPipes()
    {
        let piperPaire = SKNode()
        piperPaire.position = CGPointMake(self.frame.width + self.piper1Texture!.size().width , 0)
        piperPaire.zPosition = -10
        
        let y  = arc4random() % UInt32( self.frame.height / 3 )
        
        let pipe1 = SKSpriteNode(texture: piper1Texture)
        pipe1.setScale(2)
        pipe1.position = CGPointMake(0, CGFloat(y))
        pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipe1.size)
        pipe1.physicsBody?.dynamic = false
        pipe1.physicsBody?.categoryBitMask = PhysicsCategory.Pipes
        pipe1.physicsBody?.contactTestBitMask = PhysicsCategory.Pipes
        
        piperPaire.addChild(pipe1)
        
        let pipe2 = SKSpriteNode(texture: piper2Texture)
        pipe2.setScale(2)
        pipe2.position = CGPointMake(0, CGFloat(y) + pipe1.size.height + kVerticalPipeGap)
        pipe2.physicsBody = SKPhysicsBody(rectangleOfSize: pipe2.size)
        pipe2.physicsBody?.dynamic = false
        pipe2.physicsBody?.categoryBitMask = PhysicsCategory.Pipes
        pipe2.physicsBody?.contactTestBitMask = PhysicsCategory.Pipes
        
        piperPaire.addChild(pipe2)
        
        let contactNode = SKNode()
        contactNode.position = CGPointMake(pipe1.size.width + self.player!.size.width/2, CGRectGetMidY(self.frame))
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipe2.size.width, self.frame.size.height))
        contactNode.physicsBody?.dynamic = false
        contactNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        contactNode.physicsBody?.contactTestBitMask = PhysicsCategory.Score
        
        piperPaire.addChild(contactNode)
        piperPaire.runAction(movePipiesAndRemove!)
        
        pipes.addChild(piperPaire)
        
        
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func resetScene() {
        player?.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame))
        player?.physicsBody?.velocity = CGVectorMake(0, 0)
        player?.physicsBody?.collisionBitMask = PhysicsCategory.World | PhysicsCategory.Pipes
        player?.speed = 1.0
        player?.zRotation = 0.0
        
        pipes.removeAllChildren()
        canRestart = false
        
        moving.speed = 1
        
        score = 0
        scoreLabelNode?.text = "\(score)"
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if moving.speed > 0
        {
            player?.physicsBody?.velocity = CGVectorMake(0, 0)
            player?.physicsBody?.applyImpulse(CGVectorMake(0, 4))
        }else if canRestart
        {
           resetScene()
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // 1 - Choose one of the touches to work with
        guard touches.first != nil else {
            return
        }
//       // let touchLocation = touch.locationInNode(self)
//        player.physicsBody?.dynamic = false // 2
//
//        var dest = CGPointMake(0,0)
//        let dy:CGFloat = 60
//        if(playerPosition == 0) // center
//        {
//             dest = CGPointMake(0, player.position.y+dy)
//            playerPosition = 1
//        }else if(playerPosition == 1) // left
//        {
//             dest = CGPointMake(size.width-20, player.position.y+dy)
//             playerPosition = 2
//        }else // right
//        {
//             dest = CGPointMake(0, player.position.y+dy)
//             playerPosition = 1
//        }
//    
//        
//        // 9 - Create the actions
//        let actionMove = SKAction.moveTo(dest, duration: 0.5)
//        //let actionMoveDone = SKAction.removeFromParent()
//        /player.runAction(SKAction.sequence([actionMove]))
        
    }
    
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
    }
    
    func playerStartToFall(playerNode:SKSpriteNode) {
        //player.physicsBody?.dynamic = true
        playerNode.removeAllActions();
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        //return
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        let collision: UInt32 = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if collision == PhysicsCategory.Wall | PhysicsCategory.Player {
            playerStartToFall(firstBody.node as! SKSpriteNode)
        }
        
//        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) &&
//            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
//            projectileDidCollideWithMonster(firstBody.node as! SKSpriteNode, monster: secondBody.node as! SKSpriteNode)
//        }
//        
//        monstersDestroyed++
//        if (monstersDestroyed > 30) {
//            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
//            let gameOverScene = GameOverScene(size: self.size, won: true)
//            self.view?.presentScene(gameOverScene, transition: reveal)
//        }
        
        
    }
    
}
