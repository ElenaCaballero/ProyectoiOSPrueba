//
//  PopAnimator.swift
//  KaisApp
//
//  Created by Elena Caballero on 11/7/17.
//  Copyright © 2017 Elena Caballero. All rights reserved.
//

import UIKit

class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 1.0
    var presenting = true
    var originFrame = CGRect.zero
    var dismissCompletion: (()->Void)?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let popUpView = presenting ? toView : transitionContext.view(forKey: .from)!
        
        let initialFrame = presenting ? originFrame : popUpView.frame
        let finalFrame = presenting ? popUpView.frame : originFrame
        let xScaleFactor = presenting ? initialFrame.width / finalFrame.width : finalFrame.width / initialFrame.width
        let yScaleFactor = presenting ? initialFrame.height / finalFrame.height : finalFrame.height / initialFrame.height
        
        let scaleTransform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
        
        if presenting {
            popUpView.transform = scaleTransform
            popUpView.center = CGPoint(
                x: initialFrame.midX,
                y: initialFrame.midY)
            popUpView.clipsToBounds = true
        }
        
        containerView.addSubview(toView)
        containerView.bringSubview(toFront: popUpView)
        
        UIView.animate(withDuration: duration, delay:0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.0,
                   animations: {
                    popUpView.transform = self.presenting ?
                        CGAffineTransform.identity : scaleTransform
                    popUpView.center = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
                }, completion: { _ in
                    if !self.presenting {
                        self.dismissCompletion?()
                    }
                    transitionContext.completeTransition(true)
                }
        )
    }
}
