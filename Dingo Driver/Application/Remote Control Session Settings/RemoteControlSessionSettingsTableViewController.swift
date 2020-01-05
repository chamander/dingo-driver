
import UIKit

struct RemoteControlSessionSettings {

    var throttleSelection: Selection
    var steeringSelection: Selection

    enum Selection {

        // Both switches off.
        case userControlled

        case automatic
        case constant(Double)
    }
}

final class RemoteControlSessionSettingsNavigationController: UINavigationController {

    var settingsController: RemoteControlSessionSettingsTableViewController! {
        return self.viewControllers.first as? RemoteControlSessionSettingsTableViewController
    }
}

final class RemoteControlSessionSettingsTableViewController: UITableViewController {

    @IBOutlet private var throttleAutomaticSwitch: UISwitch!
    @IBOutlet private var throttleConstantSwitch: UISwitch!
    @IBOutlet private var throttleConstantSlider: UISlider!
    @IBOutlet private var throttleConstantLabel: UILabel!

    @IBOutlet private var steeringAutomaticSwitch: UISwitch!
    @IBOutlet private var steeringConstantSwitch: UISwitch!
    @IBOutlet private var steeringConstantSlider: UISlider!
    @IBOutlet private var steeringConstantLabel: UILabel!

    var currentSelection = RemoteControlSessionSettings(
        throttleSelection: .userControlled,
        steeringSelection: .userControlled)

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let toggleableRow = ToggleableRow(indexPath) {
            self.toggle(toggleableRow)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set the selection prior to showing the view to show default values.
        self.setSelection(self.currentSelection, animated: false)
    }

    private func setSelection(_ selection: RemoteControlSessionSettings, animated: Bool) {

        switch selection.throttleSelection {
        case .automatic:
            self.throttleAutomaticSwitch.setOn(true, animated: animated)
            self.throttleConstantSwitch.setOn(false, animated: animated)
        case let .constant(value):
            self.throttleAutomaticSwitch.setOn(false, animated: animated)
            self.throttleConstantSwitch.setOn(true, animated: animated)
            self.throttleConstantSlider.setValue(Float(value), animated: animated)
            self.throttleConstantLabel.text = "\(Int(value * 100))%"
        case .userControlled:
            break
        }

        switch selection.steeringSelection {
        case .automatic:
            self.steeringAutomaticSwitch.setOn(true, animated: animated)
            self.steeringConstantSwitch.setOn(false, animated: animated)
        case let .constant(value):
            self.steeringAutomaticSwitch.setOn(false, animated: animated)
            self.steeringConstantSwitch.setOn(true, animated: animated)
            self.steeringConstantSlider.setValue(Float(value), animated: animated)
            self.steeringConstantLabel.text = "\(Int(value * 100))%"
        case .userControlled:
            break
        }

        self.currentSelection = selection
    }

    private func toggle(_ row: ToggleableRow) {

        let feedback = UISelectionFeedbackGenerator()
        feedback.prepare()

        switch row {
        case .throttleAutomaticToggle:
            let isOn = !self.throttleAutomaticSwitch.isOn
            self.throttleAutomaticSwitch.setOn(isOn, animated: true)
            if isOn {
                self.throttleConstantSwitch.setOn(false, animated: true)
            }
        case .throttleConstantToggle:
            let isOn = !self.throttleConstantSwitch.isOn
            self.throttleConstantSwitch.setOn(isOn, animated: true)
            if isOn {
                self.throttleAutomaticSwitch.setOn(false, animated: true)
            }
        case .steeringAutomaticToggle:
            let isOn = !self.steeringAutomaticSwitch.isOn
            self.steeringAutomaticSwitch.setOn(isOn, animated: true)
            if isOn {
                self.steeringConstantSwitch.setOn(false, animated: true)
            }
        case .steeringConstantToggle:
            let isOn = !self.steeringConstantSwitch.isOn
            self.steeringConstantSwitch.setOn(isOn, animated: true)
            if isOn {
                self.steeringAutomaticSwitch.setOn(false, animated: true)
            }
        }
        self.updateCurrentSelection()
        feedback.selectionChanged()
    }

    private func updateCurrentSelection() {
        self.currentSelection = RemoteControlSessionSettings(
            throttleSelection: self.makeCurrentThrottleSelection(),
            steeringSelection: self.makeCurrentSteeringSelection())
    }

    private func makeCurrentThrottleSelection() -> RemoteControlSessionSettings.Selection {
        switch (self.throttleAutomaticSwitch.isOn, self.throttleConstantSwitch.isOn) {
        case (true, true):
            // Edge case.
            return .userControlled
        case (false, false):
            return .userControlled
        case (true, false):
            return .automatic
        case (false, true):
            return .constant(Double(self.throttleConstantSlider.value))
        }
    }

    private func makeCurrentSteeringSelection() -> RemoteControlSessionSettings.Selection {
        switch (self.steeringAutomaticSwitch.isOn, self.steeringConstantSwitch.isOn) {
        case (true, true):
            // Edge case.
            return .userControlled
        case (false, false):
            return .userControlled
        case (true, false):
            return .automatic
        case (false, true):
            return .constant(Double(self.steeringConstantSlider.value))
        }
    }

    @IBAction func onThrottleSliderValueChange(_ sender: UISlider) {
        self.throttleConstantLabel.text = "\(Int(sender.value * 100))%"
        self.updateCurrentSelection()
    }

    @IBAction func onSteeringSliderValueChange(_ sender: UISlider) {
        self.steeringConstantLabel.text = "\(Int(sender.value * 100))%"
        self.updateCurrentSelection()
    }

    private enum ToggleableRow {

        case throttleAutomaticToggle
        case throttleConstantToggle
        case steeringAutomaticToggle
        case steeringConstantToggle

        init?(_ indexPath: IndexPath) {
            switch indexPath {
            case [0, 0]:
                self = .throttleAutomaticToggle
            case [0, 1]:
                self = .throttleConstantToggle
            case [1, 0]:
                self = .steeringAutomaticToggle
            case [1, 1]:
                self = .steeringConstantToggle
            default:
                return nil
            }
        }
    }
}
