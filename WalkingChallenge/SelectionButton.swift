
import UIKit
import SnapKit

protocol SelectionButtonDataSource {
  var items: Array<String> { get }
  var selection: Int? { get set }
}

class SelectionButtonPopoverViewController: UIViewController {
  fileprivate var dataSource: SelectionButtonDataSource?
  fileprivate var sourceView: UIView?

  private let tableView: UITableView = UITableView()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(tableView)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self,
                       forCellReuseIdentifier: "PopoverCell")
    tableView.snp.makeConstraints { (ConstraintMaker) in
      ConstraintMaker.edges.equalToSuperview().inset(Style.Padding.p12)
    }
  }
}

extension SelectionButtonPopoverViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView,
                 didSelectRowAt indexPath: IndexPath) {
    dataSource?.selection = indexPath.row
    presentingViewController?.dismiss(animated: true, completion: nil)
  }
}

extension SelectionButtonPopoverViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    guard (dataSource != nil) else { return 0 }
    return dataSource!.items.count
  }

  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "PopoverCell",
                                             for: indexPath)
    if let selection = dataSource?.selection {
      if indexPath.row == selection {
        cell.accessoryType = .checkmark
      }
    }
    cell.textLabel?.text = dataSource?.items[safe: indexPath.row]
    return cell
  }
}

extension SelectionButtonPopoverViewController: UIPopoverPresentationControllerDelegate {
  func prepareForPopoverPresentation(_ controller: UIPopoverPresentationController) {
    controller.permittedArrowDirections = .any
    controller.sourceView = sourceView
  }

  func adaptivePresentationStyle(for controller: UIPresentationController)
      -> UIModalPresentationStyle {
    return .none
  }
}

protocol SelectionButtonDelegate {
  func present(_ viewControllerToPresent: UIViewController,
               animated flag: Bool, completion: (() -> Swift.Void)?)
}

class SelectionButton: UIButton {
  var dataSource: SelectionButtonDataSource?
  var delegate: SelectionButtonDelegate?
  var selection: Int? {
    get { return dataSource?.selection }
    set { dataSource?.selection = newValue }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.addTarget(self, action: #selector(presentPopover), for: .touchUpInside)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc
  private func presentPopover() {
    let popover = SelectionButtonPopoverViewController()
    popover.dataSource = dataSource
    popover.sourceView = self
    popover.modalPresentationStyle = .popover
    // TODO(compnerd) calculate this properly
    popover.preferredContentSize = CGSize(width: 256, height: 196)
    popover.popoverPresentationController!.delegate = popover
    delegate?.present(popover, animated: true, completion: nil)
  }
}
