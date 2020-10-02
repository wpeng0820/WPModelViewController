//
//  WPModelViewController.swift
//  WPModelViewController
//
//  Created by Will Peng on 2020/10/2.
//

import Foundation
import UIKit

public protocol WPModelViewModel {
    var text: String { get }
    var detailText: String { get }
}

public class WPModelViewController: UIViewController {
    
    let tableView: UITableView = {
        let view = UITableView(frame: .zero)
        return view
    }()
    
    private let interactor: WPModelInteractor = {
        return WPModelInteractor()
    }()
    
    private let viewModels: [WPModelViewModel]
    
    private var panGestureRecongnizer: UIPanGestureRecognizer!
    
    public init(viewModels: [WPModelViewModel]) {
        self.viewModels = viewModels
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.transitioningDelegate = self
        
        self.view.addSubview(self.tableView)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([self.tableView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor), self.tableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor), self.tableView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor), self.tableView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor)])
        
        self.tableView.dataSource = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        panGestureRecongnizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(sender:)))
        panGestureRecongnizer.delegate = self
        self.tableView.addGestureRecognizer(panGestureRecongnizer)
    }
    
    @objc func handlePanGesture(sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.5
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            self.dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finish() : interactor.cancel()
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource

extension WPModelViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModels.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dataModel = self.viewModels[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = dataModel.text
        cell.detailTextLabel?.text = dataModel.detailText
        return cell
    }
}

// MARK: - UIGestureRecognizerDelegate

extension WPModelViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let panGesture = gestureRecognizer as! UIPanGestureRecognizer
        let velocity = panGesture.velocity(in: self.tableView)
        return (self.tableView.contentOffset.y <= 0 && velocity.y > 0)
    }
}

// MARK: - UIViewControllerTransitioningDelegate

extension WPModelViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return WPModelDismissAnimator()
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
