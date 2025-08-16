//
//  CloudKitSharingView.swift
//  SpecialDaysReminder
//
//  Created by YourName on Date.
//

import SwiftUI
import CloudKit
import UIKit

struct CloudKitSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let categoryToShare: SpecialDayCategory
    
    // A closure to be called when the sharing view is dismissed.
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let sharingController = UICloudSharingController(share: share, container: container)
        sharingController.delegate = context.coordinator
        // Define the permissions the user can grant (e.g., read-only or read-write).
        sharingController.availablePermissions = [.allowReadWrite, .allowReadOnly]
        return sharingController
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // This view does not need to be updated.
    }

    // The Coordinator acts as a delegate to handle events from the sharing controller.
    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        var parent: CloudKitSharingView

        init(_ parent: CloudKitSharingView) {
            self.parent = parent
        }

        // Called when the user fails to save the share.
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error.localizedDescription)")
            parent.onDismiss()
        }
        
        // Called when the user successfully saves the share.
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Successfully saved share.")
            parent.onDismiss()
        }

        // Provides a title for the sharing invitation.
        func itemTitle(for csc: UICloudSharingController) -> String? {
            return parent.categoryToShare.name
        }
    }
}
