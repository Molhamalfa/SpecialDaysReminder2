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
        
        // UPDATED: All explicit permission configuration has been removed.
        // The controller will now use its default behavior based on the share object it receives.
        // Since the CloudKitManager now creates a private share, the controller will
        // automatically show the "Add People" button in the management view.
        
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
