//
//  LearningTrailDataSource.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCCore

public protocol LearningTrailDataSource {
    var trail: LearningTrail { get }
    var stepCount: Int  { get }
    var dataSourceProviderForStep: ((LearningStep) -> LearningStepDataSource) { get set }
    init(trail: LearningTrail)
    func viewControllerForStep(at index: Int) -> UIViewController?
    func index(of stepViewController: UIViewController) -> Int?
    func index(of step: LearningStep) -> Int?
    func refreshSteps()
    func liveRefresh()
}

open class DefaultLearningTrailDataSource: LearningTrailDataSource {
    private lazy var stepViewControllers: [LearningStepViewController] = {
        var viewControllers = [LearningStepViewController]()
        for step in trail.steps {
            let stepViewController = LearningStepViewController()
            stepViewController.learningStepDataSource = dataSourceProviderForStep(step)
            viewControllers.append(stepViewController)
        }
        return viewControllers
    }()
    
    public var trail: LearningTrail
    
    open var dataSourceProviderForStep: ((LearningStep) -> LearningStepDataSource) = { step in
        return DefaultLearningStepDataSource(step: step)
    }
    
    private var fileMonitor: FileMonitor?

    public convenience init() {
        self.init(trail: LearningTrail())
    }
    
    public required init(trail: LearningTrail) {
        self.trail = trail
        
        if LearningTrails.isAuthoringSupportEnabled, let url = trail.url {
            fileMonitor = FileMonitor(url: url, eventMask: [.write], eventHandler: {
                DispatchQueue.main.async {
                    self.liveRefresh()
                }
            })
        }
    }
    
    deinit {
        fileMonitor = nil
    }
    
    public var stepCount: Int {
        return trail.steps.count
    }
    
    open func viewControllerForStep(at index: Int) -> UIViewController? {
        guard index >= 0, index < trail.steps.count else { return nil }
        return stepViewControllers[index]
    }
    
    open func index(of stepViewController: UIViewController) -> Int? {
        guard let stepViewController = stepViewController as? LearningStepViewController else { return nil }
        return stepViewControllers.firstIndex(of: stepViewController)
    }
    
    open func index(of step: LearningStep) -> Int? {
        return trail.steps.firstIndex(where: {$0 === step})
    }
    
    open func refreshSteps() {
        stepViewControllers.forEach( { $0.refreshStep() } )
    }
    
    open func liveRefresh() {
        guard LearningTrails.isAuthoringSupportEnabled else { return }
        
        let freshTrail = LearningTrail()
        freshTrail.load(completion: { success in

            guard success else { return }
            
            self.trail.updateStepsFrom(trail: freshTrail, completion: { updatedIndexes in
                
                for index in updatedIndexes {
                    guard index < self.stepViewControllers.count else { continue }
                    PBLog("Refreshing step: \(index)")
                    let step = self.trail.steps[index]
                    let stepViewController = self.stepViewControllers[index]
                    stepViewController.learningStepDataSource = self.dataSourceProviderForStep(step)
                    stepViewController.refreshStep()
                }
            })
            
        })
    }
}
