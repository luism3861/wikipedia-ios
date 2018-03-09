private struct Section {
    let headerTitle: String?
    let footerText: String?
    let items: [Item]
}

private struct Item {
    let disclosureType: WMFSettingsMenuItemDisclosureType?
    let type: ItemType
    let title: String?
    let isSwitchOn: Bool
    let buttonTitle: String?
    
    init(for type: ItemType, isSwitchOn: Bool = false) {
        self.type = type
        self.isSwitchOn = isSwitchOn
        
        var disclosureType: WMFSettingsMenuItemDisclosureType? = nil
        var title: String? = nil
        var buttonTitle: String? = nil

        switch type {
        case .syncSavedArticlesAndLists:
            disclosureType = .switch
            title = WMFLocalizedString("settings-storage-and-syncing-enable-sync-title", value: "Sync saved articles and lists", comment: "Title of the settings option that enables saved articles and reading lists syncing")
        case .showSavedReadingList:
            disclosureType = .switch
            title = WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-title", value: "Show Saved reading list", comment: "Title of the settings option that enables showing the default reading list")
        case .syncWithTheServer:
            disclosureType = .titleButton
            buttonTitle = WMFLocalizedString("settings-storage-and-syncing-server-sync-title", value: "Sync with the server", comment: "Title of the settings button that initiates saved articles and reading lists server sync")
        default:
            break
        }
        
        self.title = title
        self.disclosureType = disclosureType
        self.buttonTitle = buttonTitle
    }
}

private enum ItemType: Int {
    case syncSavedArticlesAndLists, showSavedReadingList, eraseSavedArticles, syncWithTheServer
}

@objc(WMFStorageAndSyncingSettingsViewController)
class StorageAndSyncingSettingsViewController: UIViewController {
    private let customViewCellReuseIdentifier = "CustomViewTableViewCell"
    private var theme: Theme = Theme.standard
    private var tableView: UITableView!
    @objc public var dataStore: MWKDataStore?
    private var indexPathsForCellsWithSwitches: [IndexPath] = []
    
    private var sections: [Section] {
        let syncSavedArticlesAndLists = Item(for: .syncSavedArticlesAndLists, isSwitchOn: isSyncEnabled)
        
        let showSavedReadingList = Item(for: .showSavedReadingList, isSwitchOn: dataStore?.readingListsController.isDefaultListEnabled ?? false)
        let eraseSavedArticles = Item(for: .eraseSavedArticles)
        let syncWithTheServer = Item(for: .syncWithTheServer)
        
        let syncSavedArticlesAndListsSection = Section(headerTitle: nil, footerText: WMFLocalizedString("settings-storage-and-syncing-enable-sync-footer-text", value: "Allow Wikimedia to save your saved articles and reading lists to your user preferences when you login to sync", comment: "Footer text of the settings option that enables saved articles and reading lists syncing"), items: [syncSavedArticlesAndLists])
        
        let showSavedReadingListSection = Section(headerTitle: nil, footerText: WMFLocalizedString("settings-storage-and-syncing-show-default-reading-list-footer-text", value: "Show the Saved (eg. default) reading list as a separate list in your Reading lists view. This list appears on Android devices", comment: "Footer text of the settings option that enables showing the default reading list"), items: [showSavedReadingList])
        
        let eraseSavedArticlesSection = Section(headerTitle: nil, footerText: nil, items: [eraseSavedArticles])
        let syncWithTheServerSection = Section(headerTitle: nil, footerText: WMFLocalizedString("settings-storage-and-syncing-server-sync-footer-text", value: "Request a sync from the server for an update to your synced articles and reading lists", comment: "Footer text of the settings button that initiates saved articles and reading lists server sync"), items: [syncWithTheServer])
        
        return [syncSavedArticlesAndListsSection, showSavedReadingListSection, eraseSavedArticlesSection, syncWithTheServerSection]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = CommonStrings.settingsStorageAndSyncing
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0);
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WMFSettingsTableViewCell.wmf_classNib(), forCellReuseIdentifier: WMFSettingsTableViewCell.identifier())
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: customViewCellReuseIdentifier)
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        apply(theme: self.theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadRows(at: indexPathsForCellsWithSwitches, with: .none)
    }
    
    private var isSyncEnabled: Bool {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return false
        }
        return dataStore.readingListsController.isSyncEnabled
    }
    
    @objc private func eraseSavedArticles() {
        dataStore?.readingListsController.unsaveAllArticles({})
    }
    
    private lazy var eraseSavedArticlesView: EraseSavedArticlesView? = {
        let eraseSavedArticlesView = EraseSavedArticlesView.wmf_viewFromClassNib()
        eraseSavedArticlesView?.titleLabel.text = WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-title", value: "Erase saved articles", comment: "Title of the settings option that enables erasing saved articles")
        eraseSavedArticlesView?.button.setTitle(WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-button-title", value: "Erase", comment: "Title of the settings button that enables erasing saved articles"), for: .normal)
        eraseSavedArticlesView?.button.addTarget(self, action: #selector(eraseSavedArticles), for: .touchUpInside)
        eraseSavedArticlesView?.footerLabel.text = WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-footer-text", value: "Erasing your saved articles will remove them from your user account if you have syncing turned on as well as and from this device.\n\nErasing your saved articles will free up about 364.4 MB of space.", comment: "Footer text of the settings option that enables erasing saved articles")
       return eraseSavedArticlesView
    }()
}

// MARK: UITableViewDataSource

extension StorageAndSyncingSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let settingsItem = sections[indexPath.section].items[indexPath.row]
        
        guard let disclosureType = settingsItem.disclosureType else {
            let cell = tableView.dequeueReusableCell(withIdentifier: customViewCellReuseIdentifier, for: indexPath)
            cell.selectionStyle = .none
            if let eraseSavedArticlesView = eraseSavedArticlesView {
                eraseSavedArticlesView.frame = cell.contentView.bounds
                eraseSavedArticlesView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                cell.contentView.addSubview(eraseSavedArticlesView)
            } else {
                assertionFailure("Couldn't load EraseSavedArticlesView from nib")
            }
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WMFSettingsTableViewCell.identifier(), for: indexPath) as? WMFSettingsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        cell.configure(disclosureType, title: settingsItem.title, iconName: nil, isSwitchOn: settingsItem.isSwitchOn, iconColor: nil, iconBackgroundColor: nil, buttonTitle: settingsItem.buttonTitle, controlTag: settingsItem.type.rawValue, theme: theme)
    
        if settingsItem.disclosureType == .switch {
            indexPathsForCellsWithSwitches.append(indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footerText
    }
}

// MARK: - UITableViewDelegate

extension StorageAndSyncingSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let settingsItem = sections[indexPath.section].items[indexPath.row]
        guard settingsItem.disclosureType != nil else {
            return eraseSavedArticlesView?.frame.height ?? 0
        }
        return tableView.rowHeight
    }
}

// MARK: - WMFSettingsTableViewCellDelegate

extension StorageAndSyncingSettingsViewController: WMFSettingsTableViewCellDelegate {
    
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didToggleDisclosureSwitch sender: UISwitch!) {
        guard let settingsItemType = ItemType(rawValue: sender.tag) else {
            assertionFailure("Toggled discloure switch of WMFSettingsTableViewCell for undefined StorageAndSyncingSettingsItemType")
            return
        }
        
        switch settingsItemType {
        case .syncSavedArticlesAndLists:
            if WMFAuthenticationManager.sharedInstance.loggedInUsername == nil && !isSyncEnabled {
                wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: theme, dismissHandler: { sender.setOn(false, animated: true) })
            } else {
                dataStore?.readingListsController.setSyncEnabled(sender.isOn, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: !sender.isOn)
            }
        case .showSavedReadingList:
            dataStore?.readingListsController.isDefaultListEnabled = sender.isOn
        default:
            return
        }
    }
    
    func settingsTableViewCell(_ settingsTableViewCell: WMFSettingsTableViewCell!, didPress sender: UIButton!) {
        guard let settingsItemType = ItemType(rawValue: sender.tag), settingsItemType == .syncWithTheServer else {
            assertionFailure("Pressed button of WMFSettingsTableViewCell for undefined StorageAndSyncingSettingsItemType")
            return
        }
        
        dataStore?.readingListsController.fullSync({})
    }
}

// MARK: Themeable

extension StorageAndSyncingSettingsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        tableView.backgroundColor = theme.colors.baseBackground
        eraseSavedArticlesView?.apply(theme: theme)
    }
}
