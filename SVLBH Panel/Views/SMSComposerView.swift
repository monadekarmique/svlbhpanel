// SVLBHPanel — Views/SMSComposerView.swift
// Semi-auto SMS PIN — ouvre le compositeur iOS pré-rempli (2FA)

import SwiftUI
import MessageUI

struct SMSComposerView: UIViewControllerRepresentable {
    let phone: String
    let pin: String
    var onDismiss: () -> Void = {}

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = [phone]
        // Format optimisé pour iOS One-Time Code autofill
        vc.body = "Votre code SVLBH est : \(pin)"
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDismiss: () -> Void
        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) { self.onDismiss() }
        }
    }

    /// Vérifie si l'appareil peut envoyer des SMS
    static var canSend: Bool { MFMessageComposeViewController.canSendText() }
}
