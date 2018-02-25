//
//  CountdownViewController.swift
//  MHacks
//
//  Created by Russell Ladd on 11/12/14.
//  Copyright (c) 2014 MHacks. All rights reserved.
//

import UIKit
import FirebaseDatabase

class CountdownViewController: UIViewController {

	@IBOutlet weak var progressIndicator: CircularProgressIndicator!
	@IBOutlet weak var countdownLabel: UILabel!
	@IBOutlet weak var startLabel: UILabel!
	@IBOutlet weak var endLabel: UILabel!
	
	// Delays the initial filling animation by second
	var firstAppearanceDate: Date?
	var configuration = Configuration()
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment this for screenshots
		//progressIndicator.progressColor = UIColor.clear
		
		countdownLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 120.0, weight: UIFontWeightThin)
		observeConfigeration()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NotificationCenter.default.addObserver(self, selector: #selector(CountdownViewController.updateCountdownViews(_:)), name: APIManager.ConfigurationUpdatedNotification, object: nil)
		observeConfigeration()
		
		if firstAppearanceDate == nil {
			firstAppearanceDate = Date()
		}
		
		beginUpdatingCountdownViews()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		stopUpdatingCountdownViews()
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - Model Update
	
	var timer: Timer?
	
	func beginUpdatingCountdownViews() {
		
		updateCountdownViews()
		// FIXME: Use swift method instead?
		let nextSecond = (Calendar.current as NSCalendar).nextDate(after: Date(), matching: .nanosecond, value: 0, options: .matchNextTime)!
		
		let timer = Timer(fireAt: nextSecond, interval: 1.0, target: self, selector: #selector(CountdownViewController.timerFire(_:)), userInfo: nil, repeats: true)
		
		RunLoop.main.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
		
		self.timer = timer
	}
	
	func timerFire(_ timer: Timer) {
		updateCountdownViews()
	}
	
	func stopUpdatingCountdownViews() {
		timer?.invalidate()
		timer = nil
	}
	
	// MARK: - UI Update
	
	func updateCountdownViews(_: Notification) {
		
		DispatchQueue.main.async {
			self.updateCountdownViews()
		}
	}
	
	func observeConfigeration() {
		let dbRef = Database.database().reference()
		
		dbRef.child("configeration").observe(.value, with: { (snapshot) in
			if let childsnapshot = snapshot.value as? [String:Any] {
				print(childsnapshot)
				_ = self.configuration.updateWith(childsnapshot)
				print("start",self.configuration.startDate,"end",self.configuration.endDate)
			}
		}) { (errorMessage) in
			NotificationCenter.default.post(name: APIManager.FailureNotification, object: errorMessage)
		}
	}
	
	func updateCountdownViews() {

		if let firstAppearanceDate = firstAppearanceDate , firstAppearanceDate.timeIntervalSinceNow < -0.5 {
			progressIndicator.setProgress(configuration.progress(), animated: true)
		}
		
		countdownLabel.text = configuration.timeRemainingDescription
		startLabel.text = configuration.startDateDescription
		endLabel.text = configuration.endDateDescription
	}
}

