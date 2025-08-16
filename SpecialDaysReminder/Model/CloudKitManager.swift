//
//  CloudKitManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import CloudKit
import Combine

// This enum defines the names of our record types in the CloudKit schema.
enum CloudKitRecordType: String {
    case category = "Category"
    case specialDay = "SpecialDay"
}

class CloudKitManager {
    
    static let shared = CloudKitManager()
    
    // The container needs to be public so the sharing view can access it.
    let container = CKContainer.default()
    
    lazy var privateDatabase = container.privateCloudDatabase
    lazy var sharedDatabase = container.sharedCloudDatabase
    
    let accountStatusPublisher = PassthroughSubject<CKAccountStatus, Error>()
    
    private init() {
        checkAccountStatus()
    }
    
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            if let error = error {
                print("Error checking CloudKit account status: \(error.localizedDescription)")
                self?.accountStatusPublisher.send(completion: .failure(error))
                return
            }
            
            DispatchQueue.main.async {
                print("CloudKit Account Status: \(status.rawValue)")
                self?.accountStatusPublisher.send(status)
            }
        }
    }
    
    // NEW: Function to prepare a category for sharing.
    func fetchOrCreateShare(for category: SpecialDayCategory) async throws -> CKShare {
        // First, check if a share already exists for this category record.
        if let existingShareReference = category.record.share {
            let shareRecord = try await privateDatabase.record(for: existingShareReference.recordID) as! CKShare
            return shareRecord
        }
        
        // If no share exists, create a new one.
        let share = CKShare(rootRecord: category.record)
        share.publicPermission = .readOnly // Default permission
        
        // The title will appear in the share invitation.
        share[CKShare.SystemFieldKey.title] = category.name as CKRecordValue
        
        // Save the new share record to CloudKit.
        // We must also save the root record (the category) again because we've associated a share with it.
        let _ = try await privateDatabase.modifyRecords(saving: [category.record, share], deleting: [])
        
        return share
    }
}
