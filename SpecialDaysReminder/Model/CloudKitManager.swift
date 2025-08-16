//
//  CloudKitManager.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import Foundation
import CloudKit
import Combine

enum CloudKitRecordType: String {
    case category = "Category"
    case specialDay = "SpecialDay"
}

class CloudKitManager {
    
    static let shared = CloudKitManager()
    
    // UPDATED: Changed from CKContainer.default() to an explicit identifier.
    // This is the most robust way to ensure the app connects to the correct
    // CloudKit container and resolves deep-seated permission issues.
    let container = CKContainer(identifier: "iCloud.com.molham.SpecialDaysReminder")
    
    // FIXED: Corrected the property to use the modern 'privateCloudDatabase' method.
    lazy var privateDatabase = container.privateCloudDatabase
    
    let accountStatusPublisher = PassthroughSubject<CKAccountStatus, Error>()
    
    private init() {
        checkAccountStatus()
    }
    
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            if let error = error {
                self?.accountStatusPublisher.send(completion: .failure(error))
                return
            }
            DispatchQueue.main.async {
                self?.accountStatusPublisher.send(status)
            }
        }
    }
    
    func fetchOrCreateShare(for category: SpecialDayCategory) async throws -> CKShare {
        if let existingShareReference = category.record.share {
            let shareRecord = try await privateDatabase.record(for: existingShareReference.recordID) as! CKShare
            
            // If an old public share exists, delete it so we can create a new private one.
            if shareRecord.publicPermission != .none {
                try await privateDatabase.deleteRecord(withID: shareRecord.recordID)
            } else {
                // This is already a private share, so we can just return it.
                return shareRecord
            }
        }
        
        // Create a new share record.
        let share = CKShare(rootRecord: category.record)
        
        // REVERTED: Changed back to .none to create a private share.
        // This will show the management view with the "Add People" button.
        share.publicPermission = .none
        
        share[CKShare.SystemFieldKey.title] = category.name as CKRecordValue
        
        let _ = try await privateDatabase.modifyRecords(saving: [category.record, share], deleting: [])
        return share
    }
    
    // Function to accept a share invitation.
    func acceptShare(metadata: CKShare.Metadata) async throws {
        // FIXED: Corrected typo from 'shareMetatas' to 'shareMetadatas'.
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        return try await withCheckedThrowingContinuation { continuation in
            // FIXED: Added explicit type for 'result' to resolve compiler ambiguity.
            operation.acceptSharesResultBlock = { (result: Result<Void, Error>) in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            container.add(operation)
        }
    }
}
