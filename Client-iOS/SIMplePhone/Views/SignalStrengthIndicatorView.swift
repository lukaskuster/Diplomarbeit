//
//  SignalStrengthIndicatorView.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 12.12.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import UIKit

public class SignalStrengthIndicatorView: UIView {
    public var strength: Double = 0.0 {
        didSet {
            self.backgroundColor = .clear
            self.setNeedsDisplay()
        }
    }
    
    // MARK: - Constants
    
    private let indicatorsCount: Int = 4
    private let edgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
    private let spacing: CGFloat = 2
    private let darkColor = UIColor.black
    private let lightColor = UIColor.lightGray
    
    // MARK: - Drawing
    
    override public func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        ctx.saveGState()
        
        let levelValue: Int
        switch strength {
        case ..<0.15:
            levelValue = 0
        case ..<0.35:
            levelValue = 1
        case ..<0.55:
            levelValue = 2
        case ..<0.80:
            levelValue = 3
        case ..<1.0:
            levelValue = 4
        default:
            levelValue = 4
        }
        
        
        let barsCount = CGFloat(indicatorsCount)
        let barWidth = (rect.width - edgeInsets.right - edgeInsets.left - ((barsCount - 1) * spacing)) / barsCount
        let barHeight = rect.height - edgeInsets.top - edgeInsets.bottom
        
        for index in 0...indicatorsCount - 1 {
            let i = CGFloat(index)
            let width = barWidth
            let height = barHeight - (((barHeight * 0.5) / barsCount) * (barsCount - i))
            let x: CGFloat = edgeInsets.left + i * barWidth + i * spacing
            let y: CGFloat = barHeight - height
            let cornerRadius: CGFloat = barWidth * 0.35
            let barRect = CGRect(x: x, y: y, width: width, height: height)
            let clipPath: CGPath = UIBezierPath(roundedRect: barRect, cornerRadius: cornerRadius).cgPath
            
            ctx.addPath(clipPath)
            if index + 1 > levelValue {
                ctx.setFillColor(lightColor.cgColor)
            }
            else {
                ctx.setFillColor(darkColor.cgColor)
            }
            ctx.fillPath()
        }
        
        ctx.restoreGState()
    }
}
