//
//  AnnouncementsViewController.swift
//  MHacks
//
//  Created by Russell Ladd on 11/18/14.
//  Copyright (c) 2014 MHacks. All rights reserved.
//

import UIKit
import  FirebaseDatabase

class AnnouncementsViewController: UITableViewController {
	
	var announcements = [Announcement]()
	
    // MARK: Model
	
	fileprivate func fetch(completionBlock: (() -> Void)? = nil) {
		announcements.removeAll()
		
		let dbRef = Database.database().reference()
		
		dbRef.child("announcements").observe(.value, with: { (snapshot) in
			DispatchQueue.main.async(execute: {
				for child in snapshot.children {
					if let childSnapshot = child as? DataSnapshot,
						let dict = childSnapshot.value as? [String:Any]	{
						let obj = Announcement(dict)!
						if !self.announcements.contains(obj){
							self.announcements.append(obj)
						}
					}
				}
				self.tableView.reloadData()
				completionBlock?()
			})
			print("Fetched Announcements")
		})
	}
	
    // MARK: ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        refreshControl = UIRefreshControl()
		refreshControl!.addTarget(self, action: #selector(AnnouncementsViewController.refresh(_:)), for: UIControlEvents.valueChanged)
		
        tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 100.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
        navigationItem.rightBarButtonItem = nil
		
		NotificationCenter.default.addObserver(self, selector: #selector(AnnouncementsViewController.announcementsUpdated(_:)), name: APIManager.AnnouncementsUpdatedNotification, object: nil)
		
		tableView.allowsSelection = false
		tableView.allowsMultipleSelection = false
		
		if let indexPath = tableView.indexPathForSelectedRow
		{
			transitionCoordinator?.animate(alongsideTransition: { context in
				self.tableView.deselectRow(at: indexPath, animated: animated)
				}, completion: { context in
					if context.isCancelled {
						self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
					}
			})
		}
		fetch()
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Actions/Notifications
	
	func refresh(_ sender: UIRefreshControl) {
		
		fetch {
			sender.endRefreshing()
		}
	}
	
	func announcementsUpdated(_ notification: Notification? = nil) {
		DispatchQueue.main.async(execute: {
			CATransaction.begin()
			self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
			CATransaction.commit()
		})
	}
	
    // MARK: Table View Data
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.announcements.count
    }
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Announcement Cell", for: indexPath) as! AnnouncementCell
        let announcement = announcements[(indexPath as NSIndexPath).row]

		cell.selectionStyle = .none
        cell.title.text = announcement.title
        cell.date.text = announcement.localizedDate
        cell.message.text = announcement.message

		cell.colorView.backgroundColor = announcement.category.color

		cell.sponsored.isHidden = !announcement.isSponsored
		cell.unapproved.isHidden = !announcement.approved && APIManager.shared.canEditAnnouncements ? false : true

        return cell
    }
}
