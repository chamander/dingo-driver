
import UIKit

protocol ConnectionListProvider: class {
    func withConnectionList(perform handler: @escaping ([Connection]) -> Void)
}

protocol ConnectionListPersistence: class {
    func saveConnection(_ connection: Connection, completion: (() -> Void)?)
    func deleteConnection(_ connection: Connection, completion: (() -> Void)?)
}

final class ConnectionListViewController: UITableViewController {

    // MARK: - Instance Members - Privates

    // TODO: Prefer injection over hard-coding impl. detail.
    private let persistence: ConnectionListPersistence = ConnectionListDiskPersistence()
    private let provider: ConnectionListProvider = ConnectionListDiskProvider()

    private var dataSource: DiffableDataSource!
    private var connections: [Connection] = []

    private enum Section: CaseIterable {
        case connectionList
    }

    private enum Item: Hashable {

        case connection(Connection)

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
        self.dataSource = DiffableDataSource(tableView: self.tableView) { (tableView, indexPath, item) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath)
            switch self.item(at: indexPath) {
            case let .connection(connection):
                cell.textLabel?.text = connection.hostname
                cell.detailTextLabel?.text = connection.topic
            }
            return cell
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateTableView(animated: false)
    }

    // At the moment, 'Connection' is our only model object.
    private func item(at indexPath: IndexPath) -> Item {
        return .connection(self.connections[indexPath.row])
    }

    // MARK: - Overrides - Table View Controller

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(
            style: .destructive,
            title: "Delete") { [weak self] (action, sourceView, onActionCompletion) in
                if let self = self {
                    switch self.item(at: indexPath) {
                    case let .connection(connection):
                        self.persistence.deleteConnection(connection) {
                            onActionCompletion(true)
                            self.updateTableView(animated: true)
                        }
                    }
                }
            }
        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    // MARK: - Interface Builder Actions - Privates - Segues

    @IBAction private func cancelAddSession(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Add Session'.
        // The user tapped 'Cancel'; do nothing.
    }

    @IBAction private func remoteControlUnwindToConnectionList(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Remote Control'.
        // The user tapped 'Close'; do nothing.
    }

    @IBAction private func addSessionUnwindToConnectionList(_ unwindSegue: UIStoryboardSegue) {
        // Segue to dismiss 'Add Session'.
        // The user successfully tapped 'Save'; persist the session.
        guard let source = unwindSegue.source as? AddConnectionViewController else {
            return
        }

        if let connection = source.createdConnection {
            self.persistence.saveConnection(connection) {
                self.updateTableView(animated: true)
            }
        }
    }

    // MARK: - Instance Members - Privates - Functions

    private func updateTableView(animated: Bool) {

        self.provider.withConnectionList { [weak self] connections in

            guard let self = self else { return }

            var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
            snapshot.appendSections(Section.allCases)
            snapshot.appendItems(connections.map(Item.connection), toSection: .connectionList)

            self.connections = connections
            self.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }

    // MARK: - Nested Type - Diffable Data Source

    private final class DiffableDataSource: UITableViewDiffableDataSource<Section, Item> {

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
    }
}
