
import UIKit
import MonkeyKing

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        switch (indexPath as NSIndexPath).row {
        case 0:
            cell.textLabel!.text = "WeChat"
        case 1:
            cell.textLabel!.text = "Weibo"
        case 2:
            cell.textLabel!.text = "QQ"
        case 3:
            cell.textLabel!.text = "System"
        case 4:
            cell.textLabel!.text = "Pocket"
        case 5:
            cell.textLabel!.text = "Alipay"
        case 6:
            cell.textLabel!.text = "Twitter"
        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        switch (indexPath as NSIndexPath).row {
        case 0:
            performSegue(withIdentifier: "WeChat", sender: nil)
        case 1:
            performSegue(withIdentifier: "Weibo", sender: nil)
        case 2:
            performSegue(withIdentifier: "QQ", sender: nil)
        case 3:
            performSegue(withIdentifier: "System", sender: nil)
        case 4:
            performSegue(withIdentifier: "Pocket", sender: nil)
        case 5:
            performSegue(withIdentifier: "Alipay", sender: nil)
        case 6:
            performSegue(withIdentifier: "Twitter", sender: nil)
        default:
            break
        }
    }
}
