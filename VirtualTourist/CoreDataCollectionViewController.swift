//
//  CoreDataCollectionViewController.swift
//  VirtualTourist
//
//  Created by Gaurav Saraf on 1/16/17.
//  Copyright © 2017 Gaurav Saraf. All rights reserved.
//

import Foundation
import UIKit
import CoreData

// MARK: - CoreDataTableViewController: UICollectionViewController

class CoreDataCollectionViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var insertedItemsIndexPath = [IndexPath]()
    var deletedItemsIndexPath = [IndexPath]()
    var updatedItemsIndexPath = [IndexPath]()
    
    var delegate = UIApplication.shared.delegate as! AppDelegate
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - CoreDataTableViewController (Table Data Source)

extension CoreDataCollectionViewController {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let fc = fetchedResultsController {
            fc.managedObjectContext.delete(fc.object(at: indexPath) as! NSManagedObject)
            delegate.stack.save()
        }
    }
}

// MARK: - CoreDataTableViewController (Fetches)

extension CoreDataCollectionViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK: - CoreDataTableViewController: NSFetchedResultsControllerDelegate

extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedItemsIndexPath.removeAll()
        deletedItemsIndexPath.removeAll()
        updatedItemsIndexPath.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            insertedItemsIndexPath.append(newIndexPath!)
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.deleteItems(at: [indexPath!])
            collectionView.insertItems(at: [newIndexPath!])
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ () -> Void in
            self.collectionView.insertItems(at: self.insertedItemsIndexPath)
            self.collectionView.deleteItems(at: self.deletedItemsIndexPath)
            self.collectionView.reloadItems(at: self.updatedItemsIndexPath)
        }, completion: nil)
    }
}

