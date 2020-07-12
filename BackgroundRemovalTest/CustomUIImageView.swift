//
//  CustomImageView.swift
//  BackgroundRemovalTest
//
//  Created by Nihontabako on 2020/7/12.
//  Copyright © 2020 YHWang. All rights reserved.
//

import Foundation
import UIKit

class CustomUIImageView: UIImageView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(imageData: Data) {
        super.init(image: UIImage(data: imageData))
//        self.layer.borderWidth = 1
//        self.layer.borderColor = UIColor.red.cgColor
        
        self.isUserInteractionEnabled = true
        enableDrag()
        enableZoom()
    }
    
    var dragStartPositionRelativeToCenter : CGPoint?
}

extension CustomUIImageView {
    func enableDrag() {
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(startPanGesturing(_:))))
    }
    @objc private func startPanGesturing(_ recongnizer: UIPanGestureRecognizer!) {
        
        if recongnizer.state == UIGestureRecognizer.State.began {
            let locationInView = recongnizer.location(in: superview)
            dragStartPositionRelativeToCenter = CGPoint(x: locationInView.x - center.x, y: locationInView.y - center.y)

            layer.shadowOffset = CGSize(width: 0, height: 20)
            layer.shadowOpacity = 0.3
            layer.shadowRadius = 6

            return
        }

        if recongnizer.state == UIGestureRecognizer.State.ended {
            dragStartPositionRelativeToCenter = nil

            layer.shadowOffset = CGSize(width: 0, height: 3)
            layer.shadowOpacity = 0.5
            layer.shadowRadius = 2

            return
        }

        let locationInView = recongnizer.location(in: superview)
        UIView.animate(withDuration: 0.1) {
            self.center = CGPoint(
                x: locationInView.x - self.dragStartPositionRelativeToCenter!.x,
                y: locationInView.y - self.dragStartPositionRelativeToCenter!.y)
        }
    }
    
    func enableZoom() {
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(startZooming(_:))))
    }
    @objc private func startZooming(_ sender: UIPinchGestureRecognizer) {
        let scaleResult = sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale)
        guard let scale = scaleResult else { return }
        sender.view?.transform = scale
        sender.scale = 1
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
