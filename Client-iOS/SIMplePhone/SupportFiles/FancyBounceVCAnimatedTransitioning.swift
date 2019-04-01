//
//  FancyBounceVCAnimatedTransitioning.swift
//  SIMplePhone
//
//  Created by Lukas Kuster on 02.02.19.
//  Copyright © 2019 Lukas Kuster. All rights reserved.
//

import Foundation
import UIKit

class FancyBounceVCAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let src = transitionContext.viewController(forKey: .from)!
        let dst = transitionContext.viewController(forKey: .to)!
        
        let descSrc = src.view.frame.size.width
        let srcDest = -src.view.frame.size.width
        let destBounce = -(src.view.frame.size.width/15)
        
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
                            transitionContext.completeTransition(true)
                        })
        })
    }
}
