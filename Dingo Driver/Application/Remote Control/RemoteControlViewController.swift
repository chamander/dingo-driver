
import CoreMotion
import UIKit

final class RemoteControlViewController: UIViewController {

    // attitude.pitch = device length-ways rotation where rotating towards you is positive.
    // attitude.roll = device width-ways rotation where rotating "right" of the device is positive.

    @IBOutlet private var firstLabel: UILabel!
    @IBOutlet private var secondLabel: UILabel!

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

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)

        if self.motionManager.isDeviceMotionAvailable {

            self.motionManager.deviceMotionUpdateInterval = 0.5
            self.motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { motion, error in

                let normalizedPitch: Double? = motion.map { $0.attitude.pitch * 2 / .pi }
                let normalizedRoll: Double? = motion.map { $0.attitude.roll * 2 / .pi }

                self.firstLabel?.text =
                    "Pitch: \(normalizedPitch.map { String(describing: $0) } ?? "" )"
//                    "Pitch: \(motion.map { String(describing: $0.attitude.pitch) } ?? "" )"
                self.secondLabel?.text =
                    "Roll: \(normalizedRoll.map { String(describing: $0) } ?? "" )"
//                    "Roll: \(motion.map { String(describing: $0.attitude.roll) } ?? "" )"
            }
        } else {

            let alert = UIAlertController(
                title: "Motion is not available on this device",
                message: "Remote control requires access to both a accelorometer, and a gyroscope. It does not look like both are currently available.",
                preferredStyle: .alert)

            let okay = UIAlertAction(
                title: "Dismiss",
                style: .default) { _ in
                    self.perform(.unwindToConnectionList, sender: self)
                }

            alert.addAction(okay)
            self.present(alert, animated: true)
        }
    }
}
