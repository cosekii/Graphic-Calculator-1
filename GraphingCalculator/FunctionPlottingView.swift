//
//  FunctionPlottingView.swift
//  GraphingCalculator
//
//  Created by Shuo Huang on 9/9/17.
//  Copyright © 2017 Shuo Huang. All rights reserved.
//

import UIKit

protocol FunctionPlottingViewDelegate {
    func getFunctionToPlot() -> ((Double) -> Double)?
    func getCrossHairLocation() -> CGPoint?
    func getTranslation() -> CGPoint?
    func getPinchScale() -> CGFloat?
    func dismissCHL() -> Bool?
}

class FunctionPlottingView: UIView {
    
    var delegate : FunctionPlottingViewDelegate?
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    var funcLabel : UILabel? = nil
    var xMin = -1.1
    var xMax =  1.1
    //var yMax = -2.0
    //var yMin =  2.0
    var origin = CGPoint.zero
    var dismissCHL = false
    var scale = CGFloat(-1.0)
    
    
    override func draw(_ rect: CGRect) {
        if funcLabel == nil {
            funcLabel = UILabel()
            funcLabel?.frame = CGRect(x: 0, y: 0, width: 150, height: 30)
            self.addSubview(funcLabel!)
        }
        
        let delta = (xMax - xMin) / 100.0
        if scale < 0.0 {
            scale = bounds.width / CGFloat(xMax - xMin)
        }

        if let s = self.delegate?.getPinchScale() {
            print("scaled by: " + String(describing: s))
            scale *= s
        }
        else {
            scale = bounds.width / CGFloat(xMax - xMin)
        }
        
        var T = CGAffineTransform.identity
        T = T.translatedBy(x: rect.midX, y: rect.midY)
        T = T.scaledBy(x: scale, y: -scale)
        let T_inv = T.inverted()
        
        if let trans = self.delegate?.getTranslation() {
            print("moved to: " + String(describing: trans))
            let xDiff = trans.x / scale
            let yDiff = trans.y / scale
            xMin -= Double(xDiff)
            xMax -= Double(xDiff)
            //yMin -= Double(yDiff)
            //yMax -= Double(yDiff)
            origin = CGPoint(x: origin.x + xDiff, y: origin.y - yDiff)
            print("xMin: " + String(xMin) + " xMax: " + String(xMax))
            print("origin x:" + String(describing: origin.x) + " y: " + String(describing: origin.y))
        }
        
        var path = UIBezierPath()
        var function:((Double) -> Double)? = nil
        UIColor.lightGray.setStroke()
        
        path.lineWidth = 2
        
        let ori = origin.applying(T)

        path.move(to: CGPoint(x: rect.minX, y: ori.y))
        path.addLine(to: CGPoint(x: rect.maxX, y: ori.y))
        path.stroke()
        
        path.move(to: CGPoint(x: ori.x, y: rect.minY))
        path.addLine(to: CGPoint(x: ori.x, y: rect.maxY))
        path.stroke()

        
        // draw function
        path = UIBezierPath()
        //path.apply(T)
        //let f = {(x: Double) -> Double in x * x}
        
        
        
        if let f = self.delegate?.getFunctionToPlot() {
            function = f
            var validY = false
            let xMinPoint = CGPoint(x: rect.minX, y: ori.y)
            let xMaxPoint = CGPoint(x: rect.maxX, y: ori.y)
            let start = Double(xMinPoint.applying(T_inv).x) + xMin
            let end = Double(xMaxPoint.applying(T_inv).x) + xMax
            for x in stride(from: start , to: end, by: delta) {
                let y = function!(x)
                if y.isNormal || y.isZero {
                    let p = CGPoint(x: x + Double(origin.x), y: y + Double(origin.y))
                    if validY == false {
                        path.move(to: p)
                        validY = true
                    }
                    path.addLine(to:p.applying(T))
                }
                else {
                    validY = false
                }
            }
            
            UIColor.red.setStroke()
            path.lineWidth = 2.0
            path.stroke()
        }
        
        if let msg = self.delegate?.dismissCHL() {
            dismissCHL = msg;
            funcLabel?.isHidden = true
        }
        
        path = UIBezierPath()
        if dismissCHL == false, let pnt = self.delegate?.getCrossHairLocation() {

            let x_val = Double(pnt.applying(T_inv).x - origin.x)
            if let y = function?(x_val) {
                if y.isNormal || y.isZero {
                    let p = CGPoint(x: x_val + Double(origin.x), y: y + Double(origin.y))
                    path = UIBezierPath()
                    UIColor.lightGray.setStroke()
                    
                    path.move(to: CGPoint(x:rect.minX, y:p.applying(T).y))
                    path.addLine(to: CGPoint(x:rect.maxX, y:p.applying(T).y))
                    path.move(to: CGPoint(x:p.applying(T).x, y:rect.minY))
                    path.addLine(to: CGPoint(x:p.applying(T).x, y:rect.maxY))
                    
                    let dash: [CGFloat] = [4.0, 8.0]
                    path.setLineDash(dash, count: dash.count, phase: 1.0)
                    path.stroke()
                    
                    funcLabel?.isHidden = false
                    funcLabel?.frame.origin.x = p.applying(T).x
                    funcLabel?.frame.origin.y = p.applying(T).y
                        
                    funcLabel?.text = "(x = " + String(format: "%.1f", x_val) +  ", y = " + String(format: "%.1f", y) + ")"
                    funcLabel?.numberOfLines = 1
                    
                    let y_diff = (function?(x_val + delta))! - y
                    
                    let path = UIBezierPath()
                    let xMinPoint = CGPoint(x: rect.minX, y: ori.y)
                    let xMaxPoint = CGPoint(x: rect.maxX, y: ori.y)
                    let start = Double(xMinPoint.applying(T_inv).x) + xMin
                    let end = Double(xMaxPoint.applying(T_inv).x) + xMax
                    
                    let rightEnd = CGPoint(x: end + Double(origin.x), y: y + (end - x_val) / delta * y_diff + Double(origin.y))
                    path.move(to:rightEnd.applying(T))
                    let leftEnd = CGPoint(x: start  + Double(origin.x), y: y - (x_val - start) / delta * y_diff + Double(origin.y))
                    path.addLine(to:leftEnd.applying(T))
                    UIColor.purple.setStroke()
                    path.lineWidth = 2.0
                    path.stroke()
                    
                }
            }
        }
        
    }
    
    
}
