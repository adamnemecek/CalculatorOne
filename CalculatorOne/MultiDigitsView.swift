//
//  MultiDigitView.swift
//  CalculatorOne
//
//  Created by Andreas on 28/12/2016.
//  Copyright © 2016 Kitt Peak. All rights reserved.
//

import Cocoa

protocol MultiDigitViewDelegate
{
    func userEventShouldSetValue(_ value: Int) -> Bool
}

/// Displays multiple digits (0 to F, point, minus) in a vertical scroll view, allows the user to change the digit by scrolling
class MultiDigitsView: BaseView, DigitViewDelegate
{
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    private var digitViews: [DigitView]!

    @IBInspectable var countViews: Int = 20
    
    private let xDigitSpacing: CGFloat = 1.0
    var constantSize: CGSize   = CGSize(width: 0, height: 0)
    
    var delegate: MultiDigitViewDelegate?
    
    var allowsValueChangesByUI: Bool = false
    
    // represents the digit shown in the view
    var value: Int? = nil
    { didSet 
        { 
            updateViews(value: value)
        }
    }
    
    var radix: Int = 10
    { didSet 
        { 
            configureViewForRadix(radix)
            updateViews(value: value)
        }
    }
            
    var digitValue: Int? { return nil }
    
    convenience init(countDigits: Int, kind: DigitView.Kind, origin: CGPoint)
    {
        
        self.init(frame: NSRect(origin: origin, size: CGSize.zero))
        
        countViews = countDigits
    }
    
    private override init(frame frameRect: NSRect)
    {
        let newFrame: CGRect = CGRect(origin: frameRect.origin, size: constantSize)
        super.init(frame: newFrame)
        
        completeInitWithRect(frameRect: newFrame)
    }
    
    required init?(coder: NSCoder)
    {
        //let frameRect = CGRect.zero
        //let newFrame: CGRect = CGRect(origin: frameRect.origin, size: DigitView.constantSize)
        super.init(coder: coder)
        
    }
    
    override func awakeFromNib() 
    {
        super.awakeFromNib()
        
        constantSize.width = CGFloat(countViews) * (xDigitSpacing + DigitView.constantSize.width)
        constantSize.height = DigitView.constantSize.height
        
        widthConstraint.constant = constantSize.width

        let newFrame: CGRect = CGRect(origin: self.frame.origin, size: DigitView.constantSize)

        completeInitWithRect(frameRect: newFrame)
    }
    
    private func completeInitWithRect(frameRect: NSRect, kind: DigitView.Kind = DigitView.Kind.courierStyle)
    {
        constantSize.width = CGFloat(countViews) * (xDigitSpacing + DigitView.constantSize.width)
        constantSize.height = DigitView.constantSize.height

        wantsLayer = true
        layer?.backgroundColor = CGColor.clear
        
        digitViews = [DigitView]()
        
        for viewIndex: Int in 0 ..< countViews
        {
            let origin: CGPoint = CGPoint(x: CGFloat(countViews - viewIndex - 1) * (DigitView.constantSize.width + xDigitSpacing), 
                                          y: 0.0)
            let digitView = DigitView(kind: kind, origin: origin)
        
            // allow the digit view to delegate events up to this class
            digitView.delegate = self
            
            digitViews.append(digitView)
    
            self.addSubview(digitView)
        }  
    }
    
    
    func resetToZero()
    {
        value = 0
    }
    
    func configureViewForRadix(_ radix: Int)
    {
        for digitView in digitViews
        {
            digitView.configureForRadix(radix)
        }
        
    }
    
    func updateViews(value: Int?) 
    {
        if value == nil
        {
            for digitView in digitViews
            {
                digitView.setDigit(.blank, animated: true)
            }
            
            return 
        }
        
        var digitValue: Int = abs(value!)
        var index: Int = 0
        
        if digitValue == 0
        {
            self.setDigit(.d0, index: 0, animated: true)
            index += 1
        }
        
        while digitValue > 0 
        {
            self.setDigit(value: digitValue % radix, index: index, animated: true)
            digitValue = digitValue / radix  
            index += 1
        }
        
        if value! < 0
        {
            self.setDigit(.minus, index: index, animated: true)
            index += 1
        }
        
        for i in index ..< countViews
        {
            self.setDigit(.blank, index: i, animated: true)
        }
        
//        for i: Int in 0 ..< countViews
//        {
//            self.setDigit(value: digitValue % radix, index: i, animated: true)
//            digitValue = digitValue / radix
//        }
    }
    
//    private func scrollToDigit(_ digit: Digit, animated: Bool)
//    {
//        
//    }
//    
    func setDigit(_ digit: Digit, index: Int, animated: Bool)
    {
        digitViews[index].setDigit(digit, animated: animated)
    }
    
    func setDigit(value: Int, index: Int, animated: Bool)
    {
        digitViews[index].setDigit(value: value, animated: animated)
    }
    
    
    func userEventShouldSetDigit(_ digit: Digit, fromView: DigitView) -> Bool 
    {
        guard allowsValueChangesByUI == true else { return false }
        
        // the user updated one digit in the multi-digit view. 
        // the index of that digit is:
        if let indexOfUpdatedDigit = digitViews.index(of: fromView)
        {
            //TODO: this patch is no good.
            if value == nil
            {
                value = 0
            }
            
            let newValue: Int = Engine.valueWithDigitReplaced(value: value!, digitIndex: indexOfUpdatedDigit, newDigitValue: digit.rawValue, radix: radix)
                        
            if delegate?.userEventShouldSetValue(newValue) == true
            {
                value = newValue
            }
        }
        else
        {
            assertionFailure("! Failure: digit view \(fromView) was not found in the digitview array of \(self)")
        }
        
        return true
    }
    
}
