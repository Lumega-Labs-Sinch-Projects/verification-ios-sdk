//
//  SettingsViewController.swift
//  VerificationSample
//
//  Sample settings UI mirroring Android SettingsActivity.
//

import UIKit

final class SettingsViewController: UIViewController {

    private let store = SampleConfigStore.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var envButtons: [UIButton] = []
    private var indiaEnvButtons: [UIButton] = []
    private var routingButtons: [UIButton] = []

    private let baseURLField = UITextField()
    private let updateBaseURLButton = UIButton(type: .system)
    private let appKeyField = UITextField()
    private let updateAppKeyButton = UIButton(type: .system)
    private let indiaURLLabel = UILabel()
    private let indiaAppKeyField = UITextField()
    private let updateIndiaAppKeyButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissTapped)
        )

        setupLayout()
        setupKeyboardHandling()
        populateFromStore()
        showAppKeyPromptIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Layout

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        contentStack.addArrangedSubview(sectionTitle("Environment"))
        envButtons = Environments.map { env in
            makeRadioButton(value: env.name, action: #selector(envTapped(_:)))
        }
        envButtons.forEach { contentStack.addArrangedSubview($0) }

        contentStack.addArrangedSubview(sectionTitle("Environment details"))
        styleTextField(baseURLField, placeholder: "Base URL", keyboard: .URL)
        contentStack.addArrangedSubview(baseURLField)
        styleActionButton(updateBaseURLButton, title: "Update Base URL", action: #selector(updateBaseURLTapped))
        contentStack.addArrangedSubview(updateBaseURLButton)

        styleTextField(appKeyField, placeholder: "App Key", keyboard: .default)
        contentStack.addArrangedSubview(appKeyField)
        styleActionButton(updateAppKeyButton, title: "Update App Key", action: #selector(updateAppKeyTapped))
        contentStack.addArrangedSubview(updateAppKeyButton)

        contentStack.addArrangedSubview(sectionTitle("India environment"))
        indiaEnvButtons = IndiaEnv.allCases.map { env in
            makeRadioButton(value: env.rawValue, action: #selector(indiaEnvTapped(_:)))
        }
        indiaEnvButtons.forEach { contentStack.addArrangedSubview($0) }

        indiaURLLabel.font = .preferredFont(forTextStyle: .footnote)
        indiaURLLabel.textColor = .secondaryLabel
        indiaURLLabel.numberOfLines = 0
        contentStack.addArrangedSubview(indiaURLLabel)

        contentStack.addArrangedSubview(sectionTitle("Default routing"))
        let routingHint = UILabel()
        routingHint.text = "Indian numbers (+91) always use the India endpoint. Choose where non-Indian numbers are routed."
        routingHint.font = .preferredFont(forTextStyle: .footnote)
        routingHint.textColor = .secondaryLabel
        routingHint.numberOfLines = 0
        contentStack.addArrangedSubview(routingHint)

        routingButtons = DefaultRouting.allCases.map { routing in
            makeRadioButton(value: routing.rawValue, action: #selector(routingTapped(_:)))
        }
        routingButtons.forEach { contentStack.addArrangedSubview($0) }

        contentStack.addArrangedSubview(sectionTitle("India App Key"))
        styleTextField(indiaAppKeyField, placeholder: "India App Key", keyboard: .default)
        contentStack.addArrangedSubview(indiaAppKeyField)
        styleActionButton(updateIndiaAppKeyButton, title: "Update India App Key", action: #selector(updateIndiaAppKeyTapped))
        contentStack.addArrangedSubview(updateIndiaAppKeyButton)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .label
        return label
    }

    private func makeRadioButton(value: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = value
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        return button
    }

    private func styleTextField(_ field: UITextField, placeholder: String, keyboard: UIKeyboardType) {
        field.borderStyle = .roundedRect
        field.placeholder = placeholder
        field.keyboardType = keyboard
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done
        field.delegate = self
        field.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }

    private func setupKeyboardHandling() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
        else { return }

        let keyboardInView = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardInView.origin.y - view.safeAreaInsets.bottom)
        let inset = UIEdgeInsets(top: 0, left: 0, bottom: overlap, right: 0)
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset = inset
            self.scrollView.scrollIndicatorInsets = inset
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        UIView.animate(withDuration: duration) {
            self.scrollView.contentInset = .zero
            self.scrollView.scrollIndicatorInsets = .zero
        }
    }

    private func styleActionButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    // MARK: - Populate

    private func populateFromStore() {
        let config = store.usedConfig

        updateRadioSelection(envButtons, selectedTitle: config.name)
        baseURLField.text = config.domain
        appKeyField.text = config.appKey
        let customEnabled = config.isCustom
        baseURLField.isEnabled = customEnabled
        updateBaseURLButton.isEnabled = customEnabled
        baseURLField.alpha = customEnabled ? 1 : 0.5

        updateRadioSelection(indiaEnvButtons, selectedTitle: store.indiaEnv.rawValue)
        indiaURLLabel.text = store.indiaApiHost
        updateRadioSelection(routingButtons, selectedTitle: store.defaultRouting.rawValue)
        indiaAppKeyField.text = store.indiaAppKey
    }

    private func updateRadioSelection(_ buttons: [UIButton], selectedTitle: String) {
        for button in buttons {
            let value = button.accessibilityIdentifier ?? ""
            let selected = value == selectedTitle
            button.setTitle((selected ? "● " : "○ ") + value, for: .normal)
            button.titleLabel?.font = selected
                ? .preferredFont(forTextStyle: .headline)
                : .preferredFont(forTextStyle: .body)
        }
    }

    private func showAppKeyPromptIfNeeded() {
        let key = store.usedConfig.appKey
        if key.isEmpty || key.contains("YOUR APP KEY") {
            let alert = UIAlertController(
                title: nil,
                message: "Please insert a valid App Key in Settings before starting verification.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // MARK: - Actions

    @objc private func dismissTapped() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func envTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard let name = sender.accessibilityIdentifier else { return }
        store.selectEnvironment(named: name)
        populateFromStore()
    }

    @objc private func updateBaseURLTapped() {
        view.endEditing(true)
        applyBaseURLUpdate()
    }

    @objc private func updateAppKeyTapped() {
        view.endEditing(true)
        applyAppKeyUpdate()
    }

    @objc private func indiaEnvTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard let name = sender.accessibilityIdentifier else { return }
        store.updateIndiaEnv(IndiaEnv.fromName(name))
        populateFromStore()
    }

    @objc private func routingTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard let name = sender.accessibilityIdentifier else { return }
        store.updateDefaultRouting(DefaultRouting.fromName(name))
        populateFromStore()
    }

    @objc private func updateIndiaAppKeyTapped() {
        view.endEditing(true)
        applyIndiaAppKeyUpdate()
    }

    private func applyBaseURLUpdate() {
        let raw = baseURLField.text ?? ""
        if store.updateCurrentBaseURL(raw) {
            populateFromStore()
            showAcknowledgement("Base URL updated")
        } else {
            let alert = UIAlertController(
                title: nil,
                message: "Invalid environment URL. Use a full http(s) URL ending with /.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    private func applyAppKeyUpdate() {
        store.updateCurrentAppKey(appKeyField.text ?? "")
        populateFromStore()
        showAcknowledgement("App Key updated")
    }

    private func applyIndiaAppKeyUpdate() {
        store.updateIndiaAppKey(indiaAppKeyField.text ?? "")
        populateFromStore()
        showAcknowledgement("India App Key updated")
    }

    private func showAcknowledgement(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension SettingsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case baseURLField:
            applyBaseURLUpdate()
        case appKeyField:
            applyAppKeyUpdate()
        case indiaAppKeyField:
            applyIndiaAppKeyUpdate()
        default:
            break
        }
        textField.resignFirstResponder()
        return true
    }
}
