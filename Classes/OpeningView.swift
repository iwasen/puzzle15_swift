//
//  OpeningView.swift
//  puzzle15_pic
//
//  Created by 相沢伸一 on 2020/01/27.
//

import UIKit

protocol OpeningViewDelegate {
    func touchOpeningView()
}

class OpeningView: UIView {
    public var delegate: OpeningViewDelegate?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchOpeningView()
    }
}
