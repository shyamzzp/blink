//////////////////////////////////////////////////////////////////////////////////
//
// B L I N K
//
// Copyright (C) 2016-2019 Blink Mobile Shell Project
//
// This file is part of Blink.
//
// Blink is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Blink is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Blink. If not, see <http://www.gnu.org/licenses/>.
//
// In addition, Blink is also subject to certain additional terms under
// GNU GPL version 3 section 7.
//
// You should have received a copy of these additional terms immediately
// following the terms and conditions of the GNU General Public License
// which accompanied the Blink Source Code. If not, see
// <http://www.github.com/blinksh/blink>.
//
////////////////////////////////////////////////////////////////////////////////

import AVFoundation
import Speech
import UIKit

/// Wraps `SFSpeechRecognizer` for push-to-talk dictation.
///
/// The transcript is reported as it is recognized so the caller can show it
/// live, and once more when recognition settles. Nothing is inserted into a
/// terminal from here; that is the caller's decision.
final class VoiceDictation {

  enum Failure: Error {
    case unavailable
    case notPermitted

    var message: String {
      switch self {
      case .unavailable: return "Speech recognition is unavailable"
      case .notPermitted: return "Microphone or speech access denied"
      }
    }
  }

  private let _recognizer: SFSpeechRecognizer?
  private let _audioEngine = AVAudioEngine()
  private var _request: SFSpeechAudioBufferRecognitionRequest?
  private var _task: SFSpeechRecognitionTask?

  /// Set while a recognition task is running, cleared once it reports a final
  /// result. Guards against delivering a transcript twice.
  private var _finished = false

  private(set) var isListening = false

  /// Latest transcript, partial while speaking and final once settled.
  var onTranscript: ((String, _ isFinal: Bool) -> Void)?
  var onFailure: ((Failure) -> Void)?

  init(locale: Locale = Locale.current) {
    _recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  }

  deinit {
    _teardownAudio()
  }

  // MARK: - Permissions

  /// Asks for speech recognition and microphone access, in that order.
  /// The callback always lands on the main queue.
  static func requestAccess(_ completion: @escaping (Bool) -> Void) {
    SFSpeechRecognizer.requestAuthorization { speechStatus in
      guard speechStatus == .authorized else {
        DispatchQueue.main.async { completion(false) }
        return
      }
      AVAudioApplication.requestRecordPermission { micGranted in
        DispatchQueue.main.async { completion(micGranted) }
      }
    }
  }

  static var hasAccess: Bool {
    SFSpeechRecognizer.authorizationStatus() == .authorized
      && AVAudioApplication.shared.recordPermission == .granted
  }

  // MARK: - Lifecycle

  func start() {
    guard !isListening else {
      return
    }

    guard let recognizer = _recognizer, recognizer.isAvailable else {
      onFailure?(.unavailable)
      return
    }

    guard Self.hasAccess else {
      onFailure?(.notPermitted)
      return
    }

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    // Keep audio on the device when the device can manage it. Older hardware
    // reports false here and falls back to Apple's servers.
    request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.record, mode: .measurement, options: .duckOthers)
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      onFailure?(.unavailable)
      return
    }

    let input = _audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    // A zero sample rate means the input route is not ready, and installing a
    // tap with it traps inside AVAudioEngine.
    guard format.sampleRate > 0 else {
      _deactivateSession()
      onFailure?(.unavailable)
      return
    }

    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      request.append(buffer)
    }

    _audioEngine.prepare()
    do {
      try _audioEngine.start()
    } catch {
      input.removeTap(onBus: 0)
      _deactivateSession()
      onFailure?(.unavailable)
      return
    }

    _request = request
    _finished = false
    isListening = true

    _task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      guard let self = self else {
        return
      }

      if let result = result {
        let text = result.bestTranscription.formattedString
        self.onTranscript?(text, result.isFinal)
        if result.isFinal {
          self._finished = true
          self._teardownAudio()
        }
        return
      }

      if error != nil, !self._finished {
        // A task cancelled before it heard anything reports an error rather
        // than an empty result. Nothing was said, so there is nothing to say.
        self._finished = true
        self._teardownAudio()
      }
    }
  }

  /// Stops capturing. Recognition finishes asynchronously and the final
  /// transcript arrives through `onTranscript`.
  func stop() {
    guard isListening else {
      return
    }
    isListening = false

    _audioEngine.inputNode.removeTap(onBus: 0)
    if _audioEngine.isRunning {
      _audioEngine.stop()
    }
    _request?.endAudio()
  }

  /// Stops capturing and discards whatever was heard.
  func cancel() {
    isListening = false
    _finished = true
    _task?.cancel()
    _teardownAudio()
  }

  private func _teardownAudio() {
    _audioEngine.inputNode.removeTap(onBus: 0)
    if _audioEngine.isRunning {
      _audioEngine.stop()
    }
    _request = nil
    _task = nil
    isListening = false
    _deactivateSession()
  }

  private func _deactivateSession() {
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}

/// Floating push-to-talk button.
///
/// Hold to dictate, release to insert. The transcript is handed over through
/// `onInsert` without a trailing newline: a misheard command should sit on the
/// prompt waiting to be read, never run on its own.
final class MicButton: UIView {

  private let _button = UIButton(type: .custom)
  private let _transcriptLabel = PaddedLabel()
  private let _dictation = VoiceDictation()

  private var _latestTranscript = ""
  private var _inserted = false

  /// Called with the recognized text when the user releases the button.
  var onInsert: ((String) -> Void)?

  private static let _size: CGFloat = 52

  override init(frame: CGRect) {
    super.init(frame: frame)
    _setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    _setup()
  }

  private func _setup() {
    translatesAutoresizingMaskIntoConstraints = false

    _transcriptLabel.translatesAutoresizingMaskIntoConstraints = false
    _transcriptLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    _transcriptLabel.textColor = .white
    _transcriptLabel.backgroundColor = UIColor.black.withAlphaComponent(0.72)
    _transcriptLabel.numberOfLines = 3
    _transcriptLabel.textAlignment = .right
    _transcriptLabel.layer.cornerRadius = 10
    _transcriptLabel.layer.masksToBounds = true
    _transcriptLabel.isHidden = true
    _transcriptLabel.isUserInteractionEnabled = false
    addSubview(_transcriptLabel)

    _button.translatesAutoresizingMaskIntoConstraints = false
    _button.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    _button.tintColor = .white
    _button.layer.cornerRadius = Self._size / 2
    _button.layer.borderWidth = 1
    _button.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
    _button.accessibilityLabel = "Dictate"
    _button.accessibilityHint = "Hold to dictate a command, release to insert it"
    _setIcon("mic.fill")
    addSubview(_button)

    _button.addTarget(self, action: #selector(_onPress), for: .touchDown)
    _button.addTarget(self, action: #selector(_onRelease), for: .touchUpInside)
    _button.addTarget(self, action: #selector(_onRelease), for: .touchUpOutside)
    _button.addTarget(self, action: #selector(_onCancel), for: .touchCancel)

    NSLayoutConstraint.activate([
      _button.widthAnchor.constraint(equalToConstant: Self._size),
      _button.heightAnchor.constraint(equalToConstant: Self._size),
      _button.trailingAnchor.constraint(equalTo: trailingAnchor),
      _button.bottomAnchor.constraint(equalTo: bottomAnchor),
      _button.leadingAnchor.constraint(equalTo: leadingAnchor),
      _button.topAnchor.constraint(equalTo: _transcriptLabel.bottomAnchor, constant: 8),

      _transcriptLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      _transcriptLabel.topAnchor.constraint(equalTo: topAnchor),
      _transcriptLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
      _transcriptLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
    ])

    _dictation.onTranscript = { [weak self] text, isFinal in
      self?._handleTranscript(text, isFinal: isFinal)
    }
    _dictation.onFailure = { [weak self] failure in
      self?._showMessage(failure.message)
      self?._setListening(false)
    }
  }

  // The label floats above the button, so only the two of them should take
  // touches. Everything else passes through to the terminal underneath.
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return _button.frame.contains(point)
  }

  private func _setIcon(_ name: String) {
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
    _button.setImage(UIImage(systemName: name, withConfiguration: config), for: .normal)
  }

  // MARK: - Press handling

  @objc private func _onPress() {
    guard VoiceDictation.hasAccess else {
      VoiceDictation.requestAccess { [weak self] granted in
        if !granted {
          self?._showMessage("Enable Microphone and Speech Recognition in Settings")
        }
      }
      return
    }

    _latestTranscript = ""
    _inserted = false
    _setListening(true)
    _dictation.start()
  }

  @objc private func _onRelease() {
    guard _dictation.isListening else {
      return
    }
    _setListening(false)
    _dictation.stop()

    // Recognition keeps refining for a moment after the audio ends. Give it a
    // short grace period, then insert whatever it settled on.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
      self?._insertIfNeeded()
    }
  }

  @objc private func _onCancel() {
    _setListening(false)
    _inserted = true
    _dictation.cancel()
    _hideTranscript(after: 0)
  }

  private func _handleTranscript(_ text: String, isFinal: Bool) {
    _latestTranscript = text
    _showTranscript(text)
    if isFinal {
      _insertIfNeeded()
    }
  }

  private func _insertIfNeeded() {
    guard !_inserted else {
      return
    }
    let text = _latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else {
      _hideTranscript(after: 0)
      return
    }
    _inserted = true
    onInsert?(text)
    _hideTranscript(after: 0.4)
  }

  // MARK: - Appearance

  private func _setListening(_ listening: Bool) {
    _setIcon(listening ? "waveform" : "mic.fill")
    UIView.animate(withDuration: 0.15) {
      self._button.backgroundColor = listening
        ? UIColor.systemRed.withAlphaComponent(0.9)
        : UIColor.black.withAlphaComponent(0.55)
      self._button.transform = listening ? CGAffineTransform(scaleX: 1.12, y: 1.12) : .identity
    }
    if listening {
      _showTranscript("Listening...")
    }
  }

  private func _showTranscript(_ text: String) {
    _transcriptLabel.text = text
    _transcriptLabel.isHidden = false
    _transcriptLabel.alpha = 1
  }

  private func _showMessage(_ message: String) {
    _showTranscript(message)
    _hideTranscript(after: 2.5)
  }

  private func _hideTranscript(after delay: TimeInterval) {
    UIView.animate(withDuration: 0.25, delay: delay) {
      self._transcriptLabel.alpha = 0
    } completion: { finished in
      if finished {
        self._transcriptLabel.isHidden = true
      }
    }
  }
}

/// Label with interior padding, so the transcript bubble does not hug its text.
private final class PaddedLabel: UILabel {
  private let _insets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)

  override func drawText(in rect: CGRect) {
    super.drawText(in: rect.inset(by: _insets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(width: size.width + _insets.left + _insets.right,
                  height: size.height + _insets.top + _insets.bottom)
  }

  override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
    let rect = super.textRect(forBounds: bounds.inset(by: _insets),
                              limitedToNumberOfLines: numberOfLines)
    return rect.inset(by: UIEdgeInsets(top: -_insets.top, left: -_insets.left,
                                       bottom: -_insets.bottom, right: -_insets.right))
  }
}
