//
//  ViewController.swift
//  GraphingCalculator
//
//  Created by Shuo Huang on 9/9/17.
//  Copyright © 2017 Shuo Huang. All rights reserved.
//

import UIKit
import JavaScriptCore

class ViewController: UIViewController, UITextFieldDelegate, FunctionPlottingViewDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var exprTextField: UITextField!
    @IBOutlet weak var plotView: FunctionPlottingView!
    var crossHairLoc: CGPoint?
    var translation: CGPoint?
    var scale: CGFloat? = CGFloat(1.0)
    var dismiss: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        exprTextField.delegate = self
        plotView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        exprTextField.resignFirstResponder() // dismisses the keybord
        plotView.setNeedsDisplay() // tells the plot it needs to redraw
        return false // true to be the default action
    }
    
    func getFunctionToPlot() -> ((Double) -> Double)? {
        let expr = exprTextField.text
        
        if expr == "" {
            return nil
        }
        
        // JavaScript code we will execute
        let jsSrc = "log = Math.log; tan = Math.tan; sin = Math.sin; cos = Math.cos; var f = function(x) { return \( expr! ); }"
        
        // Create code and execute script, this will create the function
        // inside the context
        let jsCtx = JSContext()!
        jsCtx.evaluateScript(jsSrc)
        
        // Get a reference to the function in the context
        guard let f = jsCtx.objectForKeyedSubscript("f") else {
            return nil
        }
        
        // If the user input garbage and we can't evaluate, then exit
        if f.isUndefined {
            return nil
        }
        return {(x: Double) in return f.call(withArguments: [x]).toDouble()}
    }
    
    func getCrossHairLocation() -> CGPoint? {
        return crossHairLoc
    }
    
    func getTranslation() -> CGPoint? {
        return translation
    }
    
    func getPinchScale() -> CGFloat? {
        let s = scale
        scale = 1.0
        return s
    }
    
    func dismissCHL() -> Bool? {
        return dismiss
    }
    
    @IBAction func pinch(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .changed, .ended:
            scale = sender.scale
            //print("scale: " + String(describing: scale))
            //sender.view?.transform = (sender.view?.transform)!.scaledBy(x: sender.scale, y: sender.scale)
            plotView.setNeedsDisplay()
            //scale = 1.0

        default: break
        }
    }
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        dismiss = true
        sender.view?.setNeedsDisplay()
    }
    
    @IBAction func pan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began: fallthrough
        case .changed: fallthrough
        case .ended:
            translation = sender.translation(in: plotView)
            // update anything that depends on the pan gesture using translation.x and .y
            sender.setTranslation(CGPoint.zero, in: plotView)
            plotView.setNeedsDisplay()
        default: break
        }
    }
    
    @IBAction func tap(_ sender: UITapGestureRecognizer) {
        dismiss = false
        crossHairLoc = sender.location(in: plotView)
        plotView.setNeedsDisplay()
    }
}

