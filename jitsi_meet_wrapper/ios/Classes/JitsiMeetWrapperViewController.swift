import UIKit
import JitsiMeetSDK

// This is closely inspired by:
// https://github.com/jitsi/jitsi-meet-sdk-samples/blob/18c35f7625b38233579ff34f761f4c126ba7e03a/ios/swift-pip/JitsiSDKTest/src/ViewController.swift
class JitsiMeetWrapperViewController: UIViewController {
    fileprivate var pipViewCoordinator: PiPViewCoordinator?
    fileprivate var jitsiMeetView: JitsiMeetView?

    // TODO: Pass in ready build options object..
    var roomName: String? = nil
    var serverUrl: URL? = nil
    var subject: String? = nil
    var audioOnly: Bool? = false
    var audioMuted: Bool? = false
    var videoMuted: Bool? = false
    var token: String? = nil
    var featureFlags: Dictionary<String, Any>? = Dictionary();
    var jistiMeetUserInfo = JitsiMeetUserInfo()

    override func viewDidAppear(_ animated: Bool) {
        openJitsiMeet();
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let rect = CGRect(origin: CGPoint.zero, size: size)
        pipViewCoordinator?.resetBounds(bounds: rect)
    }

    func openJitsiMeet() {
        cleanUp()

        let jitsiMeetView = JitsiMeetView()
        jitsiMeetView.delegate = self
        self.jitsiMeetView = jitsiMeetView

        let options = JitsiMeetConferenceOptions.fromBuilder { (builder) in
            builder.room = self.roomName
            builder.serverURL = self.serverUrl
            builder.setSubject(self.subject ?? "")
            // TODO(saibotma): Fix typo
            builder.userInfo = self.jistiMeetUserInfo
            builder.setAudioOnly(self.audioOnly ?? false)
            builder.setAudioMuted(self.audioMuted ?? false)
            builder.setVideoMuted(self.videoMuted ?? false)
            builder.token = self.token

            self.featureFlags?.forEach { key, value in
                builder.setFeatureFlag(key, withValue: value);
            }
        }

        jitsiMeetView.join(options)

        // Enable jitsimeet view to be a view that can be displayed
        // on top of all the things, and let the coordinator to manage
        // the view state and interactions
        pipViewCoordinator = PiPViewCoordinator(withView: jitsiMeetView)
        pipViewCoordinator?.configureAsStickyView(withParentView: view)

        // animate in
        jitsiMeetView.alpha = 0
        pipViewCoordinator?.show()
    }

    fileprivate func cleanUp() {
        jitsiMeetView?.removeFromSuperview()
        jitsiMeetView = nil
        pipViewCoordinator = nil
    }
}

extension JitsiMeetWrapperViewController: JitsiMeetViewDelegate {
    func conferenceTerminated(_ data: [AnyHashable: Any]!) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.hide { _ in
                self.cleanUp()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    func enterPicture(inPicture data: [AnyHashable: Any]!) {
        DispatchQueue.main.async {
            self.pipViewCoordinator?.enterPictureInPicture()
        }
    }
}
