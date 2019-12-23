
import UIKit

final class AddConnectionViewController: UITableViewController, UITextFieldDelegate {

    // MARK: - Instance Members - Public API

    /// The session that is to be created to represent the data captured.
    ///
    /// This member is only populated when the user taps 'Save', and so
    /// accessing this property before that creation will result in 'nil'.
    private(set) var createdConnection: Connection?

    // MARK: - Interface Builder Members - Privates

    @IBOutlet private var hostnameTextField: UITextField!
    @IBOutlet private var topicTextField: UITextField!

    // MARK: - Nested Type - Row

    private enum Row {

        case hostname
        case topic

        init?(_ indexPath: IndexPath) {
            switch indexPath {
            case [0, 0]:
                self = .hostname
            case [0, 1]:
                self = .topic
            default:
                return nil
            }
        }
    }

    // MARK: - Nested Type - Segue-related

    private enum Segue {

        case unwindToSessionList

        var identifier: String {
            switch self {
            case .unwindToSessionList:
                return "addSessionUnwindToSessionList"
            }
        }
    }

    private func perform(_ segue: Segue, sender: Any) {
        self.performSegue(withIdentifier: segue.identifier, sender: sender)
    }

    // MARK: - Override - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hostnameTextField.delegate = self
        self.topicTextField.delegate = self
    }

    // MARK: - Override - Table View Controller

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Row(indexPath) {
        case .hostname?:
            self.hostnameTextField.becomeFirstResponder()
        case .topic?:
            self.topicTextField.becomeFirstResponder()
        case nil:
            break
        }
    }

    // MARK: - Conformance - Text Field Delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case self.hostnameTextField:
            self.topicTextField.becomeFirstResponder()
            return true
        case self.topicTextField:
            self.completeAddConnectionUseCaseIfAble(sender: self.topicTextField)
            return true
        default:
            return false // Delegate call for an unexpected UITextField instance.
        }
    }

    // MARK: - Interface Builder Actions - Privates

    @IBAction private func onSaveButtonTap(_ sender: UIBarButtonItem) {
        self.completeAddConnectionUseCaseIfAble(sender: sender)
    }

    // MARK: - Privates - Persisting the Connection

    // - If the view controller captures enough info. to persist connection:
    //   - Persist the connection.
    //   - Return to Connection List.
    // - Else, present alert to request for more information.
    //   - Return user to Add Connection (as per before attempting to persist).
    //
    /// Attempts to complete the 'Add Connection' use-case; returning to the
    /// Connection List, if completion is possible.
    ///
    /// - Parameters:
    ///     - sender: The object triggering a use-case completion attempt.
    private func completeAddConnectionUseCaseIfAble(sender: Any?) {
        if let createdConnection = self.createConnection() {
            self.createdConnection = createdConnection
            self.perform(.unwindToSessionList, sender: sender)
        } else {

            let alert = UIAlertController(
                title: "Unable to create session",
                message: "Please input enough information to connect to your car",
                preferredStyle: .alert)

            let okay = UIAlertAction(
                title: "Okay",
                style: .default)

            alert.addAction(okay)
            self.present(alert, animated: true)
        }
    }

    private func createConnection() -> Connection? {

        guard
            let hostname = self.hostnameTextField.text,
            let topic = self.topicTextField.text
        else {
            return nil
        }

        guard !(hostname.isEmpty || topic.isEmpty) else {
            return nil
        }

        return Connection(hostname: hostname, topic: topic)
    }
}
