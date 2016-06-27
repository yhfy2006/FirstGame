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
    static let All       : UInt32 = UInt32.max
    static let Player      : UInt32 = 0b1       // 1
    static let Wall      : UInt32 = 0b10      // 2
    static let Other     : UInt32 = 0b11      // 3
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
    let player = SKSpriteNode(imageNamed: "projectile")
    var monstersDestroyed = 0
    
    var playerPosition = 0 // 1 = left 2 = right
    
    override func didMoveToView(view: SKView) {
        // 2
        backgroundColor = SKColor.whiteColor()
        // 3
        player.position = CGPoint(x: size.width / 2, y: 0)
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size) // 1
        player.physicsBody?.dynamic = true // 2
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        // 4
        addChild(player)
        
        
        
        physicsWorld.gravity = CGVectorMake(0,0)
        self.physicsWorld.contactDelegate = self
        
//        runAction(SKAction.repeatActionForever(
//            SKAction.sequence([
//                SKAction.runBlock(addMonster),
//                SKAction.waitForDuration(1.0)
//                ])
//            ))

        let leftPath = CGPathCreateMutable()
        CGPathMoveToPoint(leftPath, nil, 0, 0)
        CGPathAddLineToPoint(leftPath, nil, 0, self.frame.height)
        let leftWall = SKShapeNode()
        leftWall.path = leftPath
        leftWall.strokeColor = UIColor.redColor()
        leftWall.lineWidth = 5
        leftWall.physicsBody = SKPhysicsBody.init(edgeLoopFromPath: leftPath);
        leftWall.physicsBody?.dynamic = true
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        
        leftWall.physicsBody?.contactTestBitMask = PhysicsCategory.Player  //Contact will be detected when red or green ball hit the wall
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        leftWall.physicsBody?.collisionBitMask = PhysicsCategory.Player
        addChild(leftWall)
        
        let rightPath = CGPathCreateMutable()
        CGPathMoveToPoint(rightPath, nil, self.frame.width, 0)
        CGPathAddLineToPoint(rightPath, nil, self.frame.width, self.frame.height)
        let rightWall = SKShapeNode()
        rightWall.path = rightPath
        rightWall.strokeColor = UIColor.greenColor()
        rightWall.lineWidth = 5
        rightWall.physicsBody = SKPhysicsBody.init(edgeLoopFromPath: rightPath);
        rightWall.physicsBody?.dynamic = true
        rightWall.physicsBody?.contactTestBitMask = PhysicsCategory.Player  //Contact will be detected when red or green ball hit the wall
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        rightWall.physicsBody?.collisionBitMask = PhysicsCategory.Player
        addChild(rightWall)
        
        
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // 1 - Choose one of the touches to work with
        guard touches.first != nil else {
            return
        }
       // let touchLocation = touch.locationInNode(self)
        
        var dest = CGPointMake(0,0)
        let dy:CGFloat = 60
        if(playerPosition == 0) // center
        {
             dest = CGPointMake(0, player.position.y+dy)
            playerPosition = 1
        }else if(playerPosition == 1) // left
        {
             dest = CGPointMake(size.width, player.position.y+dy)
             playerPosition = 2
        }else // right
        {
             dest = CGPointMake(0, player.position.y+dy)
             playerPosition = 1
        }
    
        
        // 9 - Create the actions
        let actionMove = SKAction.moveTo(dest, duration: 0.5)
        //let actionMoveDone = SKAction.removeFromParent()
        player.runAction(SKAction.sequence([actionMove]))
        
        //runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
    }
    
    func projectileDidCollideWithMonster(projectile:SKSpriteNode, monster:SKSpriteNode) {
        print("Hit")
        projectile.removeFromParent()
        monster.removeFromParent()
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
