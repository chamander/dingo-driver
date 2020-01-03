
import CoreMotion
import MQTTClient
import UIKit

final class RemoteControlViewController: UIViewController {

    // attitude.pitch = device length-ways rotation where rotating towards you is positive.
    // attitude.roll = device width-ways rotation where rotating "right" of the device is positive.

    @IBOutlet private var firstLabel: UILabel!
    @IBOutlet private var secondLabel: UILabel!

    private var session: MQTTSession!

    var connection: Connection?

    private enum Segue {

        case unwindToConnectionList

        var identifier: String {
            switch self {
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
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, error in

            guard let self = self else { return }

            let normalizedPitch: Double = motion.map { $0.attitude.pitch * 2 / .pi } ?? 0.0
            let normalizedRoll: Double = motion.map { $0.attitude.roll * 2 / .pi } ?? 0.0

            self.firstLabel?.text = "Pitch: \(String(describing: normalizedPitch))"
            self.secondLabel?.text = "Roll: \(String(describing: normalizedRoll))"

            self.session.publishData(
                "throttle:\(normalizedPitch)".data(using: .utf8),
                onTopic: connection.topic,
                retain: false,
                qos: .atLeastOnce)
            self.session.publishData(
                "steering:\(normalizedRoll)".data(using: .utf8),
                onTopic: connection.topic,
                retain: false,
                qos: .atLeastOnce)
        }
    }
}
