//
//  PersistentStore.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 30/08/2020.
//

import SwiftUI
import CoreData

class PersistentStore: ObservableObject {
    var context: NSManagedObjectContext { persistentContainer.viewContext }
    
        // One line singleton
    static let shared = PersistentStore()
        // Mark the class private so that it is only accessible through the singleton `shared` static property
    private init() {}
    private let persistentStoreName: String = "Tsuki"
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: persistentStoreName)
        
                // OR - Include the following line for use with CloudKit - NSPersistentCloudKitContainer
        // let container = NSPersistentCloudKitContainer(name: persistentStoreName)
        // Enable history tracking
        // (to facilitate previous NSPersistentCloudKitContainer's to load as NSPersistentContainer's)
        // (not required when only using NSPersistentCloudKitContainer)
        
        guard let persistentStoreDescriptions = container.persistentStoreDescriptions.first else {
            fatalError("\(#function): Failed to retrieve a persistent store description.")
        }
        persistentStoreDescriptions.setOption(true as NSNumber,
                                              forKey: NSPersistentHistoryTrackingKey)
        persistentStoreDescriptions.setOption(true as NSNumber,
                                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error)")
            }
        })
                // Include the following line for use with CloudKit - NSPersistentCloudKitContainer
        container.viewContext.automaticallyMergesChangesFromParent = true
                // Include the following line for use with CloudKit and to set your merge policy, for example...
                container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    // MARK: - Core Data Saving and "other future" support (such as undo)
    func save() {
        let context = persistentContainer.viewContext
//        if !context.commitEditing() {
//            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
//        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                print(nserror)
            }
        }
    }
}
