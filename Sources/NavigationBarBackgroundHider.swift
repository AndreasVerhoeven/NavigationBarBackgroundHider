//
//  NavigationBarBackgroundHider.swift
//  NavigationBarBackgroundHider
//
//  Created by Andreas Verhoeven on 13/05/2021.
//

import UIKit
import ObjectiveC.runtime

extension UIViewController {
	/// UIViewController subclasses can override this to automatically get an appropriate hiding style
	@objc public var navigationBarHidingStyle: NavigationBarBackgroundHider.NavigationBarHidingStyle {
		return .unknown
	}

	/// The main content UIScrollView to use for navigation bar hiding
	@objc var mainContentScrollViewForNavigationBarHiding: UIScrollView? {
		return viewIfLoaded as? UIScrollView ?? view.subviews.first as? UIScrollView
	}

	private static var navigationbarAssociatedObjectKey = 0

	/// the navigation bar background hider for this view controller, if enabled, nil otherwise.
	public var navigationBarBackgroundHider: NavigationBarBackgroundHider? {
		get {objc_getAssociatedObject(self, &Self.navigationbarAssociatedObjectKey) as? NavigationBarBackgroundHider}
		set {objc_setAssociatedObject(self, &Self.navigationbarAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
	}


	/// call this to enable navigation bar hiding for this view controller when scrolling the given scrollview.
	/// If called twice, will replace the existing hider in this view controller.
	///
	/// - Parameters:
	///		- scrollView: **optional** the scrollview to use for hiding
	///		- offsetForHidingProvider: **optional** a block that provides the offset for when to make the bar visible again. Can be nil.
	/// - Returns: the created NavigationBarBackgroundHider
	@discardableResult public func enableNavigationBarBackgroundHiding(with scrollView: UIScrollView? = nil, offsetForHidingProvider: NavigationBarBackgroundHider.OffsetForHidingProvider? = nil) -> NavigationBarBackgroundHider {
		let hider = NavigationBarBackgroundHider(viewController: self, scrollView: scrollView)
		hider.offsetForHidingProvider = offsetForHidingProvider
		navigationBarBackgroundHider = hider
		return hider
	}

	/// Disables navigation bar background hiding for this view controller
	public func disableNavigationBarBackgroundHiding() {
		navigationBarBackgroundHider = nil
	}
}

extension UINavigationItem {
	/// Configures this navigation item to have a default background
	///
	/// - Parameters:
	///		- navigationBar: **optional** if defined, will be used to set the `appearance`s of this item when they are not yet defined
	public func makeNavigationBarBackgroundVisible(in navigationBar: UINavigationBar? = nil) {
		configureForBarHiding(in: navigationBar)
		standardAppearance?.configureWithDefaultBackground()
		compactAppearance?.configureWithDefaultBackground()
	}

	/// Configures this navigation item to have a transparent background
	///
	/// - Parameters:
	///		- navigationBar: **optional** if defined, will be used to set the `appearance`s of this item when they are not yet defined
	public func makeNavigationBarBackgroundTransparent(in navigationBar: UINavigationBar? = nil) {
		configureForBarHiding(in: navigationBar)
		standardAppearance?.configureWithTransparentBackground()
		compactAppearance?.configureWithTransparentBackground()
	}

	/// Configures this navigation hiding for bar hiding by assigning the `standardAppearance` and `compactAppearance` when needed
	///
	/// - Parameters:
	///		- navigationBar: if defined, will be used to set the `appearance`s of this item when they are not yet defined
	public func configureForBarHiding(in navigationBar: UINavigationBar?) {
		if standardAppearance == nil {
			standardAppearance = navigationBar?.standardAppearance ?? UINavigationBarAppearance()
		}

		if compactAppearance == nil {
			compactAppearance = navigationBar?.compactAppearance ?? UINavigationBarAppearance()
		}
	}

	/// Handler to update the navigation item
	public typealias BarUpdateHandler = (_ navigationItem: UINavigationItem) -> Void

	/// Default handler to update the navigation bar background
	///
	/// - Parameters:
	///		- shouldBeVisible: if true, we will make the background visible, otherwise we will hide it
	///		- navigationBar: the navigation bar to animate in. Can be nil
	///		- animated: if yes, we will animate the changes
	///		- animateAlongSide: **optional** a handler that will be called when we perform the hide/show animation
	///		- makeVisibleHandler: **optional** if defined, this will be called to make the background visible. If nil, the default handler will be used.
	///		- makeTransparentHandler: **optional** if defined, this will be called to make the background transparent. If nil, the default handler will be used.
	public func updateNavigationBarBackgroundVisibility(shouldBeVisible: Bool,
														in navigationBar: UINavigationBar?,
														animated: Bool,
														animateAlongSide: (() -> Void)? = nil,
														makeVisibleHandler: BarUpdateHandler? = nil,
														makeTransparentHandler: BarUpdateHandler? = nil) {
		let update = {
			if shouldBeVisible == true {
				makeVisibleHandler?(self) ?? self.makeNavigationBarBackgroundVisible(in: navigationBar)
			} else {
				makeTransparentHandler?(self) ?? self.makeNavigationBarBackgroundTransparent(in: navigationBar)
			}
			animateAlongSide?()
		}

		if let navigationBar = navigationBar, animated == true {
			UIView.transition(with: navigationBar, duration: 0.25, options: [.beginFromCurrentState, .allowAnimatedContent, .allowUserInteraction, .transitionCrossDissolve], animations: update, completion: nil)
		} else {
			update()
		}
	}
}


/// Class that hides / shows a navigation bar background based on a scroll offset in a UIScrollView
public class NavigationBarBackgroundHider: NSObject {

	/// The hiding style to use
	@objc public enum NavigationBarHidingStyle: Int {
		/// no defined style
		case unknown

		/// we hide the background automatically based on the scroll offset
		case automatic

		/// background is always visible
		case alwaysVisible

		/// background is always hidden
		case alwaysHidden
	}


	/// handler to update the current navigation bar, if not set, `defaultUpdateHandler` will
	/// be used
	public var updateHandler: UpdateHandler?
	public typealias UpdateHandler = (_ hider: NavigationBarBackgroundHider, _ animated: Bool) -> Void

	/// the view controller this hider is handling
	public weak var viewController: UIViewController?

	/// the default bar hiding style
	public var defaultStyle = NavigationBarHidingStyle.automatic

	private var additionalCallbacks = Dictionary<UUID, UpdateHandler>()

	/// This can be used to remove a callback
	public struct Cancellable {
		internal let uuid: UUID
		internal weak var hider: NavigationBarBackgroundHider?

		///
		public func cancel() {
			hider?.additionalCallbacks.removeValue(forKey: uuid)
		}
	}


	/// Registers an additional callback that will be called when the bar background is changed.
	/// Can be removed by calling `.cancel()` on the returned `Cancellable`
	///
	/// - Parameters:
	///		- callback: the callback to call when the bar background is changed
	/// - Returns: A `Cancellable` that can be used to remove the callback
	public func addAdditionalCallback(_ callback: @escaping UpdateHandler) -> Cancellable {
		let cancellable = Cancellable(uuid: UUID(), hider: self)
		additionalCallbacks[cancellable.uuid] = callback
		return cancellable
	}

	/// The default bar update handler that calls `navigationItem.updateNavigationBarBackgroundVisibility()`
	public let defaultUpdateHandler: UpdateHandler = {hider, animated in
		guard let viewController = hider.viewController else {return}

		let showHandler: BarUpdateHandler = { hider.makeNavigationBarBackgroundVisibleHandler?($0) ?? hider.defaultMakeBackgroundVisibleHandler($0)}
		let hideHandler: BarUpdateHandler = { hider.makeNavigationBarBackgroundTransparentHandler?($0) ?? hider.defaultMakeBackgroundTransparentHandler($0)}

		viewController.navigationItem.updateNavigationBarBackgroundVisibility(shouldBeVisible: hider.isShowingBackground,
																			  in: viewController.navigationController?.navigationBar,
																			  animated: animated,
																			  makeVisibleHandler: showHandler,
																			  makeTransparentHandler: hideHandler)
	}


	/// the handler for making the bar background visible/hidden
	public typealias BarUpdateHandler = UINavigationItem.BarUpdateHandler

	/// handler that will be used to make the bar transparent in `defaultUpdateHandler`.
	/// If nil, `defaultMakeBackgroundTransparentHandler`, will be used.
	public var makeNavigationBarBackgroundTransparentHandler: BarUpdateHandler?

	/// handler that will be used to make the bar visible in `defaultUpdateHandler`.
	/// If nil, `defaultMakeBackgroundVisibleHandler`, will be used.
	public var makeNavigationBarBackgroundVisibleHandler: BarUpdateHandler?

	/// the default handler for making the bar transparent.
	public let defaultMakeBackgroundTransparentHandler: BarUpdateHandler = {$0.makeNavigationBarBackgroundTransparent()}

	/// the default handler for making the bar visible.
	public let defaultMakeBackgroundVisibleHandler: BarUpdateHandler = {$0.makeNavigationBarBackgroundVisible()}

	/// the scrollview we are observing
	private weak var observedScrollView: UIScrollView?
	private var scrollViewObserverKey: UInt = 0
	private var ignoreScrollChanges = false

	/// True if we are showing the bar background
	public private(set) var isShowingBackground = true

	/// Offset provider. Used to provide the offset in a scrollview where we should show the bar
	public typealias OffsetForHidingProvider = (UIScrollView) -> CGFloat


	/// the default offset provider: will make the bar visible if the first section scrolls behind the navigation bar in a UITableView.
	public let defaultOffsetForHidingProvider: OffsetForHidingProvider = { scrollView -> CGFloat in
		guard let tableView = scrollView as? UITableView, tableView.numberOfSections > 0 && tableView.tableHeaderView == nil else {return CGFloat(0)}
		return tableView.rect(forSection: 0).minY
	}

	/// the offset provider to use. The offset provider should return the offset in the UIScrollView where we should
	/// make the navigation bar's background transparent. If nil, will use `defaultOffsetForHidingProvider`
	public var offsetForHidingProvider: OffsetForHidingProvider?

	/// Creates a new bar hider
	///
	/// - Parameters:
	///		- viewController: the view controller to change the navigation bar background for
	///		- scrollView: the scrollview to observe for scroll changes
	public init(viewController: UIViewController, scrollView: UIScrollView? = nil) {
		self.viewController = viewController
		self.observedScrollView = scrollView ?? viewController.mainContentScrollViewForNavigationBarHiding
		super.init()

		viewController.navigationItem.configureForBarHiding(in: viewController.navigationController?.navigationBar)

		observedScrollView?.addObserver(self, forKeyPath: "bounds", options: .new, context: &scrollViewObserverKey)
		updateNavigationBarBackground(animated: false)
	}

	deinit {
		observedScrollView?.removeObserver(self, forKeyPath: "bounds", context: &scrollViewObserverKey)
	}

	/// Updates the navigation bar background immediately
	///
	/// - Parameters:
	///		- animated: if true, we will animate the changes
	public func update(animated: Bool) {
		updateNavigationBarBackground(animated: animated, forced: true)
	}

	// MARK: - Private
	private func actualHidingStyle(for viewController: UIViewController) -> NavigationBarHidingStyle {
		let style = viewController.navigationBarHidingStyle
		switch style {
			case .alwaysHidden, .alwaysVisible, .automatic: return style
			case .unknown: return defaultStyle
		}
	}

	private func shouldBarBackgroundBeVisible(for scrollView: UIScrollView, in viewController: UIViewController) -> Bool {
		switch actualHidingStyle(for: viewController) {
			case .alwaysHidden: return false
			case .alwaysVisible: return true
			case .automatic, .unknown:

				let offset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
				return offset > scrollOffsetForHidingNavigationBar(for: scrollView)
		}
	}

	private func scrollOffsetForHidingNavigationBar(for scrollView: UIScrollView) -> CGFloat {
		return offsetForHidingProvider?(scrollView) ?? defaultOffsetForHidingProvider(scrollView)
	}

	private func updateNavigationBarBackground(animated: Bool, forced: Bool = false) {
		guard ignoreScrollChanges == false else {return}
		guard let scrollView = observedScrollView else {return}
		guard let viewController = viewController else {return}

		ignoreScrollChanges = true
		defer {ignoreScrollChanges = false}

		let shouldShowBackground = shouldBarBackgroundBeVisible(for: scrollView, in: viewController)
		guard shouldShowBackground != isShowingBackground || forced == true else {return}
		isShowingBackground = shouldShowBackground
		updateHandler?(self, animated) ?? defaultUpdateHandler(self, animated)
		additionalCallbacks.forEach {$0.value(self, animated)}
	}

	// MARK: - NSObject
	public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard context == &scrollViewObserverKey else {return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)}
		updateNavigationBarBackground(animated: true)
	}
}
