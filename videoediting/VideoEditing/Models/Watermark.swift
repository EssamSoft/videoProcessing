//
//  Watermark.swift
//  VideoEditing
//
//  Created by jaba odishelashvili on 6/3/18.
//  Copyright © 2018 Jabson. All rights reserved.
//

import UIKit

struct Watermark {
    var animableWatermark: AnimableWatermark?
    var textWatermark: TextWatermark?
    
    init(animableWatermark: AnimableWatermark? = nil, textWatermark: TextWatermark? = nil) {
        self.animableWatermark = animableWatermark
        self.textWatermark = textWatermark
    }
}

struct AnimableWatermark {
    let images: [UIImage]
    let duration: Double
    let position: CGPoint
    let repeatCount: Float
    
    init(images: [UIImage], duration: Double, position: CGPoint, repeatCount: Float) {
        self.images = images
        self.duration = duration
        self.position = position
        self.repeatCount = repeatCount
    }
}

struct TextWatermark {
    enum Animation {
        case None
        case Fade
        case Move
    }
    
    let string: String
    let font: UIFont
    let color: UIColor
    let bgColor: UIColor
    let position: CGPoint
    let opacity: Float
    let shadowOpacity: Float
    let shadowOffset: CGSize
    let shadowColor: UIColor
    let animation: Animation
    let animationDuration: Double
        
    init(string: String, font: UIFont,
         color: UIColor, bgColor: UIColor,
         position: CGPoint, opacity: Float,
         shadowOpacity: Float, shadowOffset: CGSize,
         shadowColor: UIColor, animation: Animation = .None,
         animationDuration: Double = 1.0) {
        
        self.string = string
        self.font = font
        self.color = color
        self.bgColor = bgColor
        self.position = position
        self.opacity = opacity
        self.shadowOpacity = shadowOpacity
        self.shadowOffset = shadowOffset
        self.shadowColor = shadowColor
        self.animation = animation
        self.animationDuration = animationDuration
    }
}
