//
//  LearningTrailViewController.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import AVKit
import SPCCore
import PlaygroundSupport

// Defines the requirements for controlling a learning trail.
public protocol LearningTrailController {
    var learningTrailDataSource: LearningTrailDataSource? { get set }
}

// Implement this protocol to receive updates from a LearningTrailViewController.
public protocol LearningTrailViewControllerDelegate {
    func trailViewControllerDidRequestClose(_ trailViewController: LearningTrailViewController)
}

@objc(LearningTrailViewController)
public class LearningTrailViewController: UIViewController, LearningTrailController {
    private let mainContainerView = UIView()
    private var collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: CollectionViewTrailLayout())
    private var customLayout: CollectionViewTrailLayout? {
        return collectionView.collectionViewLayout as? CollectionViewTrailLayout
    }
    private let maximumSize = CGSize(width: 1024, height: 1024)
    private let minimumSize = CGSize(width: 300, height: 300)
    private let heightThreshold: CGFloat = 700
    private let buttonSize = CGSize(width: 44, height: 44)

    private var heightThresholdReachedTopConstraint: NSLayoutConstraint!
    private var heightThresholdReachedBottomConstraint: NSLayoutConstraint!
    private var pageControlWidthConstraint: NSLayoutConstraint!
    
    static let pageControlHeight: CGFloat = 37
    
    private var pageControl = UIPageControl()
    private var statusTextView = UITextView()
    private var closeButton = LTBarButton()
    private var visualEffectView = UIVisualEffectView()
    
    private let bottomBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let bottomLineView = UIView()
    
    private let defaultCornerRadius: CGFloat = 13
    
    private var currentPageIndex = 0
    private var dragEventCount = 0 {
        didSet {
            
            if dragEventCount < 0 {
                dragEventCount = 0
            }
            
            let noDragEvents = (dragEventCount == 0)
            collectionView.isScrollEnabled = noDragEvents
            pageControl.isUserInteractionEnabled = noDragEvents
        }
    }
    
    private var transitioningPageIndex: Int?
    
    public var learningTrailDataSource: LearningTrailDataSource? {
        didSet {
            resetCollectionView()
        }
    }
    
    public let trailMinimumTopPadding: CGFloat = 20.0
    
    public var closeButtonPosition: CGPoint {
        return mainContainerView.convert(closeButton.center, to: nil)
    }
    
    public var delegate: LearningTrailViewControllerDelegate?
    
    // MARK: Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // Register the custom icon font.
        if let iconFontName = UIFont.registerFontFromResource(named: TextAttributedStringStyle.iconFontName, fontfileExtension: TextAttributedStringStyle.iconFontExtension) {
            PBLog("Registered icon font: \(iconFontName)")
        } else {
            PBLog("Failed to register icon font.")
        }
        
        // Register the custom code font.
        if let codeFontName = UIFont.registerFontFromResource(named: CodeAttributedStringStyle.codeFontName, fontfileExtension: CodeAttributedStringStyle.codeFontExtension) {
            PBLog("Registered code font: \(codeFontName)")
        } else {
            PBLog("Failed to register code font.")
        }
        
        // Use the view’s tint color for interactive elements in text.
        TextAttributedStringStyle.shared.tintColor = view.tintColor
        GroupAttributedStringStyle.shared.tintColor = view.tintColor
        NotificationCenter.default.addObserver(self, selector: #selector(onDragInteractionStateChanged), name: .dragInteractionStateChanged, object: nil)
        
        if #available(iOS 13.0, *) {
            bottomBlurView.effect = UIBlurEffect(style: .systemMaterial)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Controller Lifecycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        mainContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainContainerView)
                
        configureCollectionView()
        
        // Use an auto-resizing mask instead of constraints so that collectionView is resized along with its superview (mainContainerView).
        // This ensures that by the time viewDidLayoutSubviews is called, the collection view is correctly sized.
        // This is essential for goToPage() to scroll to the correct page following a resize.
        collectionView.frame = mainContainerView.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let containerViewWidthConstraint = mainContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.88)
        containerViewWidthConstraint.priority = .defaultHigh
        let containerViewHeightConstraint = mainContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.77)
        containerViewHeightConstraint.priority = .defaultHigh
        let containerViewCenterYConstraint = mainContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        containerViewCenterYConstraint.priority = .defaultHigh
        
        heightThresholdReachedTopConstraint = mainContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: trailMinimumTopPadding)
        heightThresholdReachedBottomConstraint = mainContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        NSLayoutConstraint.activate([
            mainContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainContainerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            mainContainerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            mainContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: maximumSize.width),
            mainContainerView.heightAnchor.constraint(lessThanOrEqualToConstant: maximumSize.height),
            containerViewCenterYConstraint,
            containerViewWidthConstraint,
            containerViewHeightConstraint
        ])

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        bottomBlurView.translatesAutoresizingMaskIntoConstraints = false
        bottomLineView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.addSubview(bottomBlurView)
        mainContainerView.addSubview(bottomLineView)
        mainContainerView.addSubview(pageControl)
        mainContainerView.addSubview(closeButton)
        
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = view.tintColor
        pageControl.addTarget(self, action: #selector(onPageControlValueChanged(sender:)), for: UIControl.Event.valueChanged)
        pageControl.accessibilityIdentifier = "\(type(of: self)).pageControl"
        pageControlWidthConstraint = pageControl.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            pageControl.heightAnchor.constraint(equalToConstant: LearningTrailViewController.pageControlHeight),
            pageControlWidthConstraint
        ])
        
        bottomBlurView.layer.masksToBounds = true
        bottomBlurView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        bottomBlurView.layer.cornerRadius = defaultCornerRadius
        NSLayoutConstraint.activate([
            bottomBlurView.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            bottomBlurView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            bottomBlurView.widthAnchor.constraint(equalTo: collectionView.widthAnchor),
            bottomBlurView.heightAnchor.constraint(equalTo: pageControl.heightAnchor)
        ])
        
        bottomLineView.backgroundColor = GroupLearningBlockStyle.separatorColor
        bottomLineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomLineView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            bottomLineView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            bottomLineView.widthAnchor.constraint(equalTo: collectionView.widthAnchor),
            bottomLineView.heightAnchor.constraint(equalToConstant: GroupLearningBlockStyle.separatorHeight)
        ])
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.showsBackground = false
        closeButton.setImage(UIImage(named: "LearningTrailMinimize")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.addTarget(self, action: #selector(didPressCloseButton), for: .touchUpInside)
        closeButton.accessibilityLabel = NSLocalizedString("Hide Learning Trail", tableName: "SPCLearningTrails", comment: "AX label for hide learning trail button.")
        closeButton.accessibilityIdentifier = "\(String(describing: type(of: self))).closeButton"
        let closeButtonTrailingInset = (DefaultLearningStepStyle.headerHeight - DefaultLearningStepStyle.headerButtonSize.height) / 2.0
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: collectionView.topAnchor, constant: DefaultLearningStepStyle.headerHeight / 2.0),
            closeButton.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: -closeButtonTrailingInset),
            closeButton.widthAnchor.constraint(equalToConstant: DefaultLearningStepStyle.headerButtonSize.width),
            closeButton.heightAnchor.constraint(equalToConstant: DefaultLearningStepStyle.headerButtonSize.height)
        ])
   
        statusTextView.translatesAutoresizingMaskIntoConstraints = false
        statusTextView.textColor = .yellow
        statusTextView.font = UIFont.systemFont(ofSize: 14.0)
        statusTextView.backgroundColor = .darkGray
        statusTextView.alpha = 0.75
        statusTextView.isHidden = true
        statusTextView.accessibilityIdentifier = "\(String(describing: type(of: self))).statusMessage"
        collectionView.addSubview(statusTextView)
        
        NSLayoutConstraint.activate([
            statusTextView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            statusTextView.leftAnchor.constraint(equalTo: collectionView.leftAnchor),
            statusTextView.widthAnchor.constraint(equalTo: collectionView.widthAnchor),
            statusTextView.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: Layout
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.goToPage(pageIndex: self.currentPageIndex, animated: false)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        heightThresholdReachedTopConstraint.isActive = view.bounds.height < heightThreshold
        heightThresholdReachedBottomConstraint.isActive = view.bounds.height < heightThreshold
        pageControlWidthConstraint.constant = collectionView.bounds.width
        
        goToPage(pageIndex: self.currentPageIndex, animated: false)
    }
    
    // MARK: Action
    
    @objc
    func onPageControlValueChanged(sender: AnyObject) -> () {
        goToPage(pageIndex: pageControl.currentPage, animated: true)
    }
    
    @objc
    func didPressCloseButton(_ sender: UIButton) {
        delegate?.trailViewControllerDidRequestClose(self)
    }
    
    // MARK: Private Methods
    
    private func configureCollectionView() {
        guard let _ = customLayout else { return }
        
        collectionView.backgroundColor = UIColor.systemBackgroundLT
        collectionView.isPagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.clipsToBounds = true
        collectionView.layer.cornerRadius = defaultCornerRadius
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(StepCollectionViewCell.self, forCellWithReuseIdentifier: CollectionViewTrailLayout.Element.cell.id)

        mainContainerView.addSubview(collectionView)
    }
    
    private func resetCollectionView() {
        guard let learningTrailDataSource = learningTrailDataSource else { return }
        pageControl.numberOfPages = learningTrailDataSource.stepCount
        
        guard learningTrailDataSource.stepCount > 0 else { return }
        loadLastViewedPage()
    }
    
    private func viewControllerForStep(at index: Int) -> UIViewController? {
        let viewController = learningTrailDataSource?.viewControllerForStep(at: index)
        (viewController as? LearningStepViewController)?.delegate = self
        return viewController
    }
    
    private func currentPageViewController() -> UIViewController? {
        return viewControllerForStep(at: currentPageIndex)
    }
    
    private func beginTransitionBetweenSteps() {
        if var currentStepController = currentPageViewController() as? LearningStepController {
            currentStepController.isActive = false
        }
    }
    
    private func onTransitionCompletedToStepWith(index pageIndex: Int) {
        currentPageIndex = pageIndex
        dragEventCount = 0
        if pageControl.currentPage != pageIndex {
            pageControl.currentPage = pageIndex
        }
        
        if var currentStepController = currentPageViewController() as? LearningStepController {
            currentStepController.isActive = true
            saveCurrentPage()
        }
    }
    
    private func loadLastViewedPage() {
        guard let trailId = learningTrailDataSource?.trail.identifier else { return }
        guard let stateValue = PlaygroundKeyValueStore.current[trailId],
            case let .dictionary(state) = stateValue
            else {
                goToPage(pageIndex: 0, animated: false)
                return
        }
        if let activeIndexValue = state["activePageIndex"], case let .integer(previouslyActiveIndex) = activeIndexValue {
            goToPage(pageIndex: previouslyActiveIndex, animated: false)
        }
    }
    
    private func saveCurrentPage() {
        guard let trailId = learningTrailDataSource?.trail.identifier else { return }
        var state = [String : PlaygroundValue]()
        state["activePageIndex"] = .integer(currentPageIndex)
        PlaygroundKeyValueStore.current[trailId] = .dictionary(state)
    }
    
    private func goToPage(pageIndex: Int, animated: Bool = false) {
        guard pageIndex < collectionView.numberOfItems(inSection: 0) else { return }
        
        if pageIndex != self.currentPageIndex {
            beginTransitionBetweenSteps()
        }
        
        collectionView.scrollToItem(at: IndexPath(row: pageIndex, section: 0), at: .centeredHorizontally, animated: animated)
    }
    
    @objc private func onDragInteractionStateChanged(notification: Notification) {
        guard let dragValue = notification.object as? NSNumber else { return }
        dragEventCount += dragValue.intValue
    }
    
    // MARK: Public Methods

    public func showMessage(_ message: String) {
        statusTextView.text = message
        statusTextView.isHidden = false
    }
    
    private func scaleForShowHideTransform() -> CGFloat {
        let currentSize = max(mainContainerView.bounds.size.height, mainContainerView.bounds.size.width)
        let finalSize = buttonSize.height * 0.6
        return currentSize != 0.0 ? (finalSize / currentSize) : 0.1
    }
    
    public func show(from startPoint: CGPoint, duration: Double, delay: Double = 0.0) {
        // Expand and reveal the learning trail from startPoint.
        view.alpha = 0.0
        view.isHidden = false
        
        // Add a blur effect.
        mainContainerView.addSubview(visualEffectView)
        visualEffectView.effect = UIBlurEffect(style: .light)
        visualEffectView.isUserInteractionEnabled = false
        visualEffectView.layer.cornerRadius = defaultCornerRadius
        visualEffectView.clipsToBounds = true
        visualEffectView.frame = mainContainerView.bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let containerCenter = view.convert(mainContainerView.center, to: nil)
        let dx = startPoint.x - containerCenter.x
        let dy = startPoint.y - containerCenter.y
        let scale = scaleForShowHideTransform()
        self.mainContainerView.transform = CGAffineTransform.identity.translatedBy(x: dx, y: dy).scaledBy(x: scale, y: scale)
        UIView.animate(withDuration: duration, delay: delay,
                       options: [ .curveEaseOut, .beginFromCurrentState ],
                       animations: {
            self.mainContainerView.transform = CGAffineTransform.identity
            self.view.alpha = 1.0
            self.visualEffectView.effect = nil
        }, completion: { _ in
            // Activate the current step.
            if let currentStepViewController = self.currentPageViewController() as? LearningStepViewController {
                currentStepViewController.isActive = true
            }
        })
    }
    
    public func hide(to endPoint: CGPoint, duration: Double, delay: Double = 0.0) {
        // Deactivate the current step.
        if let currentStepViewController = self.currentPageViewController() as? LearningStepViewController {
            currentStepViewController.isActive = false
        }
        // Shrink and hide the learning trail to endPoint.
        let containerCenter = view.convert(mainContainerView.center, to: nil)
        let dx = endPoint.x - containerCenter.x
        let dy = endPoint.y - containerCenter.y
        let scale = scaleForShowHideTransform()
        UIView.animate(withDuration: duration, delay: delay,
                       options: [ .curveEaseOut, .beginFromCurrentState ],
                       animations: {
            self.mainContainerView.transform = CGAffineTransform.identity.translatedBy(x: dx, y: dy).scaledBy(x: scale, y: scale)
            self.view.alpha = 0.0
            self.visualEffectView.effect = UIBlurEffect(style: UIBlurEffect.Style.light)
        }, completion: { _ in
            self.view.isHidden = true
            self.visualEffectView.removeFromSuperview()
        })
    }
}

// MARK: LearningStepViewControllerDelegate
extension LearningTrailViewController: LearningStepViewControllerDelegate {
    
    func stepViewController(_ stepViewController: LearningStepViewController, didRaiseAction url: URL, at rect: CGRect?) {
        
        PBLog("\(url)")
        
        if url.absoluteString.starts(with: "@") {
            // Handle immediate @ actions.
            var actionCompletion: (() -> Void)?
            let chunks = url.absoluteString.split(separator: ":")
            let action = String(chunks[0])
            let actionParameters: [String] = chunks[1...].map{ String($0) }
            switch action {
            case "@next":
                actionCompletion = {
                    PlaygroundPage.current.navigateTo(page: .next)
                }
            case "@previous":
                actionCompletion = {
                    PlaygroundPage.current.navigateTo(page: .previous)
                }
            case "@page":
                // Go to a specified page: @page:<page relative path>
                // e.g. @page:Document1/03
                guard let pageRelativePath = actionParameters.first, !pageRelativePath.isEmpty else {
                    PBLog("@page link has no path specified: \(url.absoluteString)")
                    return
                }
                actionCompletion = {
                    PlaygroundPage.current.navigateTo(page: .pageReference(reference: pageRelativePath))
                }
            case "@nextStep":
                actionCompletion = {
                    self.goToPage(pageIndex: self.currentPageIndex + 1, animated: true)
                }
            case "@previousStep":
                actionCompletion = {
                    self.goToPage(pageIndex: self.currentPageIndex - 1, animated: true)
                }
            case "@step":
                // Go to a specified step: @step:<step number>
                // e.g. @step:4
                guard
                    let stepNumberValue = actionParameters.first,
                    let stepNumber = Int(stepNumberValue),
                    let stepCount = learningTrailDataSource?.stepCount,
                    stepNumber > 0, stepNumber <= stepCount
                    else {
                        PBLog("@step link has invalid step number: \(url.absoluteString)")
                        return
                }
                actionCompletion = {
                    self.goToPage(pageIndex: stepNumber - 1, animated: true)
                }
            default:
                PBLog("Unrecognized action: \(action)")
                return
            }
            
            DispatchQueue.main.async {
                actionCompletion?()
            }
            
        } else if url.scheme == nil, !url.relativeString.isEmpty {
            // Handle links to specified pages e.g. Document1/Page3
            PlaygroundPage.current.navigateTo(page: .pageReference(reference: url.relativeString))
            
        } else {
            // Handle links actions.
            guard let scheme = url.scheme, let host = url.host else { return }
            if scheme == "glossary" {
                // Glossary entry.
                guard let rect = rect else { return }
                PlaygroundPage.current.showGlossaryEntry(named: host, at: rect, in: nil)
            } else {
                guard
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                    let queryItems = components.queryItems
                else { return }
                let queryParameters = queryItems.reduce(into: [String: String]()) { (result, item) in
                    result[item.name] = item.value }
                if scheme == "x-playgrounds" {
                    // Launch a playground book.
                    // e.g. x-playgrounds://document/?contentIdentifier=com.apple.playgrounds.learntocode1.edition2.gm&page=4
                    guard let contentIdentifier = queryParameters["contentIdentifier"] else {
                        PBLog("Missing content identifier in: \(url)")
                        return
                    }
                    let pageIndex = Int(queryParameters["page"] ?? "")
                    PlaygroundPage.current.openPlayground(withContentIdentifier: contentIdentifier, toPageAtIndex: pageIndex)
                } else if scheme == "x-playgrounds-launch-app" {
                    // Launch an app.
                    // e.g. x-playgrounds-launch-app://com.apple.mobilenotes?iTunesID=20030426
                    let bundleIdentifier = host
                    guard !bundleIdentifier.isEmpty else {
                        PBLog("Missing bundle identifier in: \(url)")
                        return
                    }
                    let iTunesIdentifier = Int(queryParameters["iTunesID"] ?? "")
                    PlaygroundPage.current.openApplication(withBundleIdentifier: bundleIdentifier, iTunesItemIdentifier: iTunesIdentifier)
                }

            }
        }
    }
    
    func stepViewController(_ stepViewController: LearningStepViewController, goToStep step: LearningStep) {
        if let stepIndex = learningTrailDataSource?.index(of: step) {
            goToPage(pageIndex: stepIndex, animated: true)
        }
    }
    
    func stepViewController(_ stepViewController: LearningStepViewController, stepAssessmentStatusChanged step: LearningStep) {
        if LearningAssessmentManager.shared.isPageAssessmentSuccessfullyCompleted() {
            // Page assessment is completed: request a layout update on the parent view controller.
            if let parentViewController = parent {
                parentViewController.view.setNeedsLayout()
            }
        }
    }
}

// MARK: UICollectionViewDataSource
extension LearningTrailViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return learningTrailDataSource?.stepCount ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewTrailLayout.Element.cell.id, for: indexPath)
        
        if let viewController = viewControllerForStep(at: indexPath.row) as? LearningStepViewController, let cell = cell as? StepCollectionViewCell {
            addChild(viewController)
            cell.configure(with: viewController)
        }
        
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension LearningTrailViewController: UICollectionViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onScrollingDidEnd(scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        onScrollingDidEnd(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            onScrollingDidEnd(scrollView)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTransitionBetweenSteps()
        collectionView.endEditing(true)
    }
    
    private func onScrollingDidEnd(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        onTransitionCompletedToStepWith(index: pageIndex)
    }
}
