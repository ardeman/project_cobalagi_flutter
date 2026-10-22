import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HingeStream") {
      HingeStream.register(with: registrar)
    }
  }
}

/// Sends the hinge's status ("closed", "partiallyOpen", "fullyOpen" or
/// "unknown") to Dart on the `cobalagi/hinge` event channel, so the app can
/// keep its controls off the fold of a half-folded iPhone. iOS reports no
/// fold position: Dart places the fold across the middle of the screen.
final class HingeStream: NSObject, FlutterStreamHandler {
  private weak var registrar: FlutterPluginRegistrar?
  private var interaction: UIInteraction?

  static func register(with registrar: FlutterPluginRegistrar) {
    let stream = HingeStream()
    stream.registrar = registrar
    FlutterEventChannel(name: "cobalagi/hinge", binaryMessenger: registrar.messenger())
      .setStreamHandler(stream)
  }

  func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard #available(iOS 27.1, *), let view = registrar?.viewController?.view else { return nil }
    let interaction = UIHingeInteraction { _, update in
      events(Self.name(of: update.hinge?.status))
    }
    view.addInteraction(interaction)
    self.interaction = interaction
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    if let interaction {
      interaction.view?.removeInteraction(interaction)
    }
    interaction = nil
    return nil
  }

  @available(iOS 27.1, *)
  private static func name(of status: UIHinge.Status?) -> String {
    switch status {
    case .closed: return "closed"
    case .partiallyOpen: return "partiallyOpen"
    case .fullyOpen: return "fullyOpen"
    default: return "unknown"
    }
  }
}
