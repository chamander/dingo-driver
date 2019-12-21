
import UIKit

protocol ConnectionListProvider: class {
    func withConnectionList(perform handler: @escaping ([Connection]) -> Void)
}

protocol ConnectionListPersistence: class {
    func saveConnection(_ connection: Connection, completion: (() -> Void)?)
}

final class ConnectionListViewController: UITableViewController {

    private typealias DiffableDataSource = UITableViewDiffableDataSource<Section, Connection>

    // MARK: - Instance Members - Privates

    // TODO: Prefer injection over hard-coding impl. detail.
    private let persistence = ConnectionListDiskPersistence()
    private let provider = ConnectionListDiskProvider()

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

    // MARK: - Overrides - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = DiffableDataSource(tableView: self.tableView) { (tableView, indexPath, connection) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: ReusableCell.connection.reuseIdentifier, for: indexPath)
            cell.textLabel?.text = connection.hostname
            cell.detailTextLabel?.text = connection.topic
            return cell
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTableView(animated: false)
    }

    // MARK: - Interface Builder Actions - Privates - Segues

    @IBAction private func cancelAddSession(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Add Session'.
        // The user tapped 'Cancel'; do nothing.
    }

    @IBAction private func addSessionUnwindToSessionList(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Add Session'.
        // The user successfully tapped 'Save'; persist the session.
        guard let source = unwindSegue.source as? AddConnectionViewController else {
            return
        }

        if let connection = source.createdConnection {
            self.persistence.saveConnection(connection) {
                self.updateTableView()
            }
        }
    }

    // MARK: - Instance Members - Privates - Functions

    private func updateTableView(animated: Bool = true) {

        self.provider.withConnectionList { [weak self] connections in
            var snapshot = NSDiffableDataSourceSnapshot<Section, Connection>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(connections, toSection: .connectionList)
            self?.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }
}
