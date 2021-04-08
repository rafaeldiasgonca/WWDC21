//
//  LearningStepViewController.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import AVKit
import SPCCore

// Defines the requirements for controlling a learning step.
protocol LearningStepController {
    var learningStepDataSource: LearningStepDataSource? { get set }
    var isActive: Bool { get set }
    func refreshStep()
}

// Implement this protocol to receive updates from a LearningStepViewController.
protocol LearningStepViewControllerDelegate {
    func stepViewController(_ stepViewController: LearningStepViewController, didRaiseAction url: URL, at rect: CGRect?)
    func stepViewController(_ stepViewController: LearningStepViewController, goToStep step: LearningStep)
    func stepViewController(_ stepViewController: LearningStepViewController, stepAssessmentStatusChanged step: LearningStep)
}

public class LearningStepViewController: UIViewController, LearningStepController {
    private static let cellReuseIdentifier = "LearningBlockTableViewCell"
    private let backgroundImageView = UIImageView()
    
    private let stepHeaderView = LearningStepHeaderView()
    private var stepHeaderViewHeightConstraint: NSLayoutConstraint!
    
    private let debugTextView = UITextView()
    private let debugTextViewHeightPercentage: CGFloat = 0.25
    
    private let tableView = UITableView()
    private let tableViewTopContentInset: CGFloat = 15
    private let tableViewBottomContentInset = LearningTrailViewController.pageControlHeight
    private let tableViewWidthPercentage: CGFloat = 1.0
    private var learningBlockCells = [LearningBlockCell]()
        
    var learningStepDataSource: LearningStepDataSource? {
        didSet {
            guard let step = learningStepDataSource?.step else { return }
            
            learningBlockCells.removeAll()
            
            step.blocks.forEach({ block in
                let blockCell = LearningBlockCell(learningBlock: block)
                blockCell.isVisible = block.initialVisibleState
                blockCell.delegate = self
                learningBlockCells.append(blockCell)
            })
            
            if let stepStyle = learningStepDataSource?.styleForLearningStep(step), let trail = step.parentTrail {
                stepHeaderView.load(step: step, style: stepStyle, assessableSteps: trail.assessableSteps)
                stepHeaderView.delegate = self
            }
            
            view.setNeedsLayout()
        }
    }
    
    func axActivate() {
        // Delay the learning trail AX notification so that it’s not swamped by the app moving AX focus to a UI element when moving to a new page.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if LearningTrails.isStepTitleInHeader {
                UIAccessibility.post(notification: .screenChanged, argument: self.stepHeaderView.textLabel)
            } else if let firstVisibleCell = self.tableView.visibleCells.first {
                UIAccessibility.post(notification: .screenChanged, argument: firstVisibleCell)
            }
        }
    }
    
    var isActive: Bool = false {
        didSet {
            
            // Enable accessibility elements only when this view controller is active.
            view.accessibilityElementsHidden = !isActive
            
            tableView.showsVerticalScrollIndicator = isActive
            
            if oldValue == false && isActive {
                axActivate()
            }
            
            DispatchQueue.main.async {
                self.stepHeaderView.setActiveStep(nil)
                if self.isActive, let step = self.learningStepDataSource?.step {
                    self.stepHeaderView.setActiveStep(step)
                    self.stepHeaderView.refresh()
                    self.tableView.flashScrollIndicators()
                }

            }
        }
    }
        
    var delegate: LearningStepViewControllerDelegate?
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didChangePreferredContentSize(notification:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        stepHeaderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stepHeaderView)
        stepHeaderViewHeightConstraint = stepHeaderView.heightAnchor.constraint(equalToConstant: DefaultLearningStepStyle.headerHeight)
        NSLayoutConstraint.activate([
            stepHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            stepHeaderView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stepHeaderView.widthAnchor.constraint(equalTo: view.widthAnchor),
            stepHeaderViewHeightConstraint
        ])
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.systemBackgroundLT
        tableView.register(LearningBlockTableViewCell.self, forCellReuseIdentifier: LearningStepViewController.cellReuseIdentifier)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: tableViewTopContentInset, left: 0, bottom: tableViewBottomContentInset, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: tableViewBottomContentInset, right: 0)
        tableView.allowsSelection = false
        tableView.isAccessibilityElement = false
        
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: stepHeaderView.bottomAnchor),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: tableViewWidthPercentage),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        debugTextView.translatesAutoresizingMaskIntoConstraints = false
        debugTextView.textContainerInset = UIEdgeInsets.zero
        debugTextView.isSelectable = true
        debugTextView.isEditable = false
        debugTextView.backgroundColor = UIColor.yellow.withAlphaComponent(0.75)
        debugTextView.isHidden = true
        view.addSubview(debugTextView)
        NSLayoutConstraint.activate([
            debugTextView.leftAnchor.constraint(equalTo: tableView.leftAnchor),
            debugTextView.widthAnchor.constraint(equalTo: tableView.widthAnchor),
            debugTextView.heightAnchor.constraint(equalTo: tableView.heightAnchor, multiplier: debugTextViewHeightPercentage),
            debugTextView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])

        isActive = false
        
        // TODO: Should not need to set offset manually, but on steps with a content height that is bigger than the frame height, it's needed right now.
        tableView.setContentOffset(CGPoint(x: 0, y: -tableViewTopContentInset), animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        stepHeaderView.refresh()
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        dismissPresentedViewControllerIfNeeded()
    }
    
    public override func updateViewConstraints() {
        /* Things to update:
         The height of the step header (based on tableView scroll offset)
         */
        super.updateViewConstraints()
    }
    
    // Returns the child cells of a learningBlockCell if it has any.
    func childLearningBlockCells(for learningBlockCell: LearningBlockCell) -> [LearningBlockCell] {
        guard let learningBlock = learningBlockCell.learningBlock, learningBlock.childBlocks.count > 0 else { return [LearningBlockCell]() }
        var childBlockCells = [LearningBlockCell]()
        for childLearningBlock in learningBlock.childBlocks {
            if let blockCell = learningBlockCells.filter({ $0.learningBlock == childLearningBlock }).first {
                childBlockCells.append(blockCell)
            }
        }
        return childBlockCells
    }
    
    // Recursively sets the disclosed (visible) state of the child cells of a learningBlockCell.
    func setDisclosedState(_ learningBlockCell: LearningBlockCell, disclosed: Bool) {
        let childBlockCells = childLearningBlockCells(for: learningBlockCell)
        
        for childBlockCell in childBlockCells {
            guard let childLearningBlock = childBlockCell.learningBlock else { continue }

            // Update visibility of the cell.
            childBlockCell.isVisible = disclosed
            if disclosed {
                childBlockCell.alpha = 0.0
                UIView.animate(withDuration: 0.25, animations: {
                    childBlockCell.alpha = 1.0
                }, completion: nil)
            }
            
            // If the childLearningBlock is a group, recurse over its children.
            if childLearningBlock.blockType == .group {
            
                var newDisclosedState = disclosed
                if disclosed {
                    newDisclosedState = childLearningBlock.isDisclosed
                }
                
                setDisclosedState(childBlockCell, disclosed: newDisclosedState)
            }
        }
        
        // Update the cell and its child table view cells *after* the visibility state of all the cells has been set.
        // This has the effect of removing any duplicate separators between newly-visible adjacent cells.
        for childBlockCell in childBlockCells {
            guard let index = learningBlockCells.firstIndex(of: childBlockCell) else { continue }
            self.updateTableViewCell(at: IndexPath(row: index, section: 0))
            let isVisible = childBlockCell.isVisible
            childBlockCell.isVisible = isVisible // Force a constraints update.
        }
        if let index = learningBlockCells.firstIndex(of: learningBlockCell) {
            self.updateTableViewCell(at: IndexPath(row: index, section: 0))
        }
    }
    
    func updateTableViewCell(at indexPath: IndexPath) {
        guard let tvCell = tableView.cellForRow(at: indexPath) as? LearningBlockTableViewCell else { return }
        updateTableViewCell(tvCell)
     }
    
    func updateTableViewCell(_ tableViewCell: LearningBlockTableViewCell) {
        guard
            let learningBlockCell = tableViewCell.learningBlockCell,
            let learningBlock = learningBlockCell.learningBlock
            else { return }
        
        // Top separator.
        tableViewCell.isTopSeparatorVisible = learningBlockCell.isVisible && (learningBlock.blockType == .group)
        
        // Bottom separator.
        var bottomSeparatorShouldBeVisible = false
        if learningBlockCell.isVisible {
            if (learningBlock.blockType == .group) {
                bottomSeparatorShouldBeVisible = !learningBlock.isDisclosed
            } else {
                bottomSeparatorShouldBeVisible = learningBlock.isLastBlockInGroup
            }
            // Eliminate duplicate separators between adjacent cells.
            if nextVisibleCellIsAGroup(learningBlockCell) {
                bottomSeparatorShouldBeVisible = false
            }
        }
        tableViewCell.isBottomSeparatorVisible = bottomSeparatorShouldBeVisible
        
        // Accessibility.
        tableViewCell.accessibilityElementsHidden = learningBlockCell.accessibilityElementsHidden
    }
    
    // Returns true if the next visible cell after learningBlockCell is a group.
    func nextVisibleCellIsAGroup(_ learningBlockCell: LearningBlockCell) -> Bool {
        if let nextIndex = learningBlockCells.firstIndex(of: learningBlockCell)?.advanced(by: 1) {
            if let nextVisibleCell = learningBlockCells[nextIndex ..< learningBlockCells.endIndex].filter({
                $0.isVisible
            }).first {
                return nextVisibleCell.learningBlock?.blockType == .group
            }
        }
        return false
    }
    
    // Appends a debug message to the debug view.
    func appendDebug(message: String) {
        var text = debugTextView.text ?? ""
        text += text.isEmpty ? "" : "\n"
        text += message
        debugTextView.text = text
        debugTextView.isHidden = false
    }
    
    // Reloads all the blocks in a step.
    func refreshStep() {
        stepHeaderView.refresh()
        
        learningBlockCells.forEach({ $0.isLoaded = false })
        tableView.reloadData()
    }
    
    @objc func didChangePreferredContentSize(notification: Notification) {
        DispatchQueue.main.async {
            let visibleCells = self.learningBlockCells.filter{ $0.isVisible }
            visibleCells.forEach { cell in
                self.cellNeedsRefresh(cell)
            }
        }
    }
}

// MARK: UICollectionViewDataSource
extension LearningStepViewController: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }

}

// MARK: UITableViewDataSource
extension LearningStepViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let learningStepDataSource = learningStepDataSource else { return 0 }
        return learningStepDataSource.blockCount
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: LearningStepViewController.cellReuseIdentifier, for: indexPath as IndexPath) as! LearningBlockTableViewCell
        
        defer {
            updateTableViewCell(tableViewCell)
        }
        
        guard let learningStepDataSource = learningStepDataSource, indexPath.row < learningStepDataSource.blockCount else { return tableViewCell }
        
        let learningBlockCell = learningBlockCells[indexPath.row]
        
        tableViewCell.learningBlockCell = learningBlockCell
        tableViewCell.isAccessibilityElement = false
        
        guard let learningBlock = learningBlockCell.learningBlock, !learningBlockCell.isLoaded else {
            return tableViewCell
        }
        
        if let learningBlockView = learningStepDataSource.viewForLearningBlock(learningBlock) {
            learningBlockCell.isVisible = learningBlock.initialVisibleState
            learningBlockCell.learningBlockView = learningBlockView
            
            if let groupBlockView = learningBlockView as? GroupLearningBlockView {
                groupBlockView.delegate = tableViewCell.learningBlockCell
            }
            
            if let responseBlockView = learningBlockView as? ResponseLearningBlockView {
                responseBlockView.delegate = tableViewCell.learningBlockCell
            }
            
            if let imageBlockView = learningBlockView as? ImageLearningBlockView {
                imageBlockView.delegate = tableViewCell.learningBlockCell
            }
            
            if let buttonsBlockView = learningBlockView as? ButtonsLearningBlockView {
                buttonsBlockView.delegate = tableViewCell.learningBlockCell
            }
            
            if let textBlockView = learningBlockView as? TextLearningBlockView {
                textBlockView.blockViewDelegate = tableViewCell.learningBlockCell
            }
        }
        return tableViewCell
    }
}

extension LearningStepViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat{
        return 100
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let lbtvCell = cell as? LearningBlockTableViewCell else { return }
        updateTableViewCell(lbtvCell)
    }
}

// MARK: LearningBlockCellDelegate
extension LearningStepViewController: LearningBlockCellDelegate {
    
    public func cellNeedsRefresh(_ cell: LearningBlockCell) {
        guard let index = learningBlockCells.firstIndex(of: cell) else { return }
        
        updateStep({
            let indexPath = IndexPath(row: index, section: 0)
            self.updateTableViewCell(at: indexPath)
        }, completion: nil)
    }
    
    public func cell(_ cell: LearningBlockCell, didChangeDisclosedState disclosed: Bool) {
        guard let index = learningBlockCells.firstIndex(of: cell) else { return }
        
        guard let learningBlock = cell.learningBlock else { return }
        learningBlock.isDisclosed = disclosed
        
        updateStep({
            self.setDisclosedState(cell, disclosed: disclosed)
            let indexPath = IndexPath(row: index, section: 0)
            self.updateTableViewCell(at: indexPath)
        }) { (completed) in
            if disclosed {
                guard let learningBlockTableViewCell = self.learningBlockTableViewCell(for: cell) else { return }
                var height = self.heightOfChildren(in: cell)
                let availableSize = CGSize(width: self.tableView.contentSize.width * LearningBlockTableViewCell.contentWidthMultiplier, height: CGFloat.greatestFiniteMagnitude)
                height += cell.sizeThatFits(availableSize).height
                let maximumScrollHeight = self.tableView.bounds.height - self.tableView.contentInset.bottom
                height = min(maximumScrollHeight, height)
                let origin = learningBlockTableViewCell.frame.origin
                let scrollRect = CGRect(origin: origin, size: CGSize(width: availableSize.width, height: height))
                self.tableView.scrollRectToVisible(scrollRect, animated: true)
            }
        }
    }
    
    public func cell(_ cell: LearningBlockCell, didRequestZoomImage imageBlockView: ImageLearningBlockView, at screenRect: CGRect) {
        guard let viewController = delegate as? UIViewController else { return }
        
        if let presentedViewController = viewController.presentedViewController {
            // If the delegate view controller is presenting a view controller, dismiss
            presentedViewController.dismiss(animated: true, completion: {
                UIAccessibility.post(notification: .layoutChanged, argument: self)
            })
        } else {
            ImageLearningBlockPresentationViewController.present(imageBlockView: imageBlockView, from: viewController, initialFrame: screenRect)
        }
    }
    
    private func dismissPresentedViewControllerIfNeeded() {
        dismiss(animated: false, completion: nil)
    }
    
    private func updateStep(_ updates: () -> Void, completion: ((Bool) -> Void)?) {
        tableView.performBatchUpdates(updates, completion: completion)
    }
    
    private func heightOfChildren(in discloseBlock: LearningBlockCell) -> CGFloat {
        var height: CGFloat = 0.0
        for childBlockCell in childLearningBlockCells(for: discloseBlock) {
            let availableSize = CGSize(width: self.tableView.contentSize.width * LearningBlockTableViewCell.contentWidthMultiplier, height: CGFloat.greatestFiniteMagnitude)
            height += childBlockCell.sizeThatFits(availableSize).height
            if childBlockCell.learningBlock?.blockType == .group {
                height += heightOfChildren(in: childBlockCell)
            }
        }
        return height
    }
    
    private func learningBlockTableViewCell(for view: UIView) -> LearningBlockTableViewCell? {
        if let tvc = view.superview as? LearningBlockTableViewCell {
            return tvc
        }
        
        if let superview = view.superview {
            return learningBlockTableViewCell(for: superview)
        }
        
        return nil
    }
    
    public func cell(_ cell: LearningBlockCell, didChangeVisibleState visible: Bool) {
        guard cell.isLoaded, let index = learningBlockCells.firstIndex(of: cell) else { return }
        let indexPath = IndexPath(row: index, section: 0)

        updateTableViewCell(at: indexPath)
    }
    
    public func cell(_ cell: LearningBlockCell, didSubmitResponseFor learningResponse: LearningResponse) {
        guard
            let step = self.learningStepDataSource?.step,
            let trail = step.parentTrail,
            step.isAssessable
            else { return }
        
        let previousTrailAssessmentState = trail.assessmentState
        LearningAssessmentManager.shared.updateAssessmentStateFor(learningResponse, in: step)
        
        if step.assessmentState == .completedSuccessfully {
            DispatchQueue.main.async {
                self.stepHeaderView.refresh()
                let trailCompletedSuccessfully = trail.assessmentState == .completedSuccessfully
                if trailCompletedSuccessfully && (trail.assessmentState != previousTrailAssessmentState) {
                    self.stepHeaderView.celebrate()
                }
                self.delegate?.stepViewController(self, stepAssessmentStatusChanged: step)
            }
        }
    }
    
    public func cell(_ cell: LearningBlockCell, didRaiseAction url: URL, at rect: CGRect?) {
        delegate?.stepViewController(self, didRaiseAction: url, at: rect)
    }
}


// MARK: LearningBlockCellDelegate
extension LearningStepViewController: LearningStepHeaderViewDelegate {
    func stepHeaderView(_ stepHeaderView: LearningStepHeaderView, didSelectStep step: LearningStep) {
        guard let currentStep = self.learningStepDataSource?.step, step != currentStep else {
            // Already selected.
            return
        }
        delegate?.stepViewController(self, goToStep: step)
    }
}

extension LearningStepViewController: CustomCellAnimatable {
    
    var headerView: LearningStepHeaderView {
        return stepHeaderView
    }
    
    var headerTitle: UILabel {
        return stepHeaderView.textLabel
    }
    
    var contentView: UIView {
        return tableView
    }
}

extension LearningStepViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
