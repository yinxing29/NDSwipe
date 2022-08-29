//
//  NDTableViewCell.swift
//  NDSwipe
//
//  Created by yinxing on 2022/6/27.
//

import Foundation
import UIKit

class NDTableViewCell: UITableViewCell, NDSwipeViewDelegate {
    
    var dataSource = [UIColor.red, UIColor.orange, UIColor.purple, UIColor.green, UIColor.yellow]
    
    private let cellIdentify = "identify"

    private let ScreenWidth = UIScreen.main.bounds.size.width

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        p_initView()
    }
    
    //MARK: - init
    private func p_initView() {
        let testView = NDSwipeView(frame: CGRect(x: 20, y: 10, width: ScreenWidth - 40, height: (ScreenWidth - 40) * 290/320.0))
        testView.delegate = self
        testView.isStackCard = true
        testView.isRotation = true
        testView.isAutoScroll = true
        testView.activeImage = UIImage.image(color: .gray, size: CGSize(width: 8.0, height: 3.0), cornerRadius: 1.5)
        testView.inactiveImage = UIImage.image(color: .orange, size: CGSize(width: 8.0, height: 3.0), cornerRadius: 1.5)
        contentView.addSubview(testView)
    }
    //MARK: - --------------------- init END ---------------------
    
    func swipeView(swipe: NDSwipeView, index: Int) -> UITableViewCell {
        var cell = swipe.dequeueReusableUIView(identifier: cellIdentify) as? NDTextCell
        if cell == nil {
            cell = NDTextCell(style: .default, reuseIdentifier: cellIdentify)
        }
        cell?.bgImgaeView.backgroundColor = dataSource[index]
        return cell!
    }
    
    func swipeViewTotaleNumber(swipe: NDSwipeView) -> Int {
        return dataSource.count
    }
    
    func swipeViewShowPageControl(swipe: NDSwipeView) -> Bool {
        return true
    }
    
    func swipeView(swipe: NDSwipeView, didSelectedIndex index: Int) {
        print("----- \(index)")
    }
}

