/**
 * Copyright © 2017 Aga Khan Foundation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

import SnapKit
import FacebookLogin
import FacebookCore

class LoginViewController: UIViewController {
  let imgBackground: UIImageView =
      UIImageView(image: UIImage(imageLiteralResourceName: "login-screen"))
  let btnLogin: LoginButton =
      LoginButton(readPermissions: [.publicProfile, .email, .userFriends,
                                    .custom("user_location")])

  let titleLabel: UILabel = UILabel(typography: .headerTitle)
  
  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }

  // MARK: - Configure

  private func configureView() {
    view.backgroundColor = Style.Colors.white

    view.addSubviews([imgBackground, btnLogin])
    
    titleLabel.text = "Steps4Change"
    titleLabel.text = Strings.Dashboard.title
    titleLabel.textColor = .black
    titleLabel.backgroundColor = .clear

    
    titleLabel.snp.makeConstraints { (make) in
      make.width.equalTo(150)
      make.height.equalTo(50)
      make.top.equalTo(100)
    }

    imgBackground.snp.makeConstraints { (make) in
      make.width.equalTo(200)
      make.height.equalTo(200)
      make.centerX.equalTo(view)
      make.centerY.equalTo(view)
    }

    btnLogin.delegate = self
    btnLogin.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.bottom.equalToSuperview().offset(-Style.Size.s96)
    }
  }
}

extension LoginViewController: LoginButtonDelegate {
  func loginButtonDidCompleteLogin(_ loginButton: LoginButton,
                                   result: LoginResult) {
    switch result {
    case .success:
      AKFCausesService.createParticipant(fbid: Facebook.id)
      AppController.shared.login()
    case .cancelled:
      break
    case .failed(let error):
      alert(message: "Error logging in \(error)", style: .cancel)
    }
  }

  func loginButtonDidLogOut(_ loginButton: LoginButton) {
    fatalError("user logged in without a session?")
  }
}
