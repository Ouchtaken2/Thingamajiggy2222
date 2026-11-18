import UIKit

/// Root settings screen. Game speed, HUD counters and zoom are all persisted
/// by AppConfigStore; the button mapping lives one level deeper.
final class SettingsViewController: UITableViewController {

    private let config = AppConfigStore.shared
    private let cellIdentifier = "SettingsCell"
    var onDismiss: (() -> Void)?

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset All",
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )

        let note = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 76))
        note.text = "Game Speed is experimental: the engine has no official speed control, so it works by scaling the game's clock. Set it back to 1.0× if anything behaves oddly."
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabel
        note.textAlignment = .center
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
        config.resetToDefaults()
        TouchMappingStore.shared.resetToDefaults()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 4 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1  // controls
        case 1: return 1  // gameplay
        case 2: return 2  // diagnostics
        default: return 1 // minigames
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Controls"
        case 1: return "Gameplay"
        case 2: return "Diagnostics"
        default: return "Minigames"
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            cell.textLabel?.text = "Button Mapping"
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil

        case (1, 0):
            cell.textLabel?.text = "Game Speed"
            cell.detailTextLabel?.text = String(format: "%.2f×", config.gameSpeed)
            cell.detailTextLabel?.textColor = .systemBlue
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView = nil

        case (2, 0):
            cell.textLabel?.text = "FPS Counter"
            cell.accessoryType = .none
            let toggle = ConfigSwitch()
            toggle.isOn = config.showFPS
            toggle.valueChanged = { [weak self] value in self?.config.showFPS = value }
            cell.accessoryView = toggle

        case (2, 1):
            cell.textLabel?.text = "Memory Counter"
            cell.accessoryType = .none
            let toggle = ConfigSwitch()
            toggle.isOn = config.showRAM
            toggle.valueChanged = { [weak self] value in self?.config.showRAM = value }
            cell.accessoryView = toggle

        case (3, 0):
            cell.textLabel?.text = "Minigame Zoom Button"
            cell.accessoryType = .none
            let toggle = ConfigSwitch()
            toggle.isOn = config.showZoomButton
            toggle.valueChanged = { [weak self] value in self?.config.showZoomButton = value }
            cell.accessoryView = toggle

        default:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 0 {
            navigationController?.pushViewController(RemapViewController(), animated: true)
        } else if indexPath.section == 1 && indexPath.row == 0 {
            navigationController?.pushViewController(SpeedPickerViewController(), animated: true)
        }
    }
}

// MARK: - Speed picker

final class SpeedPickerViewController: UITableViewController {

    private let config = AppConfigStore.shared
    private let cellIdentifier = "SpeedCell"
    private let speeds = AppConfigStore.speedOptions

    init() {
        super.init(style: .insetGrouped)
        title = "Game Speed"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        speeds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let speed = speeds[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.textLabel?.text = String(format: "%.2f×%@", speed, speed == 1.0 ? "  (normal)" : "")
        cell.accessoryType = abs(config.gameSpeed - speed) < 0.001 ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        config.gameSpeed = speeds[indexPath.row]
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Switch

private final class ConfigSwitch: UISwitch {
    var valueChanged: ((Bool) -> Void)?

    init() {
        super.init(frame: .zero)
        addTarget(self, action: #selector(changed), for: .valueChanged)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func changed() { valueChanged?(isOn) }
}
