import UIKit
import MessageUI

extension NSError {
    
    public func alertMessage() -> String {
        if(self.wmf_isNetworkConnectionError()){
            return WMFLocalizedString("alert-no-internet", value:"There's no internet connection", comment:"Message shown in an alert banner when there is no connection to the internet.")
        }else{
            return self.localizedDescription
        }
    }
    
    public func alertType() -> RMessageType {
        if(self.wmf_isNetworkConnectionError()){
            return .warning
        }else{
            return .error
        }
    }

}


open class WMFAlertManager: NSObject, RMessageProtocol, MFMailComposeViewControllerDelegate {
    
    @objc open static let sharedInstance = WMFAlertManager()

    override init() {
        super.init()
        RMessage.shared().delegate = self
    }
    
    
    @objc open func showInTheNewsAlert(_ message: String?, sticky:Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        if (message ?? "").isEmpty {
            return
        }
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            let title = WMFLocalizedString("in-the-news-title", value:"In the news", comment:"Title for the 'In the news' notification & feed section")
            RMessage.showNotification(in: nil, title: title, subtitle: message, iconImage: UIImage(named:"trending-notification-icon"), type: .normal, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }
    

    @objc open func showAlert(_ message: String?, sticky:Bool, dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
    
         if (message ?? "").isEmpty {
             return
         }
         self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .normal, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    @objc open func showSuccessAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .success, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)

        })
    }

    @objc open func showWarningAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .warning, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    @objc open func showErrorAlert(_ error: NSError, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: error.alertMessage(), subtitle: nil, iconImage: nil, type: .error, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }
    
    @objc open func showErrorAlertWithMessage(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (() -> Void)?) {
        
        self.showAlert(dismissPreviousAlerts, alertBlock: { () -> Void in
            RMessage.showNotification(in: nil, title: message, subtitle: nil, iconImage: nil, type: .error, customTypeName: nil, duration: sticky ? -1 : 2, callback: tapCallBack, buttonTitle: nil, buttonCallback: nil, at: .top, canBeDismissedByUser: true)
        })
    }

    @objc func showAlert(_ dismissPreviousAlerts:Bool, alertBlock: @escaping ()->()){
        
        if(dismissPreviousAlerts){
            dismissAllAlerts {
                alertBlock()
            }
        }else{
            alertBlock()
        }
    }
    
    @objc open func dismissAlert() {
        RMessage.dismissActiveNotification()
    }

    @objc open func dismissAllAlerts(_ completion: @escaping () -> Void = {}) {
        guard RMessage.isNotificationActive() else {
            completion()
            return
        }
        RMessage.dismissActiveNotification {
            self.dismissAllAlerts(completion)
        }
    }

    @objc open func customize(_ messageView: RMessageView!) {

    }
    
    @objc open func showEmailFeedbackAlertViewWithError(_ error: NSError) {
       let message = WMFLocalizedString("request-feedback-on-error", value:"The app has encountered a problem that our developers would like to know more about. Please tap here to send us an email with the error details.", comment:"Displayed to beta users when they encounter an error we'd like feedback on")
        showErrorAlertWithMessage(message, sticky: true, dismissPreviousAlerts: true) {
            self.dismissAllAlerts()
            if MFMailComposeViewController.canSendMail() {
                guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                    return
                }
                let vc = MFMailComposeViewController()
                vc.setSubject("Bug:\(WikipediaAppUtils.versionedUserAgent())")
                vc.setToRecipients(["mobile-ios-wikipedia@wikimedia.org"])
                vc.mailComposeDelegate = self
                vc.setMessageBody("Domain:\t\(error.domain)\nCode:\t\(error.code)\nDescription:\t\(error.localizedDescription)\n\n\n\nVersion:\t\(WikipediaAppUtils.versionedUserAgent())", isHTML: false)
                rootVC.present(vc, animated: true, completion: nil)
            } else {
                self.showErrorAlertWithMessage(WMFLocalizedString("no-email-account-alert", value:"Please setup an email account on your device and try again.", comment:"Displayed to the user when they try to send a feedback email, but they have never set up an account on their device"), sticky: false, dismissPreviousAlerts: false) {
                    
                }
            }
        }
    }
    
    @objc open func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
