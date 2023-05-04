//
//  NDSwipeView.swift
//  NDSwipe
//
//  Created by yinxing on 2022/6/23.
//

import Foundation
import UIKit

protocol NDSwipeViewDelegate: NSObjectProtocol {
    func swipeView(swipe: NDSwipeView, index: Int) -> UITableViewCell
    
    func swipeViewTotaleNumber(swipe: NDSwipeView) -> Int
    
    func swipeViewHorizontalSpacing(swipe: NDSwipeView) -> CGFloat
    
    func swipeViewVerticalSpacing(swipe: NDSwipeView) -> CGFloat
    
    func swipeViewShowPageControl(swipe: NDSwipeView) -> Bool
    
    func swipeView(swipe: NDSwipeView, didSelectedIndex index: Int) -> Void
}

extension NDSwipeViewDelegate {
    func swipeViewHorizontalSpacing(swipe: NDSwipeView) -> CGFloat {
        return 10.0
    }
    
    
    func swipeViewVerticalSpacing(swipe: NDSwipeView) -> CGFloat {
        return 5.0
    }
    
    func swipeViewShowPageControl(swipe: NDSwipeView) -> Bool {
        return false
    }
    
    func swipeView(swipe: NDSwipeView, didSelectedIndex index: Int) -> Void {
        
    }
}

class NDSwipeView: UIView {
    
    weak var delegate: NDSwipeViewDelegate?
    
    var isStackCard = false
    
    // pageControl图片
    var activeImage: UIImage?
    
    // pageControl选中图片
    var inactiveImage: UIImage?
    
    // 是否可以轮播
    var isRotation = true
    
    /// 是否自动轮播(只有当isRotation=true时，才支持自动轮播)
    var isAutoScroll = false
    
    /// 自动轮播间隔时间
    var autoScrollTimeInterval = 2.0
        
    //MARK: - 私有属性
    // 已经划动到边界外的一个view
    private var viewRemove: UITableViewCell?
    // 放当前显示的子View的数组
    private var cacheViews = [UITableViewCell]()
    // view总共的数量
    private var totalNumber = 0
    // 当前的下标
    private var nowIndex = 0
    // 中间的cell
    private var centerCell: UITableViewCell? {
        didSet {
            if let contentView = centerCell?.contentView {
                contentView.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
                for view in contentView.subviews {
                    view.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
                }
            }
            
            if let gestures = centerCell?.gestureRecognizers, !gestures.isEmpty {
                for gesture in gestures {
                    if gesture.isKind(of: UITapGestureRecognizer.self) {
                        return
                    }
                }
            }
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
            centerCell?.contentView.addGestureRecognizer(tap)
        }
    }
    // 右边的cell
    private var rightCell: UITableViewCell? {
        didSet {
            if let contentView = rightCell?.contentView {
                contentView.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
                for view in contentView.subviews {
                    view.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
                }
            }
        }
    }
    // 左边的cell
    private var leftCell: UITableViewCell? {
        didSet {
            if let contentView = leftCell?.contentView {
                contentView.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
                for view in contentView.subviews {
                    view.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
                }
            }
        }
    }
    // 自身的宽度
    private var contentWidth: CGFloat = 0.0
    // 自身的高度
    private var contentHeight: CGFloat = 0.0
    // 是否是第一次执行
    private var isFirstLayoutSub = false
    // 左右cell和中间cell的水平间距
    private var horizontalSpacing: CGFloat = 10.0
    // 左右cell和中间cell的垂直间距
    private var verticalSpacing: CGFloat = 5.0
    
    private var pageControl: NDPageControl = {
        let view = NDPageControl(frame: .zero)
        return view
    }()
    
    private var timer: Timer?
    //MARK: - --------------------- 私有属性 END ---------------------
    
    override func awakeFromNib() {
        super.awakeFromNib()
        p_initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        p_initView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !isFirstLayoutSub {
            isFirstLayoutSub = true
            contentWidth = bounds.size.width
            contentHeight = bounds.size.height
            reloadData()
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            p_releaseTimer()
        }
    }
    
    //MARK: - init
    private func p_initView() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipe(sender:)))
        swipe.direction = .left
        addGestureRecognizer(swipe)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipe(sender:)))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)
        
//        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan(sender:)))
//        addGestureRecognizer(pan)

    }
    //MARK: - --------------------- init END ---------------------
    
    //MARK: - 手势事件
    @objc func swipe(sender: UISwipeGestureRecognizer) {
        guard totalNumber > 0 else {
            return
        }
        
        if sender.state == .began {
            p_releaseTimer()
        }
        
        if sender.direction == .left {
            swipeEnd()
        }else {
            swipeGoBack()
        }
    }
    
    @objc func tap() {
        if totalNumber == 0 {
            return
        }
        
        delegate?.swipeView(swipe: self, didSelectedIndex: nowIndex)
    }
    
    @objc func pan(sender: UIPanGestureRecognizer) {
        guard let currentCell = centerCell, totalNumber > 0 else {
            return
        }
        
        let translation = sender.translation(in: self)
        var pointStart: CGPoint = .zero
        var pointLast: CGPoint = .zero
        // 手势速度，手势向左滑时，x为负数。向右滑时，x为正数
        let velocity = sender.velocity(in: self)
        if sender.state == .began {
            pointStart = translation
            p_releaseTimer()
        }else if (sender.state == .changed) {
            pointLast = translation
            
            let xTatalMove = pointLast.x - pointStart.x
            let changeX = xTatalMove * horizontalSpacing * 2.0 / contentWidth
            var x = (currentCell.frame.origin.x) + changeX
            let changeY = verticalSpacing * changeX / horizontalSpacing
            var y = (currentCell.frame.origin.y)
            let changeHeight = verticalSpacing * 2.0 * changeX / horizontalSpacing
            var height = (currentCell.frame.size.height)
            let changeAlpha = 0.4 * changeX / horizontalSpacing
            let alpha = (centerCell?.alpha ?? 1.0) - CGFloat(fabs(Double(changeAlpha)))
            if velocity.x > 0.0 && x > horizontalSpacing {
                y = y + changeY
                height = height - changeHeight
            }else if velocity.x > 0.0 && x < horizontalSpacing {
                y = y - changeY
                height = height + changeHeight
            }else if velocity.x < 0.0 && x > horizontalSpacing {
                y = y + changeY
                height = height - changeHeight
            }else if velocity.x < 0.0 && x < horizontalSpacing {
                y = y - changeY
                height = height + changeHeight
                
            }

            if x <= 0.0 {
                x = 0.0
            }
            
            if x >= horizontalSpacing * 2.0 {
                x = horizontalSpacing * 2.0
            }
            
            var rect = centerCell?.frame ?? .zero
            rect.origin.x = x
            rect.origin.y = y
            rect.size.height = height
            centerCell?.alpha = alpha
            centerCell?.frame = rect
            sender.setTranslation(.zero, in: self)
        }else if (sender.state == .ended) {
            if !isRotation && (nowIndex == 0 && velocity.x > 0 || nowIndex == totalNumber - 1 && velocity.x < 0) {
                UIView.animate(withDuration: 0.3) { [self] in
                    centerCell?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
                    centerCell?.alpha = 1.0
                }
                return
            }
            
            if velocity.x > 0.0 && velocity.x > 100.0 {
                swipeGoBack()
            }else if velocity.x < 0.0 && velocity.x < -100.0 {
                swipeEnd()
            }else {
                UIView.animate(withDuration: 0.3) { [self] in
                    centerCell?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
                    centerCell?.alpha = 1.0
                } completion: { [self] finished in
                    if isAutoScroll && isRotation {
                        p_createTimer()
                    }
                }
            }
        }
    }
    //MARK: - --------------------- 手势事件 END ---------------------
    
    //MARK: - 私有方法
    private func swipeEnd() {
        if nowIndex == totalNumber - 1 && !isRotation {
            return
        }
        
        nowIndex += 1
        nowIndex = nowIndex % totalNumber
        
        UIView.animate(withDuration: 0.3) { [self] in
            centerCell?.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            if isStackCard {
                centerCell?.alpha = 0.6
            }
        } completion: { [self] finished in
            leftCell?.alpha = 0.0
            
            if let removeView = viewRemove, isNeedAddToCache(cell: removeView) {
                cacheViews.append(removeView)
                removeView.alpha = 1.0
                removeView.removeFromSuperview()
            }
            
            viewRemove = leftCell
            leftCell = centerCell
            centerCell = rightCell
            
            if let center = centerCell, let left = leftCell {
                insertSubview(left, belowSubview: center)
            }
            if let nextCell = delegate?.swipeView(swipe: self, index:(nowIndex + 1) % totalNumber) {
                nextCell.removeFromSuperview()
                nextCell.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
                rightCell = nextCell
                
                if let left = leftCell {
                    insertSubview(nextCell, belowSubview: left)
                }
            }
            centerCell?.isUserInteractionEnabled = true
            leftCell?.isUserInteractionEnabled = false
            rightCell?.isUserInteractionEnabled = false
            
            if isStackCard {
                leftCell?.alpha = 0.3
                rightCell?.alpha = 0.3
                centerCell?.alpha = 0.3
            }
            
            // 判断是否滑动一圈后回到第一个
            if nowIndex == 0 && !isRotation {
                leftCell?.alpha = 0.0
            }else {
                leftCell?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            // 如果滑到最后一个。隐藏左边试图
            if nowIndex == totalNumber - 1 && !isRotation {
                rightCell?.alpha = 0.0
            }else {
                rightCell?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            pageControl.currentPage = nowIndex
            
            UIView.animate(withDuration: 0.2) { [self] in
                centerCell?.alpha = 1.0
                centerCell?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
                rightCell?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            } completion: { [self] finished in
                if isAutoScroll && isRotation {
                    p_createTimer()
                }
            }
        }

    }
    
    private func swipeGoBack() {
        if nowIndex == 0 && !isRotation {
            return
        }
        
        nowIndex = ((nowIndex == 0 ? totalNumber : nowIndex) - 1) % totalNumber

        UIView.animate(withDuration: 0.3) { [self] in
            centerCell?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            if isStackCard {
                centerCell?.alpha = 0.6
            }
        } completion: { [self] finished in
            rightCell?.alpha = 0.0
            
            if let removeView = viewRemove, isNeedAddToCache(cell: removeView) {
                cacheViews.append(removeView)
                removeView.alpha = 1.0
                removeView.removeFromSuperview()
            }
            
            viewRemove = rightCell
            rightCell = centerCell
            centerCell = leftCell
            
            if let center = centerCell, let right = rightCell {
                insertSubview(right, belowSubview: center)
            }
            
            if let cell = delegate?.swipeView(swipe: self, index: ((nowIndex == 0 ? totalNumber : nowIndex) - 1) % totalNumber) {
                cell.removeFromSuperview()
                cell.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
                leftCell = cell
                
                if let right = rightCell {
                    insertSubview(cell, aboveSubview: right)
                }
            }
            
            centerCell?.isUserInteractionEnabled = true
            leftCell?.isUserInteractionEnabled = false
            rightCell?.isUserInteractionEnabled = false
            
            if isStackCard {
                leftCell?.alpha = 0.3
                rightCell?.alpha = 0.3
                centerCell?.alpha = 0.3
            }
            
            // 如果滑到第一个。隐藏左边试图
            if nowIndex == 0 && !isRotation {
                leftCell?.alpha = 0.0
            }else {
                leftCell?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            // 如果滑到最后一个。隐藏左边试图
            if nowIndex == totalNumber - 1 && !isRotation {
                rightCell?.alpha = 0.0
            }else {
                rightCell?.alpha = isStackCard ? 0.3 : 1.0
            }
            
            pageControl.currentPage = nowIndex
            
            UIView.animate(withDuration: 0.5) { [self] in
                centerCell?.alpha = 1.0
                centerCell?.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
                rightCell?.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
                leftCell?.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
            } completion: { [self] finished in
                if isAutoScroll && isRotation {
                    p_createTimer()
                }
            }
        }
    }
    
    private func isNeedAddToCache(cell: UITableViewCell) -> Bool {
        if cacheViews.contains(where: { $0.reuseIdentifier == cell.reuseIdentifier }) {
            return false
        }
        return true
    }
    
    private func p_createTimer() {
        p_releaseTimer()
        
        if totalNumber == 0 {
            return
        }
        
        timer = Timer(timeInterval: autoScrollTimeInterval, target: self, selector: #selector(p_timer), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    private func p_releaseTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc func p_timer() {
        swipeEnd()
    }
    //MARK: - --------------------- 私有方法 END ---------------------
    
    //MARK: - 公用方法
    func reloadData() {
        centerCell?.removeFromSuperview()
        leftCell?.removeFromSuperview()
        rightCell?.removeFromSuperview()
        viewRemove?.removeFromSuperview()
        centerCell = nil
        leftCell = nil
        rightCell = nil
        viewRemove = nil
        cacheViews.removeAll()
        
        if delegate == nil {
            return
        }
        
        guard let number = delegate?.swipeViewTotaleNumber(swipe: self) else {
            return
        }
        
        totalNumber = number
        
        if totalNumber == 0 {
            return
        }
        
        guard let nowCell = delegate?.swipeView(swipe: self, index: nowIndex) else {
            return
        }
        
        guard let nextCell = delegate?.swipeView(swipe: self, index: (nowIndex + 1) % totalNumber) else {
            return
        }
        
        guard let thirdCell = delegate?.swipeView(swipe: self, index: ((nowIndex == 0 ? totalNumber : nowIndex) - 1) % totalNumber) else {
            return
        }
        
        if let showPage = delegate?.swipeViewShowPageControl(swipe: self), showPage {
            contentHeight = bounds.size.height - 30.0
            pageControl.isHidden = !showPage
            
            pageControl.frame = CGRect(x: 0.0, y: contentHeight, width: 100, height: 30.0)
            pageControl.activeImage = activeImage
            pageControl.inactiveImage = inactiveImage
            pageControl.numberOfPages = totalNumber
            pageControl.currentPage = nowIndex
            pageControl.updateDots()
            
            if pageControl.superview == nil {
                addSubview(pageControl)
            }
        }
       
        if let spacing = delegate?.swipeViewHorizontalSpacing(swipe: self) {
            horizontalSpacing = spacing
        }
        
        if let spacing = delegate?.swipeViewVerticalSpacing(swipe: self) {
            verticalSpacing = spacing
        }
        
        if isStackCard {
            thirdCell.alpha = 0.3
            nextCell.alpha = 0.3
            nowCell.alpha = 1.0
        }
        
        thirdCell.removeFromSuperview()
        thirdCell.frame = CGRect(x: 0.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
        if nowIndex == 0 && !isRotation {
            thirdCell.alpha = 0.0
        }else {
            thirdCell.alpha = isStackCard ? 0.3 : 1.0
        }
        addSubview(thirdCell)
        leftCell = thirdCell
        
        nextCell.removeFromSuperview()
        nextCell.frame = CGRect(x: horizontalSpacing * 2.0, y: verticalSpacing, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight - verticalSpacing * 2.0)
        if nowIndex == totalNumber - 1 && !isRotation {
            nextCell.alpha = 0.0
        }else {
            nextCell.alpha = isStackCard ? 0.3 : 1.0
        }
        addSubview(nextCell)
        rightCell = nextCell
        
        nowCell.removeFromSuperview()
        nowCell.frame = CGRect(x: horizontalSpacing, y: 0.0, width: contentWidth - horizontalSpacing * 2.0, height: contentHeight)
        addSubview(nowCell)
        centerCell = nowCell
        
        if isAutoScroll && isRotation {
            p_createTimer()
        }
    }
    
    func dequeueReusableUIView(identifier: String) -> UITableViewCell? {
        if let index = cacheViews.firstIndex(where: { $0.reuseIdentifier == identifier }) {
            let cell = cacheViews[index]
            cacheViews.remove(at: index)
            return cell
        }
        return nil
    }
    //MARK: - --------------------- 公用方法 END ---------------------
}
