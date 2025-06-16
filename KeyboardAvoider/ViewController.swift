//
//  ViewController.swift
//  KeyboardAvoider
//
//  Created by Craig Hockenberry on 6/14/25.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet var textView: UITextView!
	@IBOutlet var customInputAccessoryView: InputAccessoryView!
	@IBOutlet var accessoryBarButtonItem: UIBarButtonItem!
	@IBOutlet var responderBarButtonItem: UIBarButtonItem!
	@IBOutlet var notificationOffsetConstraint: NSLayoutConstraint!
	
	var constraintsInitialized: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		
		// NOTE: When the inputAccessoryView is assigned, the "Accessory" button is green, otherwise it's red.
		textView.inputAccessoryView = self.customInputAccessoryView
		accessoryBarButtonItem.tintColor = .systemGreen
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleWillShowOrHide), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleWillShowOrHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		coordinator.animate(alongsideTransition: nil) { [weak self] _ in
			self?.notificationOffsetConstraint.constant = self?.view.safeAreaInsets.bottom ?? 0
			self?.view.layoutIfNeeded()
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if !constraintsInitialized {
			notificationOffsetConstraint.constant = view.safeAreaInsets.bottom
			constraintsInitialized = true
		}
	}
	
	@IBAction func toggleResponder() {
		if textView.isFirstResponder {
			textView.resignFirstResponder()
		}
		else {
			textView.becomeFirstResponder()
		}
	}
	
	// NOTE: When the inputAccessoryView is assigned, the "Accessory" button is green, otherwise it's red.
	@IBAction func toggleAccessory() {
		if textView.inputAccessoryView == nil {
			textView.inputAccessoryView = self.customInputAccessoryView
			accessoryBarButtonItem.tintColor = .systemGreen
		}
		else {
			textView.inputAccessoryView = nil
			accessoryBarButtonItem.tintColor = .systemRed
		}
	}
	
	@objc func handleWillShowOrHide(_ notification: Notification) {
		// from https://developer.apple.com/videos/play/wwdc2023/10281/
		
		guard let screen = notification.object as? UIScreen else { return }
		
		guard screen.isEqual(view.window?.screen) else { return }
		
		let endFrameKey = UIResponder.keyboardFrameEndUserInfoKey
		guard let keyboardFrameEnd = notification.userInfo?[endFrameKey] as? CGRect else { return }
		
		let fromCoordinateSpace: UICoordinateSpace = screen.coordinateSpace
		let toCoordinateSpace: UICoordinateSpace = view
	
		// REGRESSION: On iOS/iPadOS 18, the coordinates are in screen coordinates
#if true
		// use screen coordinates
		let convertedKeyboardFrameEnd: CGRect = fromCoordinateSpace.convert(keyboardFrameEnd, to: toCoordinateSpace)
#else
		// REGRESSION: On iOS/iPadOS 26, the coordinates are in view coordinates
		
		// use view coordinates
		let convertedKeyboardFrameEnd = keyboardFrameEnd
#endif
		print("keyboardFrameEnd = \(keyboardFrameEnd), convertedKeyboardFrameEnd = \(convertedKeyboardFrameEnd)")
		if (convertedKeyboardFrameEnd.minX < 0) {
			// NOTE: A full width keyboard can return a minimum X value that is off the left edge of the screen.
			// This was my first clue that we are getting view coordinates here, because that negative offset is
			// the distance from the left edge of the keyboard to the left edge of the window on iPadOS.
			print("Bad clams.")
		}
		
		var bottomOffset: CGFloat = view.safeAreaInsets.bottom
		let viewIntersection = view.bounds.intersection(convertedKeyboardFrameEnd)
		
		if !viewIntersection.isEmpty {
			bottomOffset = viewIntersection.size.height
		}
		
		notificationOffsetConstraint.constant = bottomOffset
	}
}

