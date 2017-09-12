//
//  JFAnimatedRefreshLoadingView.swift
//  JFAnimatedRefreshExample
//
//  Created by JonyFang on 2017/9/11.
//  Copyright © 2017年 JonyFang. All rights reserved.
//

import UIKit

open class JFAnimatedRefreshLoadingView: UIView {
    
    //MARK: - Life Cycle
    public init() {
        super.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Public Methods
    open func updatePullProgress(_ progress: CGFloat) {}
    
    open func startAnimation() {}
    
    open func stopLoading() {}
    
    //MARK: - Properties
    lazy var maskLayer: CAShapeLayer = {
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillColor = UIColor.black.cgColor
        maskLayer.actions = ["path": NSNull(), "position": NSNull(), "bounds": NSNull()]
        self.layer.mask = maskLayer
        return maskLayer
    }()
}
