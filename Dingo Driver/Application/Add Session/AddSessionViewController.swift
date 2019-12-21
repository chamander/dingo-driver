
import UIKit

final class AddSessionViewController: UITableViewController {

    @IBOutlet private var hostnameTextField: UITextField!
    @IBOutlet private var topicTextField: UITextField!

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
}
