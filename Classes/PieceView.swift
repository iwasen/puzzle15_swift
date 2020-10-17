//
//  PieceView.swift
//  puzzle15_pic
//
//  Created by 相沢伸一 on 2020/01/27.
//

import UIKit

protocol PieceViewDelegate {
    func touchPiece(pieceNo: Int)
}

class PieceView: UIImageView {
    public var pieceNo: Int!
    public var delegate: PieceViewDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.touchPiece(pieceNo: pieceNo)
    }
}
