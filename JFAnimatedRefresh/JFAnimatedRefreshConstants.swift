//
//  JFAnimatedRefreshConstants.swift
//  JFAnimatedRefreshExample
//
//  Created by JonyFang on 2017/9/12.
//  Copyright © 2017年 JonyFang. All rights reserved.
//

import CoreGraphics

public struct JFAnimatedRefreshConstants {
    
    struct KeyPaths {
        static let ContentOffset = "contentOffset"
        static let ContentInset = "contentInset"
        static let Frame = "frame"
        static let PanGestureRecognizerState = "panGestureRecognizer.state"
    }
    
    public static var WaveMaxHeight: CGFloat = 70.0
    public static var MinOffsetToPull: CGFloat = 95.0
    public static var LoadingContentInset: CGFloat = 50.0
    public static var LoadingViewSize: CGFloat = 30.0
}
