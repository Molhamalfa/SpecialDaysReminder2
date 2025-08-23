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
    
    let container = CKContainer(identifier: "iCloud.com.molham.SpecialDaysReminder")
    lazy var privateDatabase = container.privateCloudDatabase
    lazy var sharedDatabase = container.sharedCloudDatabase
    
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
            
            if shareRecord.publicPermission != .none {
                try await privateDatabase.deleteRecord(withID: shareRecord.recordID)
            } else {
                return shareRecord
            }
        }
        
        let share = CKShare(rootRecord: category.record)
        share.publicPermission = .none
        share[CKShare.SystemFieldKey.title] = category.name as CKRecordValue
        
        let _ = try await privateDatabase.modifyRecords(saving: [category.record, share], deleting: [])
        return share
    }
    
    func fetchOrCreateShare(for specialDay: SpecialDayModel) async throws -> CKShare {
        if let existingShareReference = specialDay.record.share {
            let shareRecord = try await privateDatabase.record(for: existingShareReference.recordID) as! CKShare
            
            // UPDATED: If the existing share is private (.none), delete it.
            // This forces the creation of a new public share.
            if shareRecord.publicPermission == .none {
                try await privateDatabase.deleteRecord(withID: shareRecord.recordID)
            } else {
                // If it's already a public share, just return it.
                return shareRecord
            }
        }
        
        let share = CKShare(rootRecord: specialDay.record)
        
        share.publicPermission = .readOnly
        
        share[CKShare.SystemFieldKey.title] = specialDay.name as CKRecordValue
        
        let _ = try await privateDatabase.modifyRecords(saving: [specialDay.record, share], deleting: [])
        return share
    }
    
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        return try await withCheckedThrowingContinuation { continuation in
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
