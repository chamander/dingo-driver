
import CoreMotion
import UIKit

final class RemoteControlViewController: UIViewController {

    // attitude.pitch = device length-ways rotation where rotating towards you is positive.
    // attitude.roll = device width-ways rotation where rotating "right" of the device is positive.

    @IBOutlet var firstLabel: UILabel!
    @IBOutlet var secondLabel: UILabel!

    private var motionManager: CMMotionManager { return .instance }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }

    override func viewDidLoad() {

        super.viewDidLoad()

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
        }
    }
}
