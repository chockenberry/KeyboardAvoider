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
	@IBOutlet var keyboardLayoutGuideConstraint: NSLayoutConstraint!
	@IBOutlet var attachedView: UIView!
	
	var layoutInitialized: Bool = false
	var keyboardOffset: CGFloat = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		var dummyText = "START\n\n"
		for _ in 0..<10 {
			dummyText += """
	Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\n\n
	"""
		}
		dummyText += "END"
		textView.text = dummyText
		
		/*
		 /// Defaults to @c YES. When the keyboard is offscreen, the layout guide is tied to the bottomAnchor of the view's safeAreaLayoutGuide. Set this to @c NO to instead have the guide use the bottomAnchor of the view.
		 @property (nonatomic, readwrite) BOOL usesBottomSafeArea API_AVAILABLE(ios(17.0));

		 /// Defaults to 0.0. When a user scrolls to dismiss the keyboard (see @c UIScrollViewKeyboardDismissMode), the gesture waits to start the dismiss until it intersects with the keyboard. This adds padding above the keyboard to start the dismiss earlier. Negative values will be treated as 0.
		 @property (nonatomic, readwrite) CGFloat keyboardDismissPadding API_AVAILABLE(ios(17.0));
		 */
		
		self.view.keyboardLayoutGuide.usesBottomSafeArea = true
		self.view.keyboardLayoutGuide.keyboardDismissPadding = attachedViewHeight
		
		textView.contentInsetAdjustmentBehavior = .scrollableAxes
		
		// NOTE: When the inputAccessoryView is assigned, the "Accessory" button is green, otherwise it's red.
		textView.inputAccessoryView = self.customInputAccessoryView
		accessoryBarButtonItem.tintColor = .systemGreen
		
		textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleWillShowOrHide), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleWillShowOrHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		
		print("viewSafeAreaInsetsDidChange: safeAreaInsets = \(view.safeAreaInsets)")
		textView.flashScrollIndicators()
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		coordinator.animate(alongsideTransition: nil) { [weak self] _ in
			print("viewWillTransition: size = \(size), bottom = \(self?.view.safeAreaInsets.bottom ?? 0)")
			self?.notificationOffsetConstraint.constant = self?.view.safeAreaInsets.bottom ?? 0
			self?.view.layoutIfNeeded()
		}
	}

	let attachedViewHeight: CGFloat = 44.0 // laziness
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if !layoutInitialized {
			notificationOffsetConstraint.constant = view.safeAreaInsets.bottom
			
			//var textViewInset: CGFloat = 0 //textView.adjustedContentInset.bottom

#if false
			// contentInsets: Never
			textView.contentOffset.y = -view.safeAreaInsets.top
			textView.contentInset.top = view.safeAreaInsets.top
			textView.contentInset.bottom = view.safeAreaInsets.bottom + attachedViewHeight
			textView.verticalScrollIndicatorInsets.bottom = attachedViewHeight
#else
			// contentInsets: Scrollable Axes
			textView.contentInset.bottom = attachedViewHeight
			textView.verticalScrollIndicatorInsets.bottom = attachedViewHeight
#endif
			print("viewDidLayoutSubviews: textViewInset = \(textView.contentInset.bottom), scrollIndicatorInset = \(textView.verticalScrollIndicatorInsets.bottom)")

			layoutInitialized = true
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
		print("handleWillShowOrHide: keyboardFrameEnd = \(keyboardFrameEnd), convertedKeyboardFrameEnd = \(convertedKeyboardFrameEnd)")
		if (convertedKeyboardFrameEnd.minX < 0) {
			// NOTE: A full width keyboard can return a minimum X value that is off the left edge of the screen.
			// This was my first clue that we are getting view coordinates here, because that negative offset is
			// the distance from the left edge of the keyboard to the left edge of the window on iPadOS.
			print("Bad clams.")
		}
		
		var isUsingScreenCoordinates = false
		var intersectingView = false
		var isKeyboardShowing = viewIntersection.size.height > 0
		

		keyboardOffset = view.safeAreaInsets.bottom
		let viewIntersection = view.bounds.intersection(convertedKeyboardFrameEnd)
		var keyboardLayoutOffset: CGFloat = attachedViewHeight // actually the height of the accessory, but we don't know that
		
#if false
		// contentInsets: Never
		var textViewInset: CGFloat = view.safeAreaInsets.bottom + attachedViewHeight
		var scrollIndicatorInset: CGFloat = attachedViewHeight

		if !viewIntersection.isEmpty {
			bottomOffset = viewIntersection.size.height
			textViewInset = viewIntersection.size.height + attachedViewHeight
		}
#else
		// contentInsets: Scrollable Axes
		var textViewInset: CGFloat = attachedViewHeight
		var scrollIndicatorInset: CGFloat = attachedViewHeight

		if !viewIntersection.isEmpty {
			intersectingView = true
			
			keyboardOffset = viewIntersection.size.height
			textViewInset = keyboardOffset + attachedViewHeight - view.safeAreaInsets.bottom
			scrollIndicatorInset = keyboardOffset + attachedViewHeight - view.safeAreaInsets.bottom
		}
#endif

		print("handleWillShowOrHide: keyboardOffset = \(keyboardOffset), textViewInset = \(textViewInset), scrollIndicatorInset = \(scrollIndicatorInset)")


		
		textView.contentInset.bottom = textViewInset
		textView.verticalScrollIndicatorInsets.bottom = scrollIndicatorInset
		textView.flashScrollIndicators()

#if false
		/* keyboardLayoutGuideConstraint.firstItem?.layoutFrame =
		Optional<CGRect>
		  ▿ some : (0.0, 819.0, 820.0, 313.0)
			▿ origin : (0.0, 819.0)
			  - x : 0.0
			  - y : 819.0
			▿ size : (820.0, 313.0)
			  - width : 820.0
			  - height : 313.0
		*/
		if #available(iOS 26.0, *) {
			if UIDevice.current.userInterfaceIdiom == .pad {
				keyboardLayoutGuideConstraint.constant = keyboardLayoutOffset
			}
			else {
				keyboardLayoutGuideConstraint.constant = 0
			}
		}
		else {
			if UIDevice.current.userInterfaceIdiom == .pad {
				keyboardLayoutGuideConstraint.constant = keyboardLayoutOffset
			}
			else {
				keyboardLayoutGuideConstraint.constant = 0
			}
		}
#endif
		
		notificationOffsetConstraint.constant = keyboardOffset
	}
}

