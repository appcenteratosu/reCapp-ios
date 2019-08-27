//
//  EULAViewController.swift
//  reCap
//
//  Created by Luke Davis on 8/25/19.
//  Copyright © 2019 Kaleb Cooper. All rights reserved.
//

import Foundation
import UIKit

protocol EULAViewControllerDelegate {
    func didAgree(controller: EULAViewController)
    func didCancel(controller: EULAViewController)
}

class EULAViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate {
    
    public var delegate: EULAViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
    }
    
    // MARK: Properties
    public var EULAText: String? {
        willSet {
            EULAView.text = newValue
        }
    }
    public var EULAAttributedText: NSAttributedString? {
        willSet {
            EULAView.attributedText = newValue
        }
    }
    
    // MARK: Fields
    private let EULAView: UITextView = {
        let tf = UITextView()
        tf.isEditable = false
        tf.dataDetectorTypes = [.all]
        tf.font = UIFont(name: "Helvetica", size: 22)
        tf.layer.cornerRadius = 5
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .green
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: Setup
    private func setup() {
        view.backgroundColor = .white
        
        setupEULATextView()
        setupButtons()
        
        EULAAttributedText = TestClass.formatted
    }
    
    private func setupEULATextView() {
        EULAView.delegate = self
        view.addSubview(EULAView)
        
        NSLayoutConstraint.activate([
            EULAView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            EULAView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            EULAView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])
    }
    
    private func setupButtons() {
        confirmButton.setTitle("Agree", for: .normal)
        confirmButton.addTarget(self, action: #selector(agree), for: .touchUpInside)
        confirmButton.isEnabled = false
        confirmButton.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        
        cancelButton.setTitle("Disagree", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        
        view.addSubview(confirmButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            cancelButton.widthAnchor.constraint(equalToConstant: 100),
            cancelButton.heightAnchor.constraint(equalToConstant: 36),
            cancelButton.leadingAnchor.constraint(equalTo: EULAView.leadingAnchor, constant: 0),
            cancelButton.topAnchor.constraint(equalTo: EULAView.bottomAnchor, constant: 16),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            
            confirmButton.heightAnchor.constraint(equalToConstant: 36),
            confirmButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 16),
            confirmButton.trailingAnchor.constraint(equalTo: EULAView.trailingAnchor, constant: 0),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
        
    }
    
    // MARK: Class Methods
    @objc private func cancel() {
        delegate?.didCancel(controller: self)
    }
    
    @objc private func agree() {
        delegate?.didAgree(controller: self)
    }

    private var reachedBottom = false {
        willSet {
            confirmButton.isEnabled = true
            confirmButton.backgroundColor = UIColor.green
        }
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if reachedBottom == false {
            if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height {
                reachedBottom = true
                print("Reached Bottom")
            }
        }
    }

}


class TestClass {
    static let eula = """

reCapp End-User License Agreement
for mobile application software designed to operate on an Apple Device
This End-User License Agreement ( “Agreement”) (i) governs Your download and use of mobile application software and any enhancement or modification thereof (“Software”) provided by Oklahoma State University (“the University”) that is designed to operate on a computing device marketed or manufactured by Apple Inc. that you own or control (“Your Apple Device”), including Your iPhone, iPod Touch, iPad, HomePod, Apple TV, or Apple Watch; (ii) applies to any systems, servers, devices, services, and other items related to the Software; The terms “You,” “Your,” “Yours,” and “End-User” refer to any individual who downloads and/or uses the Software.
Your download and/or use of the Software  constitutes Your acceptance of the terms and conditions of this Agreement, which may be amended from time to time by the University.  The most recent version of this Agreement will always be available on the internet at the web address http://tdc.okstate.edu/EULA and the most recent version shall supersede any and all other versions of this Agreement.  The University reserves the right to modify this Agreement at any time in its sole discretion by posting revisions on the internet at the web address http://tdc.okstate.edu/EULA.  Continued use of the Software  following the posting of these modifications will constitute acceptance of such modifications by You, the end-user.
1.    Acknowledgement. The University and You acknowledge that this Agreement is entered into by and between the University and You and not with Apple Inc. (“Apple”).  Notwithstanding the foregoing, You acknowledge that Apple and its subsidiaries are third-party beneficiaries of this Agreement and that upon Your acceptance of the terms and conditions of this Agreement, Apple will have the right (and will be deemed to have accepted the right) to enforce this Agreement against You.  The University is solely responsible for the Software and any content contained therein. You acknowledge that Apple has no obligation whatsoever to furnish any maintenance or services with respect to the Software.  You acknowledge that you have reviewed the Apple Media Services Terms and Conditions (“Apple Terms and Conditions”) available at the web address http://www.apple.com/legal/internet-services/itunes/appstore/jm/terms.html).
2.    End-User Representations and Warranties. You represent and warrant that (i) You are not located in a country that is subject to a U.S. Government embargo, or that has been designated by the U.S. Government as a “terrorist supporting” country; and (ii) You are not listed on any U.S. Government “watch list” of prohibited or restricted parties, including, without limitation, the Specially Designated Nationals list published by the Office of Foreign Assets Control of the U.S. Treasury and the Denied Persons List published by the U.S. Department of Commerce; and (iii) You are at least eighteen (18) years old.
3.    Incorporation of Apple’s Licensed Application End User License Agreement.  This Agreement incorporates by reference the Licensed Application End User License Agreement (the “LAEULA”) published by Apple at the web address http://www.apple.com/legal/itunes/appstore/dev/stdeula/. For purposes of this Agreement, the Software is considered the “Licensed Application” as defined in the LAEULA and the University is considered the “Application Provider” as defined in the LAEULA.  If any terms of this Agreement conflict with the terms of the LAEULA, the terms of this Agreement shall control.
4.    Scope of License and Allowable Uses of the Software.  The license granted to You for the Software is limited to a revocable, non-transferable, non-exclusive license to use the Software on any Apple Device that You own or control and as permitted by the Usage Rules set forth in the Apple Terms and Conditions and in accordance with the terms of this Agreement.  Any use of the Software in any manner not allowed under this Agreement, the Apple Terms and Conditions, or the LAEULA, including, without limitation, Your resale, transfer, modification or distribution of the Software or Your copying or distribution of text, pictures, music, barcodes, video, data, hyperlinks, displays, metadata and other content provided by the Software is prohibited. This Agreement does not entitle You to receive and does not obligate the University or Apple to provide hard-copy documentation, maintenance, support, telephone assistance, or enhancements or updates to the Software.  The University reserves the right, in its sole discretion, to terminate this Agreement and revoke Your license to use the Software for any reason, including, but not limited to, the University’s conclusion that You have violated this Agreement.
    A.    Prohibited Uses. You may not use the Software  in a manner that (a) harasses, abuses, threatens, defames, or otherwise infringes or violates the rights of any other party; (b) is unlawful, fraudulent, or deceptive; (c) uses technology or other means to access the University’s proprietary information that is not authorized by the University; (d) uses or launches any automated system to access any University website or computer system; (e) attempts to introduce viruses or any other malicious computer code that interrupts, destroys, or limits the functionality of any computer software, hardware, or telecommunications equipment; (f) attempts to gain unauthorized access to the University’s computer network or user accounts; (g) encourages conduct that would constitute a criminal offense or would give rise to civil liability; or (h) violates this Agreement.
    B.    Content and Availability.
(i)     “User-Generated Content” is information or other content, including text, pictures, music, barcodes, video, data, hyperlinks, displays, and associated metadata, that is uploaded, transmitted, broadcast, posted, submitted, or otherwise provided through or in connection with the Software (collectively “Made Available”) by a user of the Software -.  User-Generated Content may include information that would identify the user or that could tie the user’s data to the user.
(ii).    User-Generated Content may not be Made Available by You to the extent that it includes, is in conjunction with, or is alongside any Inappropriate Content.  Inappropriate Content includes, but is not limited to: (i) sexually explicit materials; (ii) vulgar, profane, offensive, defamatory, libelous, slanderous, violent, or unlawful content; (iii) content that infringes upon the rights of any third party, including copyright, trademark, privacy, publicity, or other personal or proprietary right, or that is deceptive or fraudulent; (iv) content that promotes the use or sale of illegal substances; and (v) gambling, including without limitation, any online casino, sports books, bingo or poker.  The University reserves the right, in its sole discretion, to determine whether any User-Generated Content, including Your User-Generated Content, constitutes Inappropriate Content.  The University may, without notice, take down any User-Generated Content, including Yours, and the University may, without notice, eject any user, including You, who has Made Available Inappropriate Content.
(iii)    “Software-Generated Content” is information or other content, including text, pictures, music, barcodes, video, data, results, hyperlinks, displays, and associated metadata, that is generated, created, or produced by the Software.  For the avoidance of doubt, Software-Generated Content includes derivative works of User-Generated Content created by the Software and User-Generated Content that has been modified or transformed by the Software (collectively, “Software-Modified User-Generated Content”).  Software-Generated Content may be Made Available to users of the Software-.
    (iv).    Although the University prohibits certain activities in this Agreement, the University does not make any representation or warranty that the User-Generated Content or Software-Modified User-Generated Content You may encounter through your use of the Software  complies with these acceptable use provisions.  You understand and acknowledge that You may be exposed to User-Generated Content or Software-Modified User-Generated Content that is inaccurate, objectionable, or Inappropriate. Nevertheless, you agree to use the Software - at your sole risk and You agree that THE University WILL not be liable for any damages you allege to incur as a result of any User-Generated Content AND/or SOFTWARE-MODIFIED USER-Generated Content.
    C.    User Information. Should You come into possession of the private information, data, or personally identifiable information of other users of the Software-, You are expressly forbidden to share such information with third parties unless You have express written consent from the user whose information is to be shared. Any sharing of other users’ information without their consent is an express violation of this Agreement.
    D.    Reverse Engineering. You may not and You agree not to, or to enable others to, copy, decompile, reverse engineer, disassemble, attempt to derive the source code of, decrypt, modify, or create derivative works of the Software or Software-Generated Content, or any part thereof (except as and only to the extent any foregoing restriction is prohibited by applicable law or to the extent as may be permitted by the licensing terms governing use of open-sourced components included with the Software). Any attempt to do so is a violation of the rights of the University.  If You breach this restriction, You may be subject to prosecution and damages.
    E.    reCapp Account. Use of the Software may require You to register and create an account.  You are solely responsible for maintaining the confidentiality of the passwords associated with Your account and for restricting access to your passwords and physical access to Your computer and/or Apple Device while logged into Your account.  You accept responsibility for all activities that occur under Your user account.  By registering for an account, You consent to receive communications and notices about the Software by email consistent with the terms of section 13 herein.
5.    “Opt-In” For Push Communications. The University may send You “push messages” or “push notifications” (collectively “Push Communications”) if Your Apple Device supports Push Communications. By installing the Software, You agree to accept Push Communications and “opt-in” to receive them. Should You wish to cease receiving Push Communications from the University, You may turn off Push Communications for the Software by changing the settings on your Apple Device.
6.    Intellectual Property Rights.
A.    Your User-Generated Content.
        You hereby grant to the University a non-exclusive, worldwide, perpetual, irrevocable, royalty-free, sublicensable and transferable license to collect, reproduce, modify, transform, create derivative works of, publish, and use Your User-Generated Content and Your Software-Modified User-Generated Content for purposes of (i) making it available to users of the Software, (ii) performing the functions of the Software, (iii) teaching, research, and scholarship, and (iv) any other commercial or non-commercial purpose.  You represent and warrant that You own or otherwise control all of the rights to Your User-Generated Content, or You otherwise have the right to Make Available such User-Generated Content and to grant the rights granted herein.
B.    Software Materials.
(i)     The University owns or otherwise controls the rights to the Software and any and all copyrighted material, trademarks, service marks, and other content included in the Software including, but not limited to, “reCapp,” the reCapp logo, the University name and logos, the look and feel of the services provided by the Software, Software-Generated Content, and the Software’s source code (collectively, the “Software Materials”).  The Software Materials are protected by United States and international intellectual property laws.  Except for the limited licenses granted hereunder, the University reserves all rights not expressly granted and no such additional rights may be implied.
(ii)    You acknowledge (a) all right, title and interest in and to the Software Materials, including all patents, copyrights, trade secrets, trademarks, and other proprietary rights embodied therein or associated therewith, are and will remain with the University; (b) no right or interest in the Software Materials is conveyed other than the limited licenses granted herein; and (c) You agree not to use the names or trademarks of the University in any press or news releases, advertising, promotions, or sales or solicitation materials without the prior written consent/authorization of the University.
C.    The Software may use copyrighted materials, trademarks, service marks, or other content in connection with the services it provides and such copyrighted materials, trademarks, service marks, and other content remains at all times the property of its respective owner. You have no right or license with respect to any intellectual property owned by any third party that is visible on or provided to You through the Software.
D.    You and the University acknowledge that, in the event of any third party claim that the Software or Your use of the Software infringes any third party’s intellectual property rights, the University, not Apple, will be solely responsible for the investigation, defense, settlement and discharge of any such intellectual property infringement claim.  in the event the Software is found to infringe any intellectual property rights of a third party, TO THE FULLEST EXTENT ALLOWABLE UNDER APPLICABLE LAW, Your sole remedy shall be either to cease using the Software or to use a non-infringing version of the Software should THE University choose to provide you with such a non-infringing version.
7.     Privacy. The University recognizes that privacy is important and our goal is to protect Your private information.
A. Information the University Collects and How It Is Used.
    (i)    Your Personal Information.
        (a)    “Your Personal Information” is Your personally-identifying information such as Your name, address, email address, username, and password, and Your credit card and other financial information that is Made Available by You for the purpose of enabling You to access or use the Software.  Your Personal Information does not include Your personally-identifying information that is Made Available by You for the purpose of being displayed or distributed to users of the Software, even if such information has also been Made Available by You for the purpose of enabling You to access or use the Software.  You consent to the transmission of Your Personal Information to the University, its third-party service providers, and law enforcement authorities.
        (b)    The University will not share Your Personal Information with anyone else except law enforcement authorities and third parties who provide services such as information processing, extending credit, payment processing, fulfilling customer orders, delivering products, managing and enhancing customer data, providing customer service, conducting research or satisfaction surveys, and the like.  These third-party service providers are obligated to protect Your Personal Information.
        (c)    Should You email the University with questions, complaints or comments, the University may retain such email communications. The University will treat such email communications as Your Personal Information.
    (ii)    Your User-Generated Content.
The University may collect, reproduce, modify, transform, create derivative works of, publish, and use Your User-Generated Content and Your Software-Modified User-Generated Content as described in section 6(A) herein.
        

    
    (iii)    Your Data.
        (a)    “Your Data” is (1) information sent by Your Apple Device when you access the Software, , your location, and cookie information, (2) information related to Your use of the Software, and (3) information related to Your User-Generated Content.  Your Data may include information that would identify You as the owner or that could tie Your Data to You.  The University may collect, use and reproduce Your Data and transmit Your Data to third parties for the purposes of performing functions of the Software; improving the Software and the services offered through the Software; ensuring the proper functioning of the Software; developing new services or content for the Software; developing new software; and protecting Your rights, the rights of users of the Software, and the rights of the University.  The University may disclose Your Data to law enforcement authorities as provided herein.

        (b)    “Your Anonymized Data” is Your Data from which all information that would identify You as the owner or that could tie Your Data to You has been removed.  The University may collect, reproduce, modify, publish, and use Your Anonymized Data for any commercial or non-commercial purposes whatsoever.

    (v)    Links to Third-Party Websites.
        The University may present links and embed content to third-party websites in the Software. This section  only applies to the Software. It does not govern the use of any third-party website. If You believe You have an issue or complaint with an operator of a third-party website, You should contact such operator directly.
    (vi)    Disclosure to Authorities.
        The University may disclose Your Personal Information, Your Data, Your User-Generated Content, and any other information submitted or generated by You through or in connection with the Software to law enforcement authorities pursuant to a court order or other legal process or if the University has knowledge or a reasonable belief that a violation of applicable law has occurred through use of the Software.
B.    Information Security. Although the University takes appropriate security measures to protect Your Personal Information and Your Data, its security efforts may be dependent upon the security procedures of third parties with whom the University contracts for the provision of services. The University cannot warrant or ensure that the security measures of such third-party providers will protect Your Personal Information and Your Data.
8.    Limitation of Liability. TO THE FULLEST EXTENT ALLOWABLE UNDER APPLICABLE LAW, (A) IN NO EVENT SHALL THE UNIVERSITY BE LIABLE TO YOU WITH RESPECT TO USE OF THE SOFTWARE, INCLUDING, WITHOUT LIMITATION, ANY USER-GENERATED CONTENT; AND  (B) IN NO EVENT SHALL THE UNIVERSITY BE LIABLE TO YOU FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING OUT OF OR IN ANY WAY RELATING TO THIS AGREEMENT OR THE USE OF OR INABILITY TO USE THE SOFTWARE, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOST PROFITS, LOSS OR CORRUPTION OF DATA, OR FAILURE OR MALFUNCTION OF YOUR APPLE DEVICE. YOUR SOLE REMEDY UNDER THIS AGREEMENT IS TO CEASE USE OF THE SOFTWARE. The foregoing limitations will apply even if the above-stated remedy fails of its essential purpose.  In the event of any failure of the Software to conform to a warranty to which You are entitled by law, You may notify Apple, and Apple will refund the purchase price for the Software to You; to the maximum extent permitted by applicable law, neither Apple nor THE University will have any other warranty obligations whatsoever with respect to the Software, and any other claims losses, liabilities, damages, costs or expenses attributable to any failure to conform to such warranty will be Your sole responsibility.
9.    Indemnification. You agree to defend, indemnify, and hold harmless the University and its trustees, regents, agents, employees, contractors, officers, students, and directors, as well as co-developers and co-owners of the Software, if any, from any and all claims, suits, damages, costs, fines, penalties, liabilities, and expenses (including attorney's fees) arising from or in any way connected with Your use or misuse of the Software, violation of this Agreement, or violation of any rights of a third party.  The University reserves the right to assume the exclusive defense and control of any matter otherwise subject to indemnification by You, in which event You will cooperate in asserting any available defenses.
10.    Product Claims. You and the University acknowledge that the University, not Apple, is responsible for addressing any claims of You or any third party relating to the Software or Your possession and/or use of the Software, including, but not limited to: (i) product liability claims; (ii) any claim that the Software fails to conform to any applicable legal or regulatory requirement; and (iii) claims arising under consumer protection or similar legislation.
11.    Governing Law. The laws of the State of Oklahoma, United States of America, excluding its conflicts of law rules, govern this Agreement and Your use of the Software.  You agree that any action arising under this Agreement or use of the Software shall be commenced and maintained in Payne County District Court of the State of Oklahoma, or the United States District Court for the Western District of the State of Oklahoma, which state or federal court has subject matter jurisdiction with respect to the dispute.  You submit to the jurisdiction of such courts over You personally and in connection with such litigation, and You waive any objection to venue in such courts and any claim that such forum is an inconvenient forum.
12.     Termination and Enforcement. This Agreement is effective until terminated.  The University may (i) terminate this Agreement; (ii) refuse access to the Software and the services ; and/or (iii) terminate Your reCapp account, with or without cause at its sole discretion.  Your rights under this Agreement will terminate automatically or otherwise cease to be effective without notice from the University if you violate any term(s) of this Agreement.  Upon the termination of this Agreement, You shall cease all use of the Software and destroy all copies, full or partial, of the Software.  Sections 1, 3, 4(B)(iv), 4(C), 4(D), 4(E), 6, 7, 8, 9, 10, 11, and 12 of this Agreement shall survive any such termination.  If You believe that a person has violated this Agreement, contact the University as provided in section 13 herein.
13.    Notices. Any notice or other communication required or permitted to be given hereunder may be given by regular mail, postage prepaid, courier, facsimile, or email to the parties at their respective address as follows:
Notices to the University should be addressed to:
Oklahoma State University
Technology Development Center
1201 S. Innovation Way Drive,
 Suite 210, Stillwater, OK – 74074
Fax:  405-744-6451
Email:  tdc@okstate.edu

Notices to You may be delivered to Your Apple Device and/or the email address associated with Your reCapp account.  Notices may be delivered via Push Communications.

Should You wish to contact the University with any questions, complaints or claims with respect to the Software, it is recommended that You email tdc@okstate.edu.
v.___________
Copyright © 2019 Oklahoma State University. All rights reserved.



"""
    
    static let formatted: NSAttributedString = {
        let str = """
 
    reCapp End-User License Agreement for mobile application software designed to operate on an Apple Device

This End-User License Agreement ( “Agreement”)
    (i) governs Your download and use of mobile application software and any enhancement or modification thereof (“Software”) provided by Oklahoma State University (“the University”) that is designed to operate on a computing device marketed or manufactured by Apple Inc. that you own or control (“Your Apple Device”), including Your iPhone, iPod Touch, iPad, HomePod, Apple TV, or Apple Watch;
    (ii) applies to any systems, servers, devices, services, and other items related to the Software; The terms “You,” “Your,” “Yours,” and “End-User” refer to any individual who downloads and/or uses the Software.

Your download and/or use of the Software constitutes Your acceptance of the terms and conditions of this Agreement, which may be amended from time to time by the University. The most recent version of this Agreement will always be available on the internet at the web address http://tdc.okstate.edu/EULA and the most recent version shall supersede any and all other versions of this Agreement. The University reserves the right to modify this Agreement at any time in its sole discretion by posting revisions on the internet at the web address http://tdc.okstate.edu/EULA. Continued use of the Software following the posting of these modifications will constitute acceptance of such modifications by You, the end-user.

1.​ Acknowledgement. The University and You acknowledge that this Agreement is entered into by and between the University and You and not with Apple Inc. (“Apple”). Notwithstanding the foregoing, You acknowledge that Apple and its subsidiaries are third-party beneficiaries of this Agreement and that upon Your acceptance of the terms and conditions of this Agreement, Apple will have the right (and will be deemed to have accepted the right) to enforce this Agreement against You. The University is solely responsible for the Software and any content contained therein. You acknowledge that Apple has no obligation whatsoever to furnish any maintenance or services with respect to the Software. You acknowledge that you have reviewed the Apple Media Services Terms and Conditions (“Apple Terms and Conditions”) available at the web address http://www.apple.com/legal/internet-services/itunes/appstore/jm/terms.html).

2.​ End-User Representations and Warranties. You represent and warrant that (i) You are not located in a country that is subject to a U.S. Government embargo, or that has been designated by the U.S. Government as a “terrorist supporting” country; and (ii) You are not listed on any U.S. Government “watch list” of prohibited or restricted parties, including, without limitation, the Specially Designated Nationals list published by the Office of Foreign Assets Control of the U.S. Treasury and the Denied Persons List published by the U.S. Department of Commerce; and (iii) You are at least eighteen (18) years old.

3.​ Incorporation of Apple’s Licensed Application End User License Agreement. This Agreement incorporates by reference the Licensed Application End User License Agreement (the “LAEULA”) published by Apple at the web address http://www.apple.com/legal/itunes/appstore/dev/stdeula/. For purposes of this Agreement, the Software is considered the “Licensed Application” as defined in the LAEULA and the University is considered the “Application Provider” as defined in the LAEULA. If any terms of this Agreement conflict with the terms of the LAEULA, the terms of this Agreement shall control.

4.​ Scope of License and Allowable Uses of the Software. The license granted to You for the Software is limited to a revocable, non-transferable, non-exclusive license to use the Software on any Apple Device that You own or control and as permitted by the Usage Rules set forth in the Apple Terms and Conditions and in accordance with the terms of this Agreement.  Any use of the Software in any manner not allowed under this Agreement, the Apple Terms and Conditions, or the LAEULA, including, without limitation, Your resale, transfer, modification or distribution of the Software or Your copying or distribution of text, pictures, music, barcodes, video, data, hyperlinks, displays, metadata and other content provided by the Software is prohibited. This Agreement does not entitle You to receive and does not obligate the University or Apple to provide hard-copy documentation, maintenance, support, telephone assistance, or enhancements or updates to the Software.  The University reserves the right, in its sole discretion, to terminate this Agreement and revoke Your license to use the Software for any reason, including, but not limited to, the University’s conclusion that You have violated this Agreement.
    ​A.​ Prohibited Uses. You may not use the Software in a manner that (a) harasses, abuses, threatens, defames, or otherwise infringes or violates the rights of any other party; (b) is unlawful, fraudulent, or deceptive; (c) uses technology or other means to access the University’s proprietary information that is not authorized by the University; (d) uses or launches any automated system to access any University website or computer system; (e) attempts to introduce viruses or any other malicious computer code that interrupts, destroys, or limits the functionality of any computer software, hardware, or telecommunications equipment; (f) attempts to gain unauthorized access to the University’s computer network or user accounts; (g) encourages conduct that would constitute a criminal offense or would give rise to civil liability; or (h) violates this Agreement.
    ​B.​ Content and Availability.
        (i) ​“User-Generated Content” is information or other content, including text, pictures, music, barcodes, video, data, hyperlinks, displays, and associated metadata, that is uploaded, transmitted, broadcast, posted, submitted, or otherwise provided through or in connection with the Software (collectively “Made Available”) by a user of the Software -.  User-Generated Content may include information that would identify the user or that could tie the user’s data to the user.
        (ii) User-Generated Content may not be Made Available by You to the extent that it includes, is in conjunction with, or is alongside any Inappropriate Content. Inappropriate Content includes, but is not limited to: (i) sexually explicit materials; (ii) vulgar, profane, offensive, defamatory, libelous, slanderous, violent, or unlawful content; (iii) content that infringes upon the rights of any third party, including copyright, trademark, privacy, publicity, or other personal or proprietary right, or that is deceptive or fraudulent; (iv) content that promotes the use or sale of illegal substances; and (v) gambling, including without limitation, any online casino, sports books, bingo or poker.  The University reserves the right, in its sole discretion, to determine whether any User-Generated Content, including Your User-Generated Content, constitutes Inappropriate Content. The University may, without notice, take down any User-Generated Content, including Yours, and the University may, without notice, eject any user, including You, who has Made Available Inappropriate Content.
        (iii)​ “Software-Generated Content” is information or other content, including text, pictures, music, barcodes, video, data, results, hyperlinks, displays, and associated metadata, that is generated, created, or produced by the Software.  For the avoidance of doubt, Software-Generated Content includes derivative works of User-Generated Content created by the Software and User-Generated Content that has been modified or transformed by the Software (collectively, “Software-Modified User-Generated Content”).  Software-Generated Content may be Made Available to users of the Software-.
        (iv) Although the University prohibits certain activities in this Agreement, the University does not make any representation or warranty that the User-Generated Content or Software-Modified User-Generated Content You may encounter through your use of the Software complies with these acceptable use provisions.  You understand and acknowledge that You may be exposed to User-Generated Content or Software-Modified User-Generated Content that is inaccurate, objectionable, or Inappropriate. Nevertheless, you agree to use the Software - at your sole risk and YOU AGREE THAT THE UNIVERSITY WILL NOT BE LIABLE FOR ANY DAMAGES YOU ALLEGE TO INCUR AS A RESULT OF ANY USER-GENERATED CONTENT AND/OR SOFTWARE-MODIFIED USER-GENERATED CONTENT.
    ​C.​User Information. Should You come into possession of the private information, data, or personally identifiable information of other users of the Software-, You are expressly forbidden to share such information with third parties unless You have express written consent from the user whose information is to be shared. Any sharing of other users’ information without their consent is an express violation of this Agreement.
    ​D.​Reverse Engineering. You may not and You agree not to, or to enable others to, copy, decompile, reverse engineer, disassemble, attempt to derive the source code of, decrypt, modify, or create derivative works of the Software or Software-Generated Content, or any part thereof (except as and only to the extent any foregoing restriction is prohibited by applicable law or to the extent as may be permitted by the licensing terms governing use of open-sourced components included with the Software). Any attempt to do so is a violation of the rights of the University. If You breach this restriction, You may be subject to prosecution and damages.
    ​E.​reCapp Account. Use of the Software may require You to register and create an account.  You are solely responsible for maintaining the confidentiality of the passwords associated with Your account and for restricting access to your passwords and physical access to Your computer and/or Apple Device while logged into Your account.  You accept responsibility for all activities that occur under Your user account.  By registering for an account, You consent to receive communications and notices about the Software by email consistent with the terms of section 13 herein.

5.​“Opt-In” For Push Communications. The University may send You “push messages” or “push notifications” (collectively “Push Communications”) if Your Apple Device supports Push Communications. By installing the Software, You agree to accept Push Communications and “opt-in” to receive them. Should You wish to cease receiving Push Communications from the University, You may turn off Push Communications for the Software by changing the settings on your Apple Device.

6.​Intellectual Property Rights.
    A.​Your User-Generated Content.
        (i) You hereby grant to the University a non-exclusive, worldwide, perpetual, irrevocable, royalty-free, sublicensable and transferable license to collect, reproduce, modify, transform, create derivative works of, publish, and use Your User-Generated Content and Your Software-Modified User-Generated Content for purposes of
            (a) making it available to users of the Software,
            (b) performing the functions of the Software,
            (c) teaching, research, and scholarship, and
            (d) any other commercial or non-commercial purpose.  You represent and warrant that You own or otherwise control all of the rights to Your User-Generated Content, or You otherwise have the right to Make Available such User-Generated Content and to grant the rights granted herein.
    B.​Software Materials.
        (i) ​The University owns or otherwise controls the rights to the Software and any and all copyrighted material, trademarks, service marks, and other content included in the Software including, but not limited to, “reCapp,” the reCapp logo, the University name and logos, the look and feel of the services provided by the Software, Software-Generated Content, and the Software’s source code (collectively, the “Software Materials”).  The Software Materials are protected by United States and international intellectual property laws.  Except for the limited licenses granted hereunder, the University reserves all rights not expressly granted and no such additional rights may be implied.
        (ii)​You acknowledge
            (a) all right, title and interest in and to the Software Materials, including all patents, copyrights, trade secrets, trademarks, and other proprietary rights embodied therein or associated therewith, are and will remain with the University;
            (b) no right or interest in the Software Materials is conveyed other than the limited licenses granted herein; and
            (c) You agree not to use the names or trademarks of the University in any press or news releases, advertising, promotions, or sales or solicitation materials without the prior written consent/authorization of the University.
    C.​The Software may use copyrighted materials, trademarks, service marks, or other content in connection with the services it provides and such copyrighted materials, trademarks, service marks, and other content remains at all times the property of its respective owner. You have no right or license with respect to any intellectual property owned by any third party that is visible on or provided to You through the Software.
    D.​You and the University acknowledge that, in the event of any third party claim that the Software or Your use of the Software infringes any third party’s intellectual property rights, the University, not Apple, will be solely responsible for the investigation, defense, settlement and discharge of any such intellectual property infringement claim. IN THE EVENT THE SOFTWARE IS FOUND TO INFRINGE ANY INTELLECTUAL PROPERTY RIGHTS OF A THIRD PARTY, TO THE FULLEST EXTENT ALLOWABLE UNDER APPLICABLE LAW, YOUR SOLE REMEDY SHALL BE EITHER TO CEASE USING THE SOFTWARE OR TO USE A NON-INFRINGING VERSION OF THE SOFTWARE SHOULD THE UNIVERSITY CHOOSE TO PROVIDE YOU WITH SUCH A NON-INFRINGING VERSION.

7. ​Privacy. The University recognizes that privacy is important and our goal is to protect Your private information.
    A. Information the University Collects and How It Is Used.
        ​(i)​Your Personal Information.
            ​​(a)​“Your Personal Information” is Your personally-identifying information such as Your name, address, email address, username, and password, and Your credit card and other financial information that is Made Available by You for the purpose of enabling You to access or use the Software. Your Personal Information does not include Your personally-identifying information that is Made Available by You for the purpose of being displayed or distributed to users of the Software, even if such information has also been Made Available by You for the purpose of enabling You to access or use the Software.  You consent to the transmission of Your Personal Information to the University, its third-party service providers, and law enforcement authorities.
            ​​(b)​The University will not share Your Personal Information with anyone else except law enforcement authorities and third parties who provide services such as information processing, extending credit, payment processing, fulfilling customer orders, delivering products, managing and enhancing customer data, providing customer service, conducting research or satisfaction surveys, and the like. These third-party service providers are obligated to protect Your Personal Information.
            ​​(c)​Should You email the University with questions, complaints or comments, the University may retain such email communications. The University will treat such email communications as Your Personal Information.
        ​(ii)​Your User-Generated Content.
            The University may collect, reproduce, modify, transform, create derivative works of, publish, and use Your User-Generated Content and Your Software-Modified User-Generated Content as described in section 6(A) herein.
        ​(iii)​Your Data.
            ​​(a)​“Your Data” is
                (1) information sent by Your Apple Device when you access the Software, , your location, and cookie information,
                (2) information related to Your use of the Software, and
                (3) information related to Your User-Generated Content.  Your Data may include information that would identify You as the owner or that could tie Your Data to You. The University may collect, use and reproduce Your Data and transmit Your Data to third parties for the purposes of performing functions of the Software; improving the Software and the services offered through the Software; ensuring the proper functioning of the Software; developing new services or content for the Software; developing new software; and protecting Your rights, the rights of users of the Software, and the rights of the University.  The University may disclose Your Data to law enforcement authorities as provided herein.
            ​​(b)​“Your Anonymized Data” is Your Data from which all information that would identify You as the owner or that could tie Your Data to You has been removed.  The University may collect, reproduce, modify, publish, and use Your Anonymized Data for any commercial or non-commercial purposes whatsoever.
        ​(v)​Links to Third-Party Websites.
            ​​The University may present links and embed content to third-party websites in the Software. This section only applies to the Software. It does not govern the use of any third-party website. If You believe You have an issue or complaint with an operator of a third-party website, You should contact such operator directly.
        (vi)​Disclosure to Authorities.
            ​​The University may disclose Your Personal Information, Your Data, Your User-Generated Content, and any other information submitted or generated by You through or in connection with the Software to law enforcement authorities pursuant to a court order or other legal process or if the University has knowledge or a reasonable belief that a violation of applicable law has occurred through use of the Software.
    B.​Information Security. Although the University takes appropriate security measures to protect Your Personal Information and Your Data, its security efforts may be dependent upon the security procedures of third parties with whom the University contracts for the provision of services. The University cannot warrant or ensure that the security measures of such third-party providers will protect Your Personal Information and Your Data.

8.​Limitation of Liability. TO THE FULLEST EXTENT ALLOWABLE UNDER APPLICABLE LAW, (A) IN NO EVENT SHALL THE UNIVERSITY BE LIABLE TO YOU WITH RESPECT TO USE OF THE SOFTWARE, INCLUDING, WITHOUT LIMITATION, ANY USER-GENERATED CONTENT; AND (B) IN NO EVENT SHALL THE UNIVERSITY BE LIABLE TO YOU FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING OUT OF OR IN ANY WAY RELATING TO THIS AGREEMENT OR THE USE OF OR INABILITY TO USE THE SOFTWARE, INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOST PROFITS, LOSS OR CORRUPTION OF DATA, OR FAILURE OR MALFUNCTION OF YOUR APPLE DEVICE. YOUR SOLE REMEDY UNDER THIS AGREEMENT IS TO CEASE USE OF THE SOFTWARE. The foregoing limitations will apply even if the above-stated remedy fails of its essential purpose.  In the event of any failure of the Software to conform to a warranty to which You are entitled by law, You may notify Apple, and Apple will refund the purchase price for the Software to You; to the maximum extent permitted by applicable law, NEITHER APPLE NOR THE UNIVERSITY WILL HAVE ANY OTHER WARRANTY OBLIGATIONS WHATSOEVER WITH RESPECT TO THE SOFTWARE, AND ANY OTHER CLAIMS LOSSES, LIABILITIES, DAMAGES, COSTS OR EXPENSES ATTRIBUTABLE TO ANY FAILURE TO CONFORM TO SUCH WARRANTY WILL BE YOUR SOLE RESPONSIBILITY.

9.​Indemnification. You agree to defend, indemnify, and hold harmless the University and its trustees, regents, agents, employees, contractors, officers, students, and directors, as well as co-developers and co-owners of the Software, if any, from any and all claims, suits, damages, costs, fines, penalties, liabilities, and expenses (including attorney's fees) arising from or in any way connected with Your use or misuse of the Software, violation of this Agreement, or violation of any rights of a third party. The University reserves the right to assume the exclusive defense and control of any matter otherwise subject to indemnification by You, in which event You will cooperate in asserting any available defenses.

10.​Product Claims. You and the University acknowledge that the University, not Apple, is responsible for addressing any claims of You or any third party relating to the Software or Your possession and/or use of the Software, including, but not limited to:
    (i) product liability claims;
    (ii) any claim that the Software fails to conform to any applicable legal or regulatory requirement; and
    (iii) claims arising under consumer protection or similar legislation.

11.​Governing Law. The laws of the State of Oklahoma, United States of America, excluding its conflicts of law rules, govern this Agreement and Your use of the Software. You agree that any action arising under this Agreement or use of the Software shall be commenced and maintained in Payne County District Court of the State of Oklahoma, or the United States District Court for the Western District of the State of Oklahoma, which state or federal court has subject matter jurisdiction with respect to the dispute.  You submit to the jurisdiction of such courts over You personally and in connection with such litigation, and You waive any objection to venue in such courts and any claim that such forum is an inconvenient forum.

12. ​Termination and Enforcement. This Agreement is effective until terminated.  The University may
    (i) terminate this Agreement;
    (ii) refuse access to the Software and the services ; and/or
    (iii) terminate Your reCapp account, with or without cause at its sole discretion.  Your rights under this Agreement will terminate automatically or otherwise cease to be effective without notice from the University if you violate any term(s) of this Agreement.  Upon the termination of this Agreement, You shall cease all use of the Software and destroy all copies, full or partial, of the Software.  Sections 1, 3, 4(B)(iv), 4(C), 4(D), 4(E), 6, 7, 8, 9, 10, 11, and 12 of this Agreement shall survive any such termination. If You believe that a person has violated this Agreement, contact the University as provided in section 13 herein.

13.​Notices. Any notice or other communication required or permitted to be given hereunder may be given by regular mail, postage prepaid, courier, facsimile, or email to the parties at their respective address as follows:

    Notices to the University should be addressed to:

    Oklahoma State University
    Technology Development Center
    1201 S. Innovation Way Drive,
    Suite 210, Stillwater, OK – 74074

    Fax:  405-744-6451
    Email:  tdc@okstate.edu

 

Notices to You may be delivered to Your Apple Device and/or the email address associated with Your reCapp account.  Notices may be delivered via Push Communications.
Should You wish to contact the University with any questions, complaints or claims with respect to the Software, it is recommended that You email tdc@okstate.edu.

v1.0
Copyright © 2019 Oklahoma State University. All rights reserved.

"""
        let att = NSAttributedString(string: str, attributes: [NSAttributedString.Key.font : UIFont(name: "Helvetica", size: 16)])
        return att
    }()
}
