
import CoreMotion
import MQTTClient
import UIKit

final class RemoteControlViewController: UIViewController {

    // attitude.pitch = device length-ways rotation where rotating towards you is positive.
    // attitude.roll = device width-ways rotation where rotating "right" of the device is positive.

    @IBOutlet private var firstLabel: UILabel!
    @IBOutlet private var secondLabel: UILabel!

    private var session: MQTTSession!

    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.underlyingQueue = .global(qos: .userInitiated)
        return queue
    }()

    private var isPaused: Bool = false

    private var currentSessionSettings: RemoteControlSessionSettings?

    var connection: Connection?

    private enum Segue {

        case unwindToConnectionList
        case remoteControlSessionSettings

        init?(_ segue: UIStoryboardSegue) {
            switch segue.identifier {
            case "remoteControlSessionSettings"?:
                self = .remoteControlSessionSettings
            case "remoteControlUnwindToSessionList"?:
                self = .unwindToConnectionList
            default:
                return nil
            }
        }

        var identifier: String {
            switch self {
            case .remoteControlSessionSettings:
                return "remoteControlSessionSettings"
            case .unwindToConnectionList:
                return "remoteControlUnwindToSessionList"
            }
        }
    }

    private func perform(_ segue: Segue, sender: Any?) {
        self.performSegue(withIdentifier: segue.identifier, sender: sender)
    }

    private var motionManager: CMMotionManager { return .instance }

    deinit {
        self.session?.disconnect()
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        guard let connection = self.connection else {
            let alert = UIAlertController(
                title: "Internal Error",
                message: "Remote control was not provided a 'Connection' to attempt.",
                preferredStyle: .alert)
            let dismiss = UIAlertAction(
                title: "Dismiss",
                style: .default) { _ in
                    self.perform(.unwindToConnectionList, sender: self)
            }
            alert.addAction(dismiss)
            self.present(alert, animated: true)
            return
        }

        guard self.motionManager.isDeviceMotionAvailable else {
            let alert = UIAlertController(
                title: "Motion is not available on this device",
                message: "Remote control requires access to both a accelorometer, and a gyroscope. It does not look like both are currently available.",
                preferredStyle: .alert)
            let dismiss = UIAlertAction(
                title: "Dismiss",
                style: .default) { _ in
                    self.perform(.unwindToConnectionList, sender: self)
                }
            alert.addAction(dismiss)
            self.present(alert, animated: true)
            return
        }

        let transport = MQTTCFSocketTransport()
        transport.host = connection.hostname

        // Framework provides its own init w/o nullability annotations, so
        // provide implicitly unwrapped type annotation for frictionless access.
        let session: MQTTSession! = MQTTSession()
        session.transport = transport
        session.connect()

        self.session = session

        self.motionManager.deviceMotionUpdateInterval = 0.5
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: self.operationQueue) { [weak self] motion, error in

            guard let self = self else { return }

            let throttle: String
            let steering: String

            if let settings = self.currentSessionSettings {

                switch settings.throttleSelection {
                case .userControlled:
                    let throttleValue: Double = .adjustedValue(fromRawDeviceValue: motion?.attitude.roll ?? 0.0)
                    throttle = String(describing: throttleValue)
                case let .constant(value):
                    throttle = String(describing: value)
                case .automatic:
                    throttle = "auto"
                }

                switch settings.steeringSelection {
                case .userControlled:
                    let steeringValue: Double = .adjustedValue(fromRawDeviceValue: motion?.attitude.pitch ?? 0.0)
                    steering = String(describing: steeringValue)
                case let .constant(value):
                    steering = String(describing: value)
                case .automatic:
                    steering = "auto"
                }
            } else {

                let throttleValue: Double = .adjustedValue(fromRawDeviceValue: motion?.attitude.roll ?? 0.0)
                throttle = String(describing: throttleValue)

                let steeringValue: Double = .adjustedValue(fromRawDeviceValue: motion?.attitude.pitch ?? 0.0)
                steering = String(describing: steeringValue)
            }

            DispatchQueue.main.async {
                self.firstLabel?.text = "Throttle: \(throttle)"
                self.secondLabel?.text = "Steering: \(steering)"
            }

            if !self.isPaused {
                self.session.publishData(
                    "throttle:\(throttle)".data(using: .utf8),
                    onTopic: connection.topic,
                    retain: false,
                    qos: .atLeastOnce)
                self.session.publishData(
                    "steering:\(steering)".data(using: .utf8),
                    onTopic: connection.topic,
                    retain: false,
                    qos: .atLeastOnce)
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.isPaused = true
        switch Segue(segue) {
        case .unwindToConnectionList?, nil:
            break
        case .remoteControlSessionSettings?:
            if
                let settings = self.currentSessionSettings,
                let controller = segue.destination as? RemoteControlSessionSettingsNavigationController {

                controller.settingsController.currentSelection = settings
            }
        }
    }

    @IBAction private func remoteControlSessionSettingsUnwindToRemoteControl(_ unwindSegue: UIStoryboardSegue) {
        self.isPaused = false
        switch unwindSegue.source {
        case let controller as RemoteControlSessionSettingsTableViewController:
            self.currentSessionSettings = controller.currentSelection
        default:
            break
        }
    }
}

private extension Double {

    private static let minimumPositiveAngle: Double = .pi / 20
    private static let maximumNegativeAngle: Double = -.minimumPositiveAngle

    private static let maximumPositiveAngle: Double = .pi / 2
    private static let minimumNegativeAngle: Double = -.maximumPositiveAngle

    // Expecting that the device's raw value is in radians.
    static func adjustedValue(fromRawDeviceValue value: Double) -> Double {

        // Values are all between 0 and ±π.

        if value > .zero {

            // Provide (π / 20) of give, zero-ing values between 0c and (π / 20).
            if value < .minimumPositiveAngle {
                return .zero
            }

            // Maximise values at (π / 2). Anything larger returns maximum value.
            if value > .maximumPositiveAngle {
                return 1.0
            }

            // Value is between (π / 20) and (π / 2).
            // Normalise between 0.0 and 1.0.
            let scaled = value - .minimumPositiveAngle
            let normalized = scaled / (.maximumPositiveAngle - .minimumPositiveAngle)
            return normalized

        } else if value < .zero {

            // Provide (π / 20) of give, zero-ing values between -(π / 20) and 0c.
            if value > .maximumNegativeAngle {
                return .zero
            }

            // Maximise negative values at -(π / 2). Anything more negative returns minimum value.
            if value < .minimumNegativeAngle {
                return -1.0
            }

            // Value is between -(π / 2) and -(π / 20).
            // Normalise between -1.0 and -0.0.
            let scaled = value - .maximumNegativeAngle
            let normalized = scaled / (.maximumNegativeAngle - .minimumNegativeAngle)
            return normalized

        } else {
            return .zero
        }
    }
}
