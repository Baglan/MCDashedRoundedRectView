//
//  MCDashedRoundrectView.swift
//  MCDashedRoundrectView
//
//  Created by Baglan on 7/16/16.
//  Copyright © 2016 Mobile Creators. All rights reserved.
//

import Foundation
import UIKit

/// UIView with a dashed rounded rect outline; pattern of the dashes is adjusted to fit nicely.
@IBDesignable class MCDashedRoundedRectView: UIView {
    @IBInspectable var cornerRadius: CGFloat = 10 { didSet { setNeedsDisplay() } }
    
    @IBInspectable var strokeWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    @IBInspectable var strokeColor: UIColor? { didSet { setNeedsDisplay() } }
    
    @IBInspectable var isFilled: Bool = false { didSet { setNeedsDisplay() } }
    @IBInspectable var fillColor: UIColor? { didSet { setNeedsDisplay() } }
    
    /**
     A general way to set a pattern is to populate this array with dash/gap pattern.
     (see _UIBezierPath.setLineDash()_ for the details)
     
     The _dashPattern_ is initially populated with _firstDashSize_, _firstGapSize_,
     _secondDashSize_ and _secondGapSize_. If any of these properties is updated,
     _dashPattern_ will be re-populated with values of these properties.
     */
    var dashPattern: [CGFloat]! {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var firstDashSize: CGFloat = 3 { didSet { updateDashPatternFromInspectables() } }
    @IBInspectable var firstGapSize: CGFloat = 3 { didSet { updateDashPatternFromInspectables() } }
    @IBInspectable var secondDashSize: CGFloat = 0 { didSet { updateDashPatternFromInspectables() } }
    @IBInspectable var secondGapSize: CGFloat = 0 { didSet { updateDashPatternFromInspectables() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateDashPatternFromInspectables()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        updateDashPatternFromInspectables()
    }
    
    override func prepareForInterfaceBuilder() {
        updateDashPatternFromInspectables()
        super.prepareForInterfaceBuilder()
        
    }
    
    /**
     Replaces _dashPattern_ with the one using values from _firstDashSize_, _firstGapSize_, _secondDashSize_ and _secondGapSize_
     */
    func updateDashPatternFromInspectables() {
        dashPattern = [firstDashSize, firstGapSize, secondDashSize, secondGapSize]
    }
    
    /**
     Phase of the pattern.
     (see _UIBezierPath.setLineDash()_ for the details)
     */
    @IBInspectable var phase: CGFloat = 0 { didSet { setNeedsDisplay() } }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        // Calculate rounded rect size for drawing to avoid clipping
        let offsetFromEdge = ceil(1 + strokeWidth / 2)
        let roundedRect = CGRectMake(
            offsetFromEdge,
            offsetFromEdge,
            bounds.width - offsetFromEdge * 2,
            bounds.height - offsetFromEdge * 2
        )
        
        // Calculate corner radius to avoid overlap
        let smallerDimension = min(roundedRect.width, roundedRect.height)
        let radius = cornerRadius * 2 < smallerDimension ? cornerRadius : smallerDimension / 2
        
        // Construct the path
        
        // Using the following code would be much simpler but it overshoots in some conditions,
        // drawing a part of the line twice, which defeats the purpose of this project:
        //
        // let path = UIBezierPath(roundedRect: roundedRect, cornerRadius: radius)
        //
        // Instead, we need to reproduce the rounded rect ourselves:
        // 
        // For starters, let's calculate corrdinates for centers of rounded corners.
        // The pattern is as following:
        //   A  B
        //   D  C
        
        let pointA = CGPoint(x: roundedRect.minX + radius, y: roundedRect.minY + radius)
        let pointB = CGPoint(x: roundedRect.maxX - radius, y: roundedRect.minY + radius)
        let pointC = CGPoint(x: roundedRect.maxX - radius, y: roundedRect.maxY - radius)
        let pointD = CGPoint(x: roundedRect.minX + radius, y: roundedRect.maxY - radius)
        
        let path = UIBezierPath()
        // Start before the top left arc, drawing clockwise:
        path.moveToPoint(CGPoint(x: pointA.x - radius, y: pointA.y))
        // Top left arc:
        path.addArcWithCenter(
            pointA,
            radius: radius,
            startAngle: CGFloat(M_PI),
            endAngle: CGFloat(M_PI + M_PI / 2),
            clockwise: true
        )
        // Top segment:
        path.addLineToPoint(CGPoint(x: pointB.x, y: pointB.y - radius))
        // Top right arc:
        path.addArcWithCenter(
            pointB,
            radius: radius,
            startAngle: CGFloat(M_PI + M_PI / 2),
            endAngle: CGFloat(2 * M_PI),
            clockwise: true
        )
        // Right segment:
        path.addLineToPoint(CGPoint(x: pointC.x + radius, y: pointC.y))
        // Bottom right arc:
        path.addArcWithCenter(
            pointC,
            radius: radius,
            startAngle: 0,
            endAngle: CGFloat(M_PI / 2),
            clockwise: true
        )
        // Bottom segment:
        path.addLineToPoint(CGPoint(x: pointD.x, y: pointD.y + radius))
        // Bottom left arc:
        path.addArcWithCenter(
            pointD,
            radius: radius,
            startAngle: CGFloat(M_PI / 2),
            endAngle: CGFloat(M_PI),
            clockwise: true
        )
        path.closePath()
        
        // Fill the path if necessary
        if let fillColor = fillColor where isFilled {
            fillColor.setFill()
            path.fill()
        }
        
        // Stroke the path
        if let strokeColor = strokeColor {
            path.lineWidth = strokeWidth
            
            // Dash and gap pattern
            let pathLength = CGFloat(M_PI) * radius * 2 + roundedRect.width * 2 + roundedRect.height * 2 - radius * 8
            let patternLength = dashPattern.reduce(0) { (sum, value) -> CGFloat in return sum + value }
            if patternLength != 0 {
                let numberOfPatterns = Int(round(pathLength / patternLength))
                let stretchRatio = pathLength / (patternLength * CGFloat(numberOfPatterns))
                let finalPattern = dashPattern.map { (value) -> CGFloat in return value * stretchRatio }
                path.setLineDash(finalPattern, count: finalPattern.count, phase: phase)
            }
            
            strokeColor.setStroke()
            path.stroke()
        }
    }
}