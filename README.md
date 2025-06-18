# KeyboardAvoider

A sample app that demonstrates the issues with the software and hardware keyboard on iOS 26.

The **red bar** shows issues with the **Keyboard Layout Guide**.

The **orange bar** shows issues with the **keyboard frame notifications**.

This app was submitted with the following feedback:

## FB18129544 - REGRESSION: iOS 26: Keyboard layout frame is reported in view coordinates, not screen coordinates.

On iPadOS, the UIResponder.keyboardWillShowNotification and UIResponder.keyboardWillHideNotification notifications report a UIResponder.keyboardFrameEndUserInfoKey in view coordinates, not screen coordinates as it did in iPadOS 18 and as it should per the documentation.

This issue is triggered when an inputAccessoryView is used with a UITextView.

The issue is demonstrated with the attached sample project. The orange bar uses a layout constraint that is derived from keyboard frame notification (using the code from "Keep up with the keyboard" at WWDC23). The orange bar should be aligned with the top of the on-screen keyboard.

To verify that view coordinates are used, change the "true" conditional compilation in handleWillShowOrHide() to "false". When the conversion from screen to view coordinates is disabled, the orange bar moves correctly.

## FB18129551 - REGRESSION: iOS 26: Keyboard Layout Guide is unpredictable

The keyboard layout guide is unpredictable on iOS 26 when an inputAccessoryView is used. In the following screenshots, the red bar shows the top of the Keyboard Layout Guide constraint.

The following conditions have been observed and are included as screenshots:

1. On launch, the layout guide is placed above an inputAccessoryView the first time a UITextView becomes the first responder.

![1 - iPadOS - first launch.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/1%20-%20iPadOS%20-%20first%20launch.png)

2. On interactive dismiss, the layout guide is placed above the safe area after the dismiss completes. Additionally, the guide jumps around during the dismiss. Additionally, the misplacement offset depends on whether the device is in a horizontal or portrait orientation.

![2 - iPadOS - interactive dismiss.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/2%20-%20iPadOS%20-%20Interactive%20dismiss.png)

![2 - iOS - interactive dismiss.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/2%20-%20iOS%20-%20interactive%20dismiss.png)

![2 - iOS - interactive dismiss landscape.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/2%20-%20iOS%20-%20interactive%20dismiss%20landscape.png)

3. With a hardware keyboard connected, the layout guide is underneath the inputAccessoryView when the UITextView becomes the first responder.

![3 - iPadOS - hardware keyboard responder.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/3%20-%20iPadOS%20-%20hardware%20keyboard%20responder.png)

4. With a hardware keyboard connected, the layout guide is well above the safe area  when the UITextView resigns the first responder.

![4 - iPadOS - hardware keyboard not responder.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/4%20-%20iPadOS%20-%20hardware%20keyboard%20not%20responder.png)

5. With a software keyboard with an inputAccessoryView, the layout guide is underneath the inputAccessoryView that's attached to the bottom of the window.

![5 - iPadOS - no intersection.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129551/5%20-%20iPadOS%20-%20no%20intersection.png)

There are probably more, but here's the gist: it's pretty broken.

The results can be reproduced with the attached sample project.

## FB18129558 - REGRESSION: iOS 26: Keyboard Layout Guide can't handle changes to inputAccessoryView

When an inputAccessoryView is added to a UITextView, presented with becomeFirstResponder, and then removed afterwards, the Keyboard Layout Guide will be placed underneath the keyboard with the next becomeFirstResponder.

Adding and removing the inputAccessoryView is necessary when the accessories are needed for normal text editing, but not needed for the same view's findInteraction. For example, a button to set a text attribute makes sense for rich text, but not the plain text of a search string.

The results can be reproduced with the attached sample project:

1. Launch the app
2. Press the Responder button (to become first responder with an accessory view)
3. Press the Responder button again
4. Press the Accessory button to remove the accessory view (text will become red)
5. Press the Responder button

Screenshots of the results on iOS are attached.

![Toggle accessory - portrait.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129558/Toggle%20accessory%20-%20portrait.png)

![Toggle accessory - landscape.png](https://github.com/chockenberry/KeyboardAvoider/blob/main/FB18129558/Toggle%20accessory%20-%20landscape.png)

## FB18184281 - iOS26: Keyboard Layout Guide does not update when window is dragged behind keyboard

The keyboard layout guide does not update when a window that contains the view with the layout guide is moved behind the keyboard. See the attached video.

To reproduce this issue, get the app from the GitHub repo.

The red rectangle is the view that's constrained to the keyboard layout guide.

[Video](https://github.com/chockenberry/KeyboardAvoider/tree/main/FB18184281)


