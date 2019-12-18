
import MonkeyKing
import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    struct Item {
        let title: String

        var segueIdentifier: String {
            return title
        }
    }

    let items: [Item] = [
        Item(title: "WeChat"),
        Item(title: "Weibo"),
        Item(title: "QQ"),
        Item(title: "Alipay"),
        Item(title: "Twitter"),
        Item(title: "Pocket"),
        Item(title: "System"),
    ]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let segueIdentifier = items[indexPath.row].segueIdentifier
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }
}
