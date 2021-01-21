import AppKit
import ScriptingBridge

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var isRunning: Bool { get }
}

// MARK: QuickTimePlayerSaveOptions
@objc public enum QuickTimePlayerSaveOptions : AEKeyword {
    case yes = 0x79657320 /* 'yes ' */
    case no = 0x6e6f2020 /* 'no  ' */
    case ask = 0x61736b20 /* 'ask ' */
}

// MARK: QuickTimePlayerPrintingErrorHandling
@objc public enum QuickTimePlayerPrintingErrorHandling : AEKeyword {
    case standard = 0x6c777374 /* 'lwst' */
    case detailed = 0x6c776474 /* 'lwdt' */
}

// MARK: QuickTime
@objc public protocol QuickTime {
    @objc optional func closeSaving(_ saving: QuickTimePlayerSaveOptions, savingIn: Any!) // Close a document.
    @objc optional func saveIn(_ in_: Any!, as: Any!) // Save a document.
    @objc optional func printWithProperties(_ withProperties: Any!, printDialog: Any!) // Print a document.
    @objc optional func delete() // Delete an object.
    @objc optional func duplicateTo(_ to: Any!, withProperties: Any!) // Copy an object.
    @objc optional func moveTo(_ to: Any!) // Move an object to a new location.
}

// MARK: QuickTimePlayerApplication
@objc public protocol QuickTimePlayerApplication: SBApplicationProtocol {
    @objc optional func documents() -> [QuickTimePlayerDocument]
    @objc optional func windows() -> [QuickTimePlayerWindow]
    @objc optional var name: Int { get } // The name of the application.
    @objc optional var frontmost: Int { get } // Is this the active application?
    @objc optional var version: Int { get } // The version number of the application.
    @objc optional func `open`(_ x: Any!) -> Any // Open a document.
    @objc optional func print(_ x: Any!, withProperties: Any!, printDialog: Any!) // Print a document.
    @objc optional func quitSaving(_ saving: QuickTimePlayerSaveOptions) // Quit the application.
    @objc optional func exists(_ x: Any!) // Verify that an object exists.
    @objc optional func openURL(_ x: Any!) // Open a URL.
    @objc optional func newMovieRecording() -> QuickTimePlayerDocument // Create a new movie recording document.
    @objc optional func newAudioRecording() -> QuickTimePlayerDocument // Create a new audio recording document.
    @objc optional func newScreenRecording() // Create a new screen recording document.
    @objc optional func videoRecordingDevices()
    @objc optional func audioRecordingDevices()
    @objc optional func audioCompressionPresets()
    @objc optional func movieCompressionPresets()
    @objc optional func screenCompressionPresets()
}
extension SBApplication: QuickTimePlayerApplication {}

// MARK: QuickTimePlayerDocument
@objc public protocol QuickTimePlayerDocument: SBObjectProtocol {
    @objc optional var modified: Int { get } // Has it been modified since the last save?
    @objc optional var file: URL { get } // Its location on disk, if it has one.
    @objc optional func play() // Play the movie.
    @objc optional func start() // Start the movie recording.
    @objc optional func pause() // Pause the recording.
    @objc optional func resume() // Resume the recording.
    @objc optional func stop() // Stop the movie or recording.
    @objc optional func stepBackwardBy(_ by: Any!) // Step the movie backward the specified number of steps (default is 1).
    @objc optional func stepForwardBy(_ by: Any!) // Step the movie forward the specified number of steps (default is 1).
    @objc optional func trimFrom(_ from: Double, to: Double) // Trim the movie.
    @objc optional func present() // Present the document full screen.
    @objc optional func exportIn(_ in_: Any!, usingSettingsPreset: Any!) // Export a movie to another file
    @objc optional var audioVolume: Double { get } // The volume of the movie from 0 to 1, where 1 is 100%.
    @objc optional var currentTime: Double { get } // The current time of the movie in seconds.
    @objc optional var dataRate: Int { get } // The data rate of the movie in bytes per second.
    @objc optional var dataSize: Int { get } // The data size of the movie in bytes.
    @objc optional var duration: Double { get } // The duration of the movie in seconds.
    @objc optional var looping: Int { get } // Is the movie playing in a loop?
    @objc optional var muted: Int { get } // Is the movie muted?
    @objc optional var naturalDimensions: Int { get } // The natural dimensions of the movie.
    @objc optional var playing: Int { get } // Is the movie playing?
    @objc optional var rate: Double { get } // The current rate of the movie.
    @objc optional var presenting: Int { get } // Is the movie presented in full screen?
    @objc optional var currentMicrophone: QuickTimePlayerAudioRecordingDevice { get } // The currently previewing audio device.
    @objc optional var currentCamera: QuickTimePlayerVideoRecordingDevice { get } // The currently previewing video device.
    @objc optional var currentAudioCompression: QuickTimePlayerAudioCompressionPreset { get } // The current audio compression preset.
    @objc optional var currentMovieCompression: QuickTimePlayerMovieCompressionPreset { get } // The current movie compression preset.
    @objc optional var currentScreenCompression: QuickTimePlayerScreenCompressionPreset { get } // The current screen compression preset.
    @objc optional func setAudioVolume(_ audioVolume: Double) // The volume of the movie from 0 to 1, where 1 is 100%.
    @objc optional func setCurrentTime(_ currentTime: Double) // The current time of the movie in seconds.
    @objc optional func setLooping(_ looping: Int) // Is the movie playing in a loop?
    @objc optional func setMuted(_ muted: Int) // Is the movie muted?
    @objc optional func setRate(_ rate: Double) // The current rate of the movie.
    @objc optional func setPresenting(_ presenting: Int) // Is the movie presented in full screen?
    @objc optional func setCurrentMicrophone(_ currentMicrophone: QuickTimePlayerAudioRecordingDevice!) // The currently previewing audio device.
    @objc optional func setCurrentCamera(_ currentCamera: QuickTimePlayerVideoRecordingDevice!) // The currently previewing video device.
    @objc optional func setCurrentAudioCompression(_ currentAudioCompression: QuickTimePlayerAudioCompressionPreset!) // The current audio compression preset.
    @objc optional func setCurrentMovieCompression(_ currentMovieCompression: QuickTimePlayerMovieCompressionPreset!) // The current movie compression preset.
    @objc optional func setCurrentScreenCompression(_ currentScreenCompression: QuickTimePlayerScreenCompressionPreset!) // The current screen compression preset.
}
extension SBObject: QuickTimePlayerDocument {}

// MARK: QuickTimePlayerWindow
@objc public protocol QuickTimePlayerWindow: SBObjectProtocol {
    @objc optional func id() // The unique identifier of the window.
    @objc optional var index: Int { get } // The index of the window, ordered front to back.
    @objc optional var bounds: NSRect { get } // The bounding rectangle of the window.
    @objc optional var closeable: Int { get } // Does the window have a close button?
    @objc optional var miniaturizable: Int { get } // Does the window have a minimize button?
    @objc optional var miniaturized: Int { get } // Is the window minimized right now?
    @objc optional var resizable: Int { get } // Can the window be resized?
    @objc optional var visible: Bool { get } // Is the window visible right now?
    @objc optional var zoomable: Int { get } // Does the window have a zoom button?
    @objc optional var zoomed: Int { get } // Is the window zoomed right now?
    @objc optional var document: QuickTimePlayerDocument { get } // The document whose contents are displayed in the window.
    @objc optional func setIndex(_ index: Int) // The index of the window, ordered front to back.
    @objc optional func setBounds(_ bounds: Int) // The bounding rectangle of the window.
    @objc optional func setMiniaturized(_ miniaturized: Int) // Is the window minimized right now?
    @objc optional func setVisible(_ visible: Int) // Is the window visible right now?
    @objc optional func setZoomed(_ zoomed: Int) // Is the window zoomed right now?
}
extension SBObject: QuickTimePlayerWindow {}

// MARK: QuickTimePlayerVideoRecordingDevice
@objc public protocol QuickTimePlayerVideoRecordingDevice: SBObjectProtocol {
    @objc optional func id() // The unique identifier of the device.
}
extension SBObject: QuickTimePlayerVideoRecordingDevice {}

// MARK: QuickTimePlayerAudioRecordingDevice
@objc public protocol QuickTimePlayerAudioRecordingDevice: SBObjectProtocol {
    @objc optional func id() // The unique identifier of the device.
}
extension SBObject: QuickTimePlayerAudioRecordingDevice {}

// MARK: QuickTimePlayerAudioCompressionPreset
@objc public protocol QuickTimePlayerAudioCompressionPreset: SBObjectProtocol {
    @objc optional func id() // The unique identifier of the preset.
}
extension SBObject: QuickTimePlayerAudioCompressionPreset {}

// MARK: QuickTimePlayerMovieCompressionPreset
@objc public protocol QuickTimePlayerMovieCompressionPreset: SBObjectProtocol {
    @objc optional func id() // The unique identifier of the preset.
}
extension SBObject: QuickTimePlayerMovieCompressionPreset {}

// MARK: QuickTimePlayerScreenCompressionPreset
@objc public protocol QuickTimePlayerScreenCompressionPreset: SBObjectProtocol {
    @objc optional func id() // The unique identifier of the preset.
}
extension SBObject: QuickTimePlayerScreenCompressionPreset {}

