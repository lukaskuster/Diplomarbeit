//
//  FancyBounceAnimationSegue.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 13.11.18.
//  Copyright © 2018 Lukas Kuster. All rights reserved.
//

import Foundation
import UIKit

class FancyBounceAnimationSegue: UIStoryboardSegue {
    enum directionTypes {
        case forward
        case backward
    }
    var direction: directionTypes = .forward
    
    override init(identifier: String?, source: UIViewController, destination: UIViewController) {
        switch identifier {
        case "forward":
            direction = .forward
        case "backward":
            direction = .backward
        default:
            direction = .forward
        }
        super.init(identifier: identifier, source: source, destination: destination)
    }
    
    override func perform() {
        let src = self.source
        let dst = self.destination
        
        let descSrc: CGFloat
        let srcDest: CGFloat
        let destBounce: CGFloat
        if direction == .forward {
            descSrc = src.view.frame.size.width
            srcDest = -src.view.frame.size.width
            destBounce = -(src.view.frame.size.width/15)
        }else{
            descSrc = -src.view.frame.size.width
            srcDest = src.view.frame.size.width
            destBounce = (src.view.frame.size.width/15)
        }
        
        let whiteBackgroundView = UIView(frame: src.view.frame)
        whiteBackgroundView.backgroundColor = UIColor.white
        
        src.view.superview?.insertSubview(whiteBackgroundView, belowSubview: src.view)
        
        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: descSrc, y: 0)
        
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: .curveEaseInOut,
                       animations: {
                        src.view.transform = CGAffineTransform(translationX: srcDest, y: 0)
                        dst.view.transform = CGAffineTransform(translationX: destBounce, y: 0)
        },
                       completion: { finished in
                        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
                            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
                        }, completion: { finished in
                            src.present(dst, animated: false, completion: nil)
                        })
        })
    }
}
