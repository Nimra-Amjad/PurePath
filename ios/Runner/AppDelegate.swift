import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Normalize Display Zoom
    enforceStandardMetrics()
    // Disable Dynamic Type scaling globally
    disableDynamicTypeScaling()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func enforceStandardMetrics() {
    let screen = UIScreen.main
    let nativeScale = screen.nativeScale
    let logicalScale = screen.scale
    print("Native Scale: \(nativeScale)")
    print("Logical Scale: \(logicalScale)")
    if nativeScale != logicalScale {
      let zoomFactor = nativeScale / logicalScale
      print("Display Zoom detected. Adjustment factor: \(zoomFactor)")
      adjustViewHierarchy(for: zoomFactor)
    } else {
      print("No Display Zoom detected. No adjustments needed.")
    }
  }

  private func adjustViewHierarchy(for zoomFactor: CGFloat) {
    print("Applying Display Zoom adjustment: \(zoomFactor)")
    guard let window = window else {
      print("No UIWindow found to adjust constraints.")
      return
    }
    // Adjust constraints and apply scaling
    adjustViewConstraints(view: window, factor: 1.0 / zoomFactor)
    // Apply scaling globally to the root view
    window.transform = CGAffineTransform(scaleX: 1.0 / zoomFactor, y: 1.0 / zoomFactor)
  }

  private func adjustViewConstraints(view: UIView, factor: CGFloat) {
    for constraint in view.constraints {
      constraint.constant *= factor
    }
    for subview in view.subviews {
      adjustViewConstraints(view: subview, factor: factor)
    }
  }

  private func disableDynamicTypeScaling() {
    UILabel.appearance().adjustsFontForContentSizeCategory = false
    UITextField.appearance().adjustsFontForContentSizeCategory = false
    UITextView.appearance().adjustsFontForContentSizeCategory = false
    UIButton.appearance().titleLabel?.adjustsFontForContentSizeCategory = false
    print("Dynamic Type scaling disabled globally.")
  }
}
