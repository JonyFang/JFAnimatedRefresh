//
//  JFAnimatedRefreshExtensions.swift
//  JFAnimatedRefreshExample
//
//  Created by JonyFang on 2017/9/12.
//  Copyright © 2017年 JonyFang. All rights reserved.
//

import UIKit
import ObjectiveC

public extension NSObject {
    //MARK: - Public Methods
    public func jf_addObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        let observerInfo = [keyPath : observer]
        guard jf_observers.index(where: {$0 == observerInfo}) == nil else {
            return
        }
        jf_observers.append(observerInfo)
        addObserver(observer, forKeyPath: keyPath, options: .new, context: nil)
    }
    
    public func jf_removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        let observerInfo = [keyPath : observer]
        guard let index = jf_observers.index(where: {$0 == observerInfo}) else {
            return
        }
        jf_observers.remove(at: index)
        removeObserver(observer, forKeyPath: keyPath)
    }
    
    //MARK: - Private Methods
    fileprivate struct jf_associatedKeys {
        static var observers = "observers"
    }
    
    fileprivate var jf_observers: [[String : NSObject]] {
        get {
            guard let observers = objc_getAssociatedObject(self, &jf_associatedKeys.observers) as? [[String : NSObject]] else {
                let observers = [[String : NSObject]]()
                self.jf_observers = observers
                return observers
            }
            return observers
        }
        set {
            objc_setAssociatedObject(self, &jf_associatedKeys.observers, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public extension UIView {
    func jf_center(_ usePresentationLayerIfPossible: Bool) -> CGPoint {
        guard usePresentationLayerIfPossible, let presentationLayer = layer.presentation() else {
            return center
        }
        return presentationLayer.position
    }
}

public extension UIGestureRecognizerState {
    func jf_isAnyOf(_ values: [UIGestureRecognizerState]) -> Bool {
        return values.contains(where: {$0 == self})
    }
}

public extension UIScrollView {
    //MARK: - Public Methods
    public func jf_addPullToRefreshWithHandler(_ handler: @escaping () -> Void, loadingView: JFAnimatedRefreshLoadingView?) {
        isMultipleTouchEnabled = false
        panGestureRecognizer.maximumNumberOfTouches = 1
        
        let pullToRefreshView = JFAnimatedRefresh()
        pullToRefreshView.actionHandler = handler
        pullToRefreshView.loadingView = loadingView
        self.pullToRefreshView = pullToRefreshView
        addSubview(pullToRefreshView)
        
        pullToRefreshView.isObserving = true
    }
    
    public func jf_removePullToRefresh() {
        pullToRefreshView?.disassociateDisplayLink()
        pullToRefreshView?.isObserving = false
        pullToRefreshView?.removeFromSuperview()
    }
    
    public func jf_setPullToRefreshBackgroundColor(_ color: UIColor) {
        pullToRefreshView?.backgroundColor = color
    }
    
    public func jf_setPullToRefreshFillColor(_ color: UIColor) {
        pullToRefreshView?.fillColor = color
    }
    
    public func jf_stopLoading() {
        pullToRefreshView?.stopLoading()
    }
    
    //MARK: - Private Methods
    fileprivate struct jf_associatedKeys {
        static var pullToRefreshView = "pullToRefreshView"
    }
    
    fileprivate var pullToRefreshView: JFAnimatedRefresh? {
        get {
            return objc_getAssociatedObject(self, &jf_associatedKeys.pullToRefreshView) as? JFAnimatedRefresh
        }
        set {
            objc_setAssociatedObject(self, &jf_associatedKeys.pullToRefreshView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
