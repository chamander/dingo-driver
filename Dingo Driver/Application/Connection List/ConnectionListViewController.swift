
import UIKit

final class ConnectionListViewController: UITableViewController {

    private var dataSource: DiffableDataSource!

    private enum Section: CaseIterable {
        case connectionList
    }

    private enum ReusableCell {

        case connection

        var reuseIdentifier: String {
            switch self {
            case .connection:
                return "connectionCell"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = DiffableDataSource(tableView: self.tableView) { (tableView, indexPath, connection) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: ReusableCell.connection.reuseIdentifier, for: indexPath)
            cell.textLabel?.text = connection.hostname
            cell.detailTextLabel?.text = connection.topic
            return cell
        }
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

extension ConnectionListViewController {

    private final class DiffableDataSource: UITableViewDiffableDataSource<Section, Connection> { }
}
