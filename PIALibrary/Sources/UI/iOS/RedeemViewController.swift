//
//  RedeemViewController.swift
//  PIALibrary-iOS
//
//  Created by Davide De Rosa on 5/8/18.
//  Copyright © 2018 London Trust Media. All rights reserved.
//

import UIKit
import SwiftyBeaver

private let log = SwiftyBeaver.self

class RedeemViewController: AutolayoutViewController, WelcomeChild {
    private static let codeInvalidSet = CharacterSet.decimalDigits.inverted
    
    private static let rxCodeGrouping: NSRegularExpression = try! NSRegularExpression(pattern: "\\d{4}(?=\\d)", options: [])
    
    private static let codePlaceholder = "1234-5678-9012-3456"
    
    private static let codeLength = 16

    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var labelTitle: UILabel!
    
    @IBOutlet private weak var labelSubtitle: UILabel!
    
    @IBOutlet private weak var textEmail: BorderedTextField!
    
    @IBOutlet private weak var textCode: BorderedTextField!
    
    @IBOutlet private weak var textAgreement: UITextView!

    @IBOutlet private weak var buttonRedeem: ActivityButton!
    
    @IBOutlet private weak var viewFooter: UIView!
    
    @IBOutlet private weak var viewLogin: UIView!
    
    @IBOutlet private weak var labelLogin1: UILabel!
    
    @IBOutlet private weak var labelLogin2: UILabel!

    var preset: PIAWelcomeViewController.Preset?
    
    var omitsSiblingLink: Bool = false
    
    var completionDelegate: WelcomeCompletionDelegate?

    private var redeemEmail: String?
    
    private var redeemCode: String? {
        didSet {
            guard let code = redeemCode else {
                textCode.text = nil
                return
            }
            textCode.text = friendlyRedeemCode(code)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let preset = self.preset else {
            fatalError("Preset not propagated")
        }
        
        viewFooter.isHidden = omitsSiblingLink
        
        labelTitle.text = L10n.Welcome.Redeem.title
        labelSubtitle.text = L10n.Welcome.Redeem.subtitle(RedeemViewController.codeLength)
        textEmail.placeholder = L10n.Welcome.Redeem.Email.placeholder
        textCode.placeholder = RedeemViewController.codePlaceholder
        textAgreement.attributedText = Theme.current.agreementText(
            withMessage: L10n.Welcome.Agreement.message,
            tos: L10n.Welcome.Agreement.Message.tos,
            tosUrl: Client.configuration.tosUrl,
            privacy: L10n.Welcome.Agreement.Message.privacy,
            privacyUrl: Client.configuration.privacyUrl
        )
        buttonRedeem.title = L10n.Welcome.Redeem.submit
        labelLogin1.text = L10n.Welcome.Purchase.Login.footer
        labelLogin2.text = L10n.Welcome.Purchase.Login.button
        
        buttonRedeem.accessibilityIdentifier = "uitests.redeem.submit"
        viewLogin.accessibilityLabel = "\(labelLogin1.text!) \(labelLogin2.text!)"
        textEmail.text = preset.redeemEmail
        if let code = preset.redeemCode {
            redeemCode = strippedRedeemCode(code) // will set textCode automatically
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        enableInteractions(true)
    }
    
    override func didRefreshOrientationConstraints() {
        scrollView.isScrollEnabled = (traitCollection.verticalSizeClass == .compact)
    }
    
    // MARK: Actions

    @IBAction private func redeem(_ sender: Any?) {
        guard !buttonRedeem.isRunningActivity else {
            return
        }
        
        guard let email = textEmail.text?.trimmed(), Validator.validate(email: email) else {
            let alert = Macros.alert(
                L10n.Welcome.Redeem.Error.title,
                L10n.Welcome.Purchase.Error.validation
            )
            alert.addCancelAction(L10n.Ui.Global.ok)
            present(alert, animated: true, completion: nil)
            return
        }
        guard let code = redeemCode?.trimmed(), Validator.validate(giftCode: code) else {
            let alert = Macros.alert(
                L10n.Welcome.Redeem.Error.title,
                L10n.Welcome.Redeem.Error.code(RedeemViewController.codeLength)
            )
            alert.addCancelAction(L10n.Ui.Global.ok)
            present(alert, animated: true, completion: nil)
            return
        }
        
        textEmail.text = email
        textCode.text = friendlyRedeemCode(code)
        log.debug("Redeeming...")
        
        redeemEmail = email
//        redeemCode = code
        perform(segue: StoryboardSegue.Welcome.signupViaRedeemSegue)
    }
    
    @IBAction private func logIn(_ sender: Any?) {
        guard let pageController = parent as? WelcomePageViewController else {
            fatalError("Not running in WelcomePageViewController")
        }
        pageController.show(page: .login)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == StoryboardSegue.Welcome.signupViaRedeemSegue.rawValue) {
            let nav = segue.destination as! UINavigationController
            let vc = nav.topViewController as! SignupInProgressViewController
            
            guard let email = redeemEmail else {
                fatalError("Redeeming and redeemEmail is not set")
            }
            guard let code = redeemCode else {
                fatalError("Redeeming and redeemCode is not set")
            }
            var metadata = SignupMetadata(email: email)
            metadata.title = L10n.Welcome.Redeem.title
            metadata.bodySubtitle = L10n.Signup.InProgress.Redeem.message
            vc.metadata = metadata
            vc.redeemRequest = RedeemRequest(email: email, code: friendlyRedeemCode(code))
            vc.preset = preset
            vc.completionDelegate = completionDelegate
        }
    }

    private func enableInteractions(_ enable: Bool) {
        parent?.view.isUserInteractionEnabled = enable
        if enable {
            buttonRedeem.stopActivity()
        } else {
            buttonRedeem.startActivity()
        }
    }
    
    // MARK: Helpers
    
    private func friendlyRedeemCode(_ code: String) -> String {
        return RedeemViewController.rxCodeGrouping.stringByReplacingMatches(
            in: code,
            options: [],
            range: NSMakeRange(0, code.count),
            withTemplate: "$0-"
        )
    }
    
    private func strippedRedeemCode(_ code: String) -> String {
        return code.replacingOccurrences(of: "-", with: "")
    }

    // MARK: Restylable
    
    override func viewShouldRestyle() {
        super.viewShouldRestyle()
        
        Theme.current.applyTitle(labelTitle, appearance: .dark)
        Theme.current.applySubtitle(labelSubtitle, appearance: .dark)
        Theme.current.applyInput(textEmail)
        Theme.current.applyInput(textCode)
        Theme.current.applyLinkAttributes(textAgreement)
        Theme.current.applyActionButton(buttonRedeem)
        Theme.current.applyBody1(labelLogin1, appearance: .dark)
        Theme.current.applyTextButton(labelLogin2)
    }
}

extension RedeemViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == textEmail) {
            textCode.becomeFirstResponder()
        } else if (textField == textCode) {
            redeem(nil)
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == textCode else {
            return true
        }

        // cleared input
        guard let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            redeemCode = nil
            return true
        }

        // typed/pasted invalid character and did not paste a full code with dashes
        guard (string.rangeOfCharacter(from: RedeemViewController.codeInvalidSet) == nil) || Validator.validate(giftCode: newText, withDashes: true) else {
            return false
        }
        
        let cursorLocation = textField.position(from: textField.beginningOfDocument, offset: range.location + string.count)
        let newCode = strippedRedeemCode(newText)
        guard newCode.count <= RedeemViewController.codeLength else {
            return false
        }
        redeemCode = newCode
        if let previousLocation = cursorLocation {
            textField.selectedTextRange = textField.textRange(from: previousLocation, to: previousLocation)
        }

        return false
    }
}

extension RedeemViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }
}
