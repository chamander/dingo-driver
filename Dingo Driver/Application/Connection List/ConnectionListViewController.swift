
import UIKit

final class ConnectionListViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction private func cancelAddSession(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Add Session'.
        // The user tapped 'Cancel'; do nothing.
    }

    @IBAction private func addSessionUnwindToSessionList(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Add Session'.
        // The user successfully tapped 'Save'; persist the session.
    }
}
