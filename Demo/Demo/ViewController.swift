//
//  ViewController.swift
//  Demo
//
//  Created by Andreas Verhoeven on 16/05/2021.
//

import UIKit

class ViewController: UITableViewController {
	var offsetIndexPath: IndexPath?

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "A List"

		// this table view has a header view: when the header view is visible,
		// we'll not show the navigation bar's background. When the header view scrolls behind
		// the navigation bar, we make its background visible.
		tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
		tableView.tableHeaderView?.backgroundColor = .red

		// We do this by enabling navigation bar hiding. We provide a custom offset provider here:
		// if you tap on an item in the list, we'll make the bar's background visible when that
		// specific row scrolls behind the navigation bar only.
		enableNavigationBarBackgroundHiding() { [weak self] scrollView in
			guard let self = self else { return 0 }
			if let indexPath = self.offsetIndexPath {
				return self.tableView.rectForRow(at: indexPath).minY
			} else {
				return self.tableView.rect(forSection: 0).minY
			}
		}
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 10
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 5
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
		cell.textLabel?.text = String(describing: indexPath)
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		offsetIndexPath = indexPath
		navigationBarBackgroundHider?.update(animated: true)
	}
}

