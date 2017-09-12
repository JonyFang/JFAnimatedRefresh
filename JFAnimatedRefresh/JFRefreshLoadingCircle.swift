//
//  JFRefreshLoadingCircle.swift
//  JFAnimatedRefreshExample
//
//  Created by JonyFang on 2017/9/12.
//  Copyright © 2017年 JonyFang. All rights reserved.
//

import UIKit

open class JFRefreshLoadingCircle: JFRefreshLoadingView {
    
    //MARK: - Properties
    fileprivate let shapeLayer = CAShapeLayer()
    fileprivate let kRotationAnimation = "kRotationAnimation"
    
    fileprivate lazy var identityTransform: CATransform3D = {
        var transform = CATransform3DIdentity
        transform.m34 = CGFloat(1.0 / 500)
        transform = CATransform3DRotate(transform, CGFloat(-90.0).toRadius(), 0.0, 0.0, 1.0)
        return transform
    }()
    
    //MARK: - Life Cycle
    public override init() {
        super.init(frame: .zero)
        setupView()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func tintColorDidChange() {
        super.tintColorDidChange()
        shapeLayer.strokeColor = tintColor.cgColor
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        let inset = shapeLayer.lineWidth / 2.0
        shapeLayer.path = UIBezierPath(ovalIn: shapeLayer.bounds.insetBy(dx: inset, dy: inset)).cgPath
    }
    
    //MARK: - Private Methods
    fileprivate func setupView() {
        shapeLayer.lineWidth = 1.6
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = tintColor.cgColor
        shapeLayer.actions = ["strokeEnd": NSNull(), "transform": NSNull()]
        shapeLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.addSublayer(shapeLayer)
    }
    
    fileprivate func currentDegree() -> CGFloat {
        return shapeLayer.value(forKeyPath: "transform.rotation.z") as! CGFloat
    }
    
    open override func updatePullProgress(_ progress: CGFloat) {
        super.updatePullProgress(progress)
        shapeLayer.strokeEnd = min(0.96 * progress, 0.96)
        if progress > 1.0 {
            let degrees = (progress - 1.0) * 200
            shapeLayer.transform = CATransform3DRotate(identityTransform, degrees.toRadius(), 0.0, 0.0, 1.0)
        }
        else {
            shapeLayer.transform = identityTransform
        }
    }
    
    open override func startAnimation() {
        super.startAnimation()
        if shapeLayer.animation(forKey: kRotationAnimation) != nil { return }
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = 2 * .pi + currentDegree()
        rotationAnimation.duration = 1.0
        rotationAnimation.repeatCount = Float.infinity
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.fillMode = kCAFillModeForwards
        shapeLayer.add(rotationAnimation, forKey: kRotationAnimation)
    }
    
    open override func stopLoading() {
        super.stopLoading()
        shapeLayer.removeAnimation(forKey: kRotationAnimation)
    }
}

public extension CGFloat {
    public func toRadius() -> CGFloat {
        return (self * .pi) / 180.0
    }
    
    public func toDegrees() -> CGFloat {
        return self * 180.0 / .pi
    }
}
