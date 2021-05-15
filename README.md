# NavigationBarBackgroundHider
Helper to easily hide the navigation bar background on scrolling



## What?

Sometimes, you want to hide the background of a navigation bar until the user scrolls to a specific point. For example, you might have a header image that you want to be unobscured by the blur, until the user scrolls past it. This small library makes that easily possible.

## How?

In your view controller, call `enableNavigationBarBackgroundHiding()` to make navigation bar hiding active:


```
override func viewDidLoad() {
	// this will hide the navigation bar's background until
	// the user scrolls to the first section of the tableview
	enableNavigationBarBackgroundHiding()
}
```

If you don't have a `UITableView, you can provide your own offset provider that tells the bar hider when to hide/show the bar: just return the point where the bar should become visible:

```
override func viewDidLoad() {
	// this will make the bar's background visible when the scroll view contentOffset > 100 or 200 
	// depending on some variable. You can put any logic here, just make sure to
	// not retain `self` strongly, otherwise you have a retain cycle.
	enableNavigationBarBackgroundHiding() { [weak self] scrollView in 
		return self?.someVariable == true ? 100 : 200
	}
}
```
## Usage

In your `UIViewController` subclass, you can optionally override the following:

- override `navigationBarHidingStyle` to provide one of the default bar hiding styles. (e.g. return `.alwaysHidden` to always hide the bar)
- override `mainContentScrollViewForNavigationBarHiding` to return the `UIScrollView` to use


To enable bar hiding, call:
	- `enableNavigationBarBackgroundHiding()` 
	- or, by specifying the scroll view to use directly: `enableNavigationBarBackgroundHiding(with: someScrollView)`

You can also pass an `offset` provider callback, used to determine when to show/hide the bar:
```
enableNavigationBarBackgroundHiding(with: someScrollView) {
	return scrollView in return scrollView.contentSize.height * 0.5
}
```

To **disable** bar hiding, call:
	- `disableNavigationbarBackgroundHiding()`

To get the active bar hider, call:
	- `self.navigationBarBackgroundHider` in your view controller
	

## Customizing

The bar hider has a lot of customization points. First, call `navigationBarBackgroundHider` to get the current bar hider after enabling it.

- `isShowingBackground` you can query this property to see if the background is visible
- `update(animated:)` you can call this to do an immediate update of the background's visibility
- `addAdditionalCallback()` you can register extra callbacks that will be called when the background's visibility is toggled


- `updateHandler` you can optionally set your own handler that gets called to update the navigation bar background.
- `makeNavigationBarBackgroundTransparentHandler` you can optionally set the handler that gets called to make the bar's background transparent.
- `makeNavigationBarBackgroundVisibleHandler` you can optionally set the handler that gets called to make the bar's background visible.
- `offsetForHidingProvider` you can set a handler that determines when the bar's background will be hidden when the specified scroll view is scrolled. 

All handlers have default implementations.The default implementations are also accessible and can be called directly. You can use this to override some behaviour dynamically:
	- `defaultUpdateHandler` (calls `makeNavigationBarBackgroundTransparentHandler` and `makeNavigationBarBackgroundVisibleHandler`) when needed)
	- `defaultMakeBackgroundTransparentHandler` (calls `UINavigationItem.makeNavigationBarBackgroundTransparent()`)
	- `defaultMakeBackgroundVisibleHandler` (calls `UINavigationItem.makeNavigationBarBackgroundVisible()`)
	- `defaultOffsetForHidingProvider` (returns the offset of the first section for `UITableView`, otherwise 0)
