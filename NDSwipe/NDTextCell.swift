//
//  NDTextCell.swift
//  NDSwipe
//
//  Created by yinxing on 2022/6/24.
//

import Foundation
import UIKit

class NDTextCell: UITableViewCell {
    
    lazy var bgImgaeView: UIImageView = {
        let img = UIImageView(frame: .zero)
        img.contentMode = .scaleAspectFill
        img.clipsToBounds = true
        img.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth, .flexibleRightMargin, .flexibleTopMargin, .flexibleHeight, .flexibleBottomMargin]
        return img
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 10.0
        contentView.addSubview(bgImgaeView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgImgaeView.frame = contentView.bounds
    }
}
