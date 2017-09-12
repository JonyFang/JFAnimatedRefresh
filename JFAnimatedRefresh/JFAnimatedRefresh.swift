//
//  JFAnimatedRefresh.swift
//  JFAnimatedRefreshExample
//
//  Created by JonyFang on 2017/9/12.
//  Copyright © 2017年 JonyFang. All rights reserved.
//

import UIKit

public enum JFAnimatedRefreshState: Int {
    case stopped
    case dragging
    case animatingBounce
    case loading
    case animatingToStopped
    
    func isAnyOf(_ values: [JFAnimatedRefreshState]) -> Bool {
        return values.contains(where: {$0 == self})
    }
}

open class JFAnimatedRefresh: UIView {
    
    //MARK: - Properties
    fileprivate var _state: JFAnimatedRefreshState = .stopped
    fileprivate var state: JFAnimatedRefreshState {
        get {
            return _state
        }
        set {
            let previousValue = state
            _state = newValue
            if previousValue == .dragging && newValue == .animatingBounce {
                loadingView?.startAnimation()
                //
            }
            else if newValue == .loading && actionHandler != nil {
                actionHandler()
            }
            else if newValue == .animatingToStopped {
                //
            }
            else if newValue == .stopped {
                loadingView?.stopLoading()
            }
        }
    }
    
    var loadingView: JFAnimatedRefreshLoadingView? {
        willSet {
            loadingView?.removeFromSuperview()
            if let newValue = newValue {
                addSubview(newValue)
            }
        }
    }
    
    var actionHandler:(() -> Void)!
    fileprivate let shapLayer = CAShapeLayer()
    fileprivate var displayLink: CADisplayLink!
    
    fileprivate var originalContentInsetTop: CGFloat = 0.0 {
        didSet {
            layoutSubviews()
        }
    }
    
    var observing: Bool = false {
        didSet {
            guard let scrollView = scrollView() else {
                return
            }
            if observing {
                scrollView.jf_addObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentOffset)
                scrollView.jf_addObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentInset)
                scrollView.jf_addObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.Frame)
                scrollView.jf_addObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.PanGestureRecognizerState)
            }
            else {
                scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentOffset)
                scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentInset)
                scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.Frame)
                scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.PanGestureRecognizerState)
            }
        }
    }
    
    var fillColor: UIColor = .clear {
        didSet {
            shapLayer.fillColor = fillColor.cgColor
        }
    }
    
    fileprivate let bounceAnimationHelperView = UIView()
    fileprivate let cControlPointView = UIView()
    fileprivate let l1ControlPointView = UIView()
    fileprivate let l2ControlPointView = UIView()
    fileprivate let l3ControlPointView = UIView()
    fileprivate let r1ControlPointView = UIView()
    fileprivate let r2ControlPointView = UIView()
    fileprivate let r3ControlPointView = UIView()
    
    //MARK: - Life Cycle
    init() {
        super.init(frame: .zero)
        displayLink = CADisplayLink(target: self, selector: #selector(JFAnimatedRefresh.displayLinkTick))
        displayLink.add(to: .main, forMode: .commonModes)
        displayLink.isPaused = true
        
        shapLayer.backgroundColor = UIColor.clear.cgColor
        shapLayer.fillColor = UIColor.black.cgColor
        shapLayer.actions = ["path": NSNull(), "position": NSNull(), "bounds": NSNull()]
        layer.addSublayer(shapLayer)
        
        addSubview(bounceAnimationHelperView)
        addSubview(cControlPointView)
        addSubview(l1ControlPointView)
        addSubview(l2ControlPointView)
        addSubview(l3ControlPointView)
        addSubview(r1ControlPointView)
        addSubview(r2ControlPointView)
        addSubview(r3ControlPointView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(JFAnimatedRefresh.applicationWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        observing = false
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if let scrollView = scrollView(), state != .animatingBounce {
            let width = scrollView.bounds.width
            let height = currentHeight()
            frame = CGRect(x: 0.0, y: -height, width: width, height: height)
            
            if state.isAnyOf([.loading, .animatingToStopped]) {
                cControlPointView.center = CGPoint(x: width * 0.5, y: height)
                l1ControlPointView.center = CGPoint(x: 0.0, y: height)
                l2ControlPointView.center = CGPoint(x: 0.0, y: height)
                l3ControlPointView.center = CGPoint(x: 0.0, y: height)
                r1ControlPointView.center = CGPoint(x: width, y: height)
                r2ControlPointView.center = CGPoint(x: width, y: height)
                r3ControlPointView.center = CGPoint(x: width, y: height)
            }
            else {
                let locationX = scrollView.panGestureRecognizer.location(in: scrollView).x
                let waveHeight = currentWaveHeight()
                let baseHeight = bounds.height - waveHeight
                
                let minleftX = min((locationX - width * 0.5) * 0.28, 0.0)
                let maxRightX = max(width + (locationX - width * 0.5) * 0.28, width)
                
                let lefPartWidth = locationX - minleftX
                let rightPartWidth = maxRightX - locationX
                
                cControlPointView.center = CGPoint(x: locationX, y: baseHeight + waveHeight * 1.36)
                l1ControlPointView.center = CGPoint(x: minLeftX + leftPartWidth * 0.71, y: baseHeight + waveHeight * 0.64)
                l2ControlPointView.center = CGPoint(x: minLeftX + leftPartWidth * 0.44, y: baseHeight)
                l3ControlPointView.center = CGPoint(x: minLeftX, y: baseHeight)
                r1ControlPointView.center = CGPoint(x: maxRightX - rightPartWidth * 0.71, y: baseHeight + waveHeight * 0.64)
                r2ControlPointView.center = CGPoint(x: maxRightX - (rightPartWidth * 0.44), y: baseHeight)
                r3ControlPointView.center = CGPoint(x: maxRightX, y: baseHeight)
            }
            shapeLayer.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
            shapeLayer.path = currentPath()
            
            layoutLoadingView()
        }
    }
    
    //MARK: - Public Methods
    func disassociateDisplayLink() {
        displayLink.invalidate()
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == JFAnimatedRefreshConstants.KeyPaths.ContentOffset {
            if let newContentOffset = change?[NSKeyValueChangeKey.newKey], let scrollView = scrollView() {
                let newContentOffsetY = (newContentOffset as AnyObject).cgPointValue.y
                if state.isAnyOf([.loading, .animatingToStopped]) && newContentOffsetY < -scrollView.contentInset.top {
                    scrollView.contentOffset.y = -scrollView.contentInset.top
                }
                else {
                    scrollViewDidChangeContentOffset(dragging: scrollView.isDragging)
                }
                layoutSubviews()
            }
        }
        else if keyPath == JFAnimatedRefreshConstants.KeyPaths.ContentInset {
            if let newContentInset = change?[NSKeyValueChangeKey.newKey] {
                let newContentInsetTop = (newContentInset as AnyObject).uiEdgeInsetsValue.top
                originalContentInsetTop = newContentInsetTop
            }
        }
        else if keyPath == JFAnimatedRefreshConstants.KeyPaths.Frame {
            layoutSubviews()
        }
        else if keyPath == JFAnimatedRefreshConstants.KeyPaths.PanGestureRecognizerState {
            if let gestureState = scrollView()?.panGestureRecognizer.state, gestureState.jf_isAnyOf([.ended, .cancelled, .failed]) {
                scrollViewDidChangeContentOffset(dragging: false)
            }
        }
    }
    
    func stopLoading() {
        if state == .animatingToStopped {
            return
        }
        state = .animatingToStopped
    }
    
    //MARK: - Private Methods
    fileprivate func resetScrollViewContentInset(shouldAddObserverWhenFinished: Bool, animated: Bool, completion: (() -> ())?) {
        guard let scrollView = scrollView() else { return }
        
        var contentInset = scrollView.contentInset
        contentInset.top = originalContentInsetTop
        
        if state == .animatingBounce {
            contentInset.top += JFAnimatedRefreshConstants.LoadingContentInset
        }
        else if state == .loading {
            contentInset.top += JFAnimatedRefreshConstants.LoadingContentInset
        }
        
        scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentInset)
        
        let animationBlock = {
            scrollView.contentInset = contentInset
        }
        let completionBlock = { () -> Void in
            if  shouldAddObserverWhenFinished && self.observing {
                scrollView.jf_addObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentInset)
            }
            completion?()
        }
        
        if animated {
            startDisplayLink()
            UIView.animate(withDuration: 0.4, animations: animationBlock, completion: { _ in
                self.startDisplayLink()
                completionBlock()
            })
        }
        else {
            animationBlock()
            completionBlock()
        }
    }
    
    fileprivate func currentHeight() -> CGFloat {
        guard let scrollView = scrollView() else { return 0.0 }
        return max(-originalContentInsetTop - scrollView.contentOffset.y, 0)
    }
    
    fileprivate func currentWaveHeight() -> CGFloat {
        return min(bounds.height / 3.0 * 1.6, JFAnimatedRefreshConstants.WaveMaxHeight)
    }
    
    
    fileprivate func scrollViewDidChangeContentOffset(dragging: Bool) {
        let offsetY = actualContentOffsetY()
        if state == .stopped && dragging {
            state = .dragging
        }
        else if state == .dragging && dragging == false {
            if offsetY >= JFAnimatedRefreshConstants.MinOffsetToPull {
                state = .animatingBounce
            }
            else {
                state = .stopped
            }
        }
        else if state.isAnyOf([.dragging, .stopped]) {
            let pullProgress: CGFloat = offsetY / JFAnimatedRefreshConstants.MinOffsetToPull
            loadingView?.updatePullProgress(pullProgress)
        }
    }
    
    fileprivate func scrollView() -> UIScrollView? {
        return superview as? UIScrollView
    }
    
    @objc fileprivate func applicationWillEnterForeground() {
        if state == .loading {
            layoutSubviews()
        }
    }
    
    fileprivate func isAnimating() -> Bool {
        return state.isAnyOf([.animatingBounce, .animatingToStopped])
    }
    
    fileprivate func actualContentOffsetY() -> CGFloat {
        guard let scrollView = scrollView() else { return 0.0 }
        return max(-scrollView.contentInset.top - scrollView.contentOffset.y, 0)
    }
    
    fileprivate func currentPath() -> CGPath {
        let width: CGFloat = scrollView()?.bounds.width ?? 0.0
        let bezierPath = UIBezierPath()
        let animating = isAnimating()
        
        bezierPath.move(to: CGPoint(x: 0.0, y: 0.0))
        bezierPath.addLine(to: CGPoint(x: 0.0, y: l3ControlPointView.jf_center(animating).y))
        bezierPath.addCurve(to: l1ControlPointView.jf_center(animating), controlPoint1: l3ControlPointView.jf_center(animating), controlPoint2: l2ControlPointView.jf_center(animating))
        bezierPath.addCurve(to: r1ControlPointView.jf_center(animating), controlPoint1: cControlPointView.jf_center(animating), controlPoint2: r1ControlPointView.jf_center(animating))
        bezierPath.addCurve(to: r3ControlPointView.jf_center(animating), controlPoint1: r1ControlPointView.jf_center(animating), controlPoint2: r2ControlPointView.jf_center(animating))
        bezierPath.addLine(to: CGPoint(x: width, y: 0.0))
        
        return bezierPath.cgPath
    }
    
    @objc fileprivate func displayLinkTick() {
        let width = bounds.width
        var height: CGFloat = 0.0
        if state == .animatingBounce {
            guard let scrollView = scrollView() else { return }
            scrollView.contentInset.top = bounceAnimationHelperView.jf_center(isAnimating()).y
            scrollView.contentOffset.y = -scrollView.contentInset.top
            
            height = scrollView.contentInset.top - originalContentInsetTop
            frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        }
        else if state == .animatingToStopped {
            height = actualContentOffsetY()
        }
        
        shapLayer.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        shapLayer.path = currentPath()
    }
    
    fileprivate func startDisplayLink() {
        displayLink.isPaused = false
    }
    
    fileprivate func stopDisplayLink() {
        displayLink.isPaused = true
    }
    
    fileprivate func animateBounce() {
        guard let scrollView = scrollView() else { return }
        if !self.observing { return }
        
        resetScrollViewContentInset(shouldAddObserverWhenFinished: false, animated: false, completion: nil)
        
        let centerY = JFAnimatedRefreshConstants.LoadingContentInset
        let duration = 0.9
        
        scrollView.isScrollEnabled = false
        startDisplayLink()
        scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentOffset)
        scrollView.jf_removeObserver(self, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentInset)
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.43, initialSpringVelocity: 0.0, options: [], animations: { 
            [weak self] in
            self?.cControlPointView.center.y = centerY
            self?.l1ControlPointView.center.y = centerY
            self?.l2ControlPointView.center.y = centerY
            self?.l3ControlPointView.center.y = centerY
            self?.r1ControlPointView.center.y = centerY
            self?.r2ControlPointView.center.y = centerY
            self?.r3ControlPointView.center.y = centerY
        }) { [weak self] _ in
            self?.stopDisplayLink()
            self?.resetScrollViewContentInset(shouldAddObserverWhenFinished: true, animated: false, completion: nil)
            if let strongSelf = self, let scrollView = strongSelf.scrollView() {
                scrollView.jf_addObserver(strongSelf, forKeyPath: JFAnimatedRefreshConstants.KeyPaths.ContentOffset)
                scrollView.isScrollEnabled = true
            }
            self?.state = .loading
        }
        
        bounceAnimationHelperView.center = CGPoint(x: 0.0, y: originalContentInsetTop + currentHeight())
        UIView.animate(withDuration: duration * 0.4, animations: { 
            [weak self] in
            if let contentInsetTop = self?.originalContentInsetTop {
                self?.bounceAnimationHelperView.center = CGPoint(x: 0.0, y: contentInsetTop + JFAnimatedRefreshConstants.LoadingContentInset)
            }
        }, completion: nil)
    }
    
    fileprivate func layoutLoadingView() {
        let width = bounds.width
        let height: CGFloat = bounds.height
        
        let loadingViewSize: CGFloat = JFAnimatedRefreshConstants.LoadingViewSize
        let minOriginY = (JFAnimatedRefreshConstants.LoadingContentInset - loadingViewSize) * 0.5
        let originY: CGFloat = max(min((height - loadingViewSize) * 0.5, minOriginY), 0.0)
        
        loadingView?.frame = CGRect(x: (width - loadingViewSize) * 0.5, y: originY, width: loadingViewSize, height: loadingViewSize)
        loadingView?.maskLayer.frame = convert(shapLayer.frame, to: loadingView)
        loadingView?.maskLayer.path = shapLayer.path
    }
    
}
