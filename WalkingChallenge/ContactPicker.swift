
import UIKit
import SnapKit
import Contacts

struct FriendCellInfo : CellInfo {
  let cellIdentifier: String = FriendCell.identifier
  let fbid: String
  let name: String
  let picture: String
}

class FriendCell: ConfigurableTableViewCell {
  static let identifier: String = "FriendCell"

  let picture = UIImageView()
  let name = UILabel(.body)

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    initialize()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initialize()
  }

  private func initialize() {
    contentView.addSubviews([picture, name])
    backgroundColor = .clear

    picture.snp.makeConstraints { (make) in
      make.height.width.equalTo(Style.Size.s32)
      make.left.equalToSuperview().inset(Style.Padding.p12)
    }
    name.snp.makeConstraints { (make) in
      make.left.equalTo(picture.snp.right).offset(Style.Padding.p12)
      make.right.equalToSuperview().inset(Style.Padding.p12)
      make.height.equalTo(picture.snp.height)
    }
  }

  override func configure(cellInfo: CellInfo) {
    guard let cell = cellInfo as? FriendCellInfo else { return }

    name.text = cell.name
    do {
      let data = try Data(contentsOf: URL(string: cell.picture)!)
      picture.image = UIImage(data: data)
    } catch {
    }
  }
}

class FriendsDataSource: TableDataSource {
  var cells = [CellInfo]()

  var selectedContacts = [String]()
  var sortedContacts = [String: [String]]()

  func reload(completion: @escaping () -> Void) {
    if cells.isEmpty {
      let sortOrder = CNContactsUserDefaults.shared().sortOrder
      Facebook.getTaggableFriends(limit: .none) { (friend) in
        self.cells.append(FriendCellInfo(fbid: friend.fbid,
                                         name: friend.display_name,
                                         picture: friend.picture_url))
        var sorted = [String]()

        var key: String
        switch (sortOrder) {
        case .givenName:
          key = String(friend.first_name.characters.first!).uppercased()
        case .none:
          fallthrough
        case .familyName:
          key = String(friend.last_name.characters.first!).uppercased()
        case .userDefault:
          key = "#"
        }

        if let friends = self.sortedContacts[key] {
          sorted = friends
        }
        sorted.append(friend.fbid)
        self.sortedContacts[key] = sorted
        onMain {
          completion()
        }
      }
    }
  }
}

class ContactPicker : UIViewController {
  var tableView = UITableView()
  let dataSource = FriendsDataSource()
  let search = UISearchBar()

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    dataSource.reload { [weak self] () in
      self?.tableView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureNavigationBar()
    configureTableView()

    // TODO(compnerd) color the background to .clear
    search.delegate = self

    view.backgroundColor = Style.Colors.white
    view.addSubviews([search, tableView])

    search.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview().inset(Style.Padding.p12)
      make.top.equalToSuperview().inset(Style.Padding.p12)
    }
    tableView.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview().inset(Style.Padding.p12)
      make.top.equalTo(search.snp.bottom).offset(Style.Padding.p12)
      make.bottom.equalToSuperview().inset(Style.Padding.p12)
    }
  }

  private func configureNavigationBar() {
    navigationItem.title = Strings.ContactPicker.title
    navigationItem.leftBarButtonItem =
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                        action: #selector(cancelTapped))
    navigationItem.rightBarButtonItem =
        UIBarButtonItem(barButtonSystemItem: .done, target: self,
                        action: #selector(doneTapped))
  }

  private func configureTableView() {
    tableView.rowHeight = Style.Size.s40
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = Style.Colors.white
    tableView.register(FriendCell.self,
                       forCellReuseIdentifier: FriendCell.identifier)
    tableView.allowsMultipleSelection = true
  }

  func cancelTapped() {
    self.dismiss(animated: true, completion: nil)
  }

  func doneTapped() {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ContactPicker {
  fileprivate func contact(for indexPath: IndexPath) -> String? {
    guard
      let key = dataSource.sortedContacts.keys.sorted()[safe: indexPath.section],
      let contacts = dataSource.sortedContacts[key]
    else {
        return nil
    }
    return contacts[safe: indexPath.row]!
  }

  fileprivate func selectContact(fbid: String) {
    dataSource.selectedContacts.append(fbid)
  }

  fileprivate func unselectContact(fbid: String) {
    dataSource.selectedContacts =
        dataSource.selectedContacts.filter { (contact) in
          return !(contact == fbid)
        }
  }

  fileprivate func isSelected(fbid: String) -> Bool {
    return dataSource.selectedContacts.contains(fbid)
  }
}

extension ContactPicker : UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
      -> UITableViewCell {
    guard
      let contact = self.contact(for: indexPath),
      let cell =
          tableView.dequeueReusableCell(withIdentifier: FriendCell.identifier,
                                        for: indexPath)
              as? ConfigurableTableViewCell
    else {
      return UITableViewCell()
    }

    let cellInfo = dataSource.cells.filter { (ci) in
      return (ci as! FriendCellInfo).fbid == contact
    }.first! as! FriendCellInfo
    cell.configure(cellInfo: cellInfo)
    cell.accessoryType =
        dataSource.selectedContacts.contains(cellInfo.fbid) ? .checkmark : .none
    return cell
  }

  func sectionIndexTitles(for tableView: UITableView) -> [String]? {
    return dataSource.sortedContacts.keys.sorted()
  }
}

extension ContactPicker : UITableViewDelegate {
  func numberOfSections(in tableView: UITableView) -> Int {
    return dataSource.sortedContacts.keys.count
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int)
      -> String? {
    return dataSource.sortedContacts.keys.sorted()[section]
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
      -> Int {
    let key = dataSource.sortedContacts.keys.sorted()[section]
    return (dataSource.sortedContacts[key]?.count)!
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                 forRowAt indexPath: IndexPath) {
    guard let contact = self.contact(for: indexPath) else {
      cell.accessoryType = .none
      return
    }
    cell.accessoryType = isSelected(fbid: contact) ? .checkmark : .none
  }

  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath)
      -> IndexPath? {
    if let selected = tableView.indexPathsForSelectedRows {
      if selected.count == 11 {
        let alert = UIAlertController(title: "Error",
                                      message: "You are limited to 11 members",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default,
                                      handler: nil))
        self.present(alert, animated: true, completion: nil)
        return nil
      }
    }

    return indexPath
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let cell = tableView.cellForRow(at: indexPath) {
      guard let contact = self.contact(for: indexPath) else { return }
      selectContact(fbid: contact)
      cell.accessoryType = .checkmark
    }
  }

  func tableView(_ tableView: UITableView,
                 didDeselectRowAt indexPath: IndexPath) {
    if let cell = tableView.cellForRow(at: indexPath) {
      guard let contact = self.contact(for: indexPath) else { return }
      unselectContact(fbid: contact)
      cell.accessoryType = .none
    }
  }
}

extension ContactPicker : UISearchBarDelegate {
}
