import UIKit

/// In-app button mapping editor. Changes are saved immediately to UserDefaults.
final class RemapViewController: UITableViewController {

    private let store = TouchMappingStore.shared
    private let cellIdentifier = "MappingCell"
    var onDismiss: (() -> Void)?

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Button Mapping"
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: cellIdentifier
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )

        let note = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 56))
        note.text = "Tap a button, then pick the key it should send.\nSaved automatically. Use MOUSE for doors and the monitor."
        note.numberOfLines = 0
        note.textAlignment = .center
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabel
        tableView.tableFooterView = note
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    @objc private func doneTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }

    @objc private func resetTapped() {
        store.resetToDefaults()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TouchAction.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = TouchAction.allCases[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        cell.textLabel?.text = action.title
        cell.detailTextLabel?.text = store.label(for: action)
        cell.detailTextLabel?.textColor = .systemBlue
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let action = TouchAction.allCases[indexPath.row]
        navigationController?.pushViewController(
            KeyPickerViewController(action: action),
            animated: true
        )
    }
}

// MARK: - Key picker

final class KeyPickerViewController: UITableViewController {

    private let action: TouchAction
    private let store = TouchMappingStore.shared
    private let keys = TouchMappingStore.availableKeys
    private let cellIdentifier = "KeyCell"

    init(action: TouchAction) {
        self.action = action
        super.init(style: .insetGrouped)
        title = action.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = keys[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = option.label

        let current = store.entry(for: action)
        cell.accessoryType = (current.keyCode == option.keyCode && current.code == option.code)
            ? .checkmark
            : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        store.set(keys[indexPath.row], for: action)
        navigationController?.popViewController(animated: true)
    }
}
