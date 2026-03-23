import SwiftUI
import Combine

class GourceConfig: ObservableObject {
    // MARK: - Repository
    @Published var repoPath: String = ""

    // MARK: - Display
    @Published var viewportWidth: Int = 1280
    @Published var viewportHeight: Int = 720
    @Published var fullscreen: Bool = false
    @Published var screenNumber: Int = 0
    @Published var multiSampling: Bool = false
    @Published var highDPI: Bool = true
    @Published var noVsync: Bool = false
    @Published var frameless: Bool = false
    @Published var windowPositionX: Int = 0
    @Published var windowPositionY: Int = 0
    @Published var useWindowPosition: Bool = false
    @Published var transparent: Bool = false

    // MARK: - Time Range
    @Published var useStartDate: Bool = false
    @Published var startDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @Published var useStopDate: Bool = false
    @Published var stopDate: Date = Date()

    // MARK: - Position & Playback
    @Published var useStartPosition: Bool = false
    @Published var startPosition: Double = 0.0
    @Published var useStopPosition: Bool = false
    @Published var stopPosition: Double = 1.0
    @Published var useStopAtTime: Bool = false
    @Published var stopAtTime: Int = 60
    @Published var stopAtEnd: Bool = false
    @Published var dontStop: Bool = false
    @Published var loop: Bool = false
    @Published var loopDelaySeconds: Int = 3

    // MARK: - Speed & Timing
    @Published var autoSkipSeconds: Double = 3.0
    @Published var disableAutoSkip: Bool = false
    @Published var secondsPerDay: Double = 10.0
    @Published var realtime: Bool = false
    @Published var noTimeTravel: Bool = false
    @Published var authorTime: Bool = false
    @Published var timeScale: Double = 1.0
    @Published var elasticity: Double = 0.0

    // MARK: - Camera
    @Published var cameraMode: String = "overview" // overview, track
    @Published var crop: String = "none" // none, vertical, horizontal
    @Published var padding: Double = 1.1
    @Published var disableAutoRotate: Bool = false

    // MARK: - Appearance
    @Published var backgroundColor: Color = .black
    @Published var useBackgroundImage: Bool = false
    @Published var backgroundImage: String = ""
    @Published var bloomMultiplier: Double = 1.0
    @Published var bloomIntensity: Double = 0.75
    @Published var showKey: Bool = false
    @Published var useTitle: Bool = false
    @Published var title: String = ""

    // MARK: - Users
    @Published var useUserImageDir: Bool = false
    @Published var userImageDir: String = ""
    @Published var useDefaultUserImage: Bool = false
    @Published var defaultUserImage: String = ""
    @Published var fixedUserSize: Bool = false
    @Published var colourImages: Bool = false
    @Published var userScale: Double = 1.0
    @Published var userFriction: Double = 0.67
    @Published var maxUserSpeed: Int = 500

    // MARK: - Files
    @Published var fileIdleTime: Double = 0.0
    @Published var fileIdleTimeAtEnd: Double = 0.0
    @Published var maxFiles: Int = 0
    @Published var maxFileLag: Double = 0.0
    @Published var fileExtensions: Bool = false
    @Published var fileExtensionFallback: Bool = false
    @Published var filenameTime: Double = 4.0

    // MARK: - Fonts
    @Published var useFontFile: Bool = false
    @Published var fontFile: String = ""
    @Published var fontScale: Double = 1.0
    @Published var fontSize: Int = 16
    @Published var fileFontSize: Int = 12
    @Published var dirFontSize: Int = 12
    @Published var userFontSize: Int = 12
    @Published var fontColor: Color = .white

    // MARK: - Colours
    @Published var useHighlightColour: Bool = false
    @Published var highlightColour: Color = .yellow
    @Published var useSelectionColour: Bool = false
    @Published var selectionColour: Color = .blue
    @Published var useFilenameColour: Bool = false
    @Published var filenameColour: Color = .white
    @Published var useDirColour: Bool = false
    @Published var dirColour: Color = .white

    // MARK: - Hide Elements
    @Published var hideBloom: Bool = false
    @Published var hideDate: Bool = false
    @Published var hideDirnames: Bool = false
    @Published var hideFiles: Bool = false
    @Published var hideFilenames: Bool = false
    @Published var hideMouse: Bool = false
    @Published var hideProgress: Bool = false
    @Published var hideRoot: Bool = false
    @Published var hideTree: Bool = false
    @Published var hideUsers: Bool = false
    @Published var hideUsernames: Bool = false

    // MARK: - Highlighting
    @Published var highlightDirs: Bool = false
    @Published var highlightUsers: Bool = false
    @Published var useFollowUser: Bool = false
    @Published var followUser: String = ""
    @Published var useHighlightUser: Bool = false
    @Published var highlightUser: String = ""

    // MARK: - Filters
    @Published var useUserFilter: Bool = false
    @Published var userFilter: String = ""
    @Published var useUserShowFilter: Bool = false
    @Published var userShowFilter: String = ""
    @Published var useFileFilter: Bool = false
    @Published var fileFilter: String = ""
    @Published var useFileShowFilter: Bool = false
    @Published var fileShowFilter: String = ""

    // MARK: - Directory Names
    @Published var dirNameDepth: Int = 0
    @Published var useDirNameDepth: Bool = false
    @Published var dirNamePosition: Double = 0.5

    // MARK: - Logo
    @Published var useLogo: Bool = false
    @Published var logo: String = ""
    @Published var logoOffsetX: Int = 0
    @Published var logoOffsetY: Int = 0

    // MARK: - Captions
    @Published var useCaptionFile: Bool = false
    @Published var captionFile: String = ""
    @Published var captionSize: Int = 24
    @Published var captionColour: Color = .white
    @Published var captionDuration: Double = 10.0
    @Published var captionOffset: Int = 0

    // MARK: - Date Format
    @Published var useDateFormat: Bool = false
    @Published var dateFormat: String = "%A %d %B %Y"

    // MARK: - Git
    @Published var useGitBranch: Bool = false
    @Published var gitBranch: String = "main"

    // MARK: - Log
    @Published var logFormat: String = "auto" // auto, git, svn, hg, bzr, cvs2cl, custom

    // MARK: - Output
    @Published var useOutputPPM: Bool = false
    @Published var outputPPMFile: String = ""
    @Published var outputFramerate: Int = 60

    // MARK: - Advanced
    @Published var disableInput: Bool = false
    @Published var hashSeed: Int = 0
    @Published var useHashSeed: Bool = false

    // MARK: - Build Command

    func colorToHex(_ color: Color) -> String {
        let nsColor = NSColor(color)
        guard let rgb = nsColor.usingColorSpace(.sRGB) else { return "FFFFFF" }
        let r = Int(rgb.redComponent * 255)
        let g = Int(rgb.greenComponent * 255)
        let b = Int(rgb.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }

    func buildCommand() -> [String] {
        var args: [String] = ["/usr/local/bin/gource"]

        // Display
        args += ["--viewport", "\(viewportWidth)x\(viewportHeight)"]
        if fullscreen { args.append("--fullscreen") }
        if screenNumber > 0 { args += ["--screen", "\(screenNumber)"] }
        if multiSampling { args.append("--multi-sampling") }
        if highDPI { args.append("--high-dpi") }
        if noVsync { args.append("--no-vsync") }
        if frameless { args.append("--frameless") }
        if useWindowPosition { args += ["--window-position", "\(windowPositionX)x\(windowPositionY)"] }
        if transparent { args.append("--transparent") }

        // Time range
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if useStartDate { args += ["--start-date", df.string(from: startDate)] }
        if useStopDate { args += ["--stop-date", df.string(from: stopDate)] }

        // Position
        if useStartPosition { args += ["--start-position", String(format: "%.2f", startPosition)] }
        if useStopPosition { args += ["--stop-position", String(format: "%.2f", stopPosition)] }
        if useStopAtTime { args += ["--stop-at-time", "\(stopAtTime)"] }
        if stopAtEnd { args.append("--stop-at-end") }
        if dontStop { args.append("--dont-stop") }
        if loop {
            args.append("--loop")
            if loopDelaySeconds != 3 { args += ["--loop-delay-seconds", "\(loopDelaySeconds)"] }
        }

        // Speed
        if disableAutoSkip {
            args.append("--disable-auto-skip")
        } else if autoSkipSeconds != 3.0 {
            args += ["--auto-skip-seconds", String(format: "%.1f", autoSkipSeconds)]
        }
        if realtime {
            args.append("--realtime")
        } else if secondsPerDay != 10.0 {
            args += ["--seconds-per-day", String(format: "%.1f", secondsPerDay)]
        }
        if noTimeTravel { args.append("--no-time-travel") }
        if authorTime { args.append("--author-time") }
        if timeScale != 1.0 { args += ["--time-scale", String(format: "%.2f", timeScale)] }
        if elasticity != 0.0 { args += ["--elasticity", String(format: "%.2f", elasticity)] }

        // Camera
        if cameraMode != "overview" { args += ["--camera-mode", cameraMode] }
        if crop != "none" { args += ["--crop", crop] }
        if padding != 1.1 { args += ["--padding", String(format: "%.2f", padding)] }
        if disableAutoRotate { args.append("--disable-auto-rotate") }

        // Appearance
        let bgHex = colorToHex(backgroundColor)
        if bgHex != "000000" { args += ["--background-colour", bgHex] }
        if useBackgroundImage && !backgroundImage.isEmpty { args += ["--background-image", backgroundImage] }
        if bloomMultiplier != 1.0 { args += ["--bloom-multiplier", String(format: "%.2f", bloomMultiplier)] }
        if bloomIntensity != 0.75 { args += ["--bloom-intensity", String(format: "%.2f", bloomIntensity)] }
        if showKey { args.append("--key") }
        if useTitle && !title.isEmpty { args += ["--title", title] }

        // Users
        if useUserImageDir && !userImageDir.isEmpty { args += ["--user-image-dir", userImageDir] }
        if useDefaultUserImage && !defaultUserImage.isEmpty { args += ["--default-user-image", defaultUserImage] }
        if fixedUserSize { args.append("--fixed-user-size") }
        if colourImages { args.append("--colour-images") }
        if userScale != 1.0 { args += ["--user-scale", String(format: "%.2f", userScale)] }
        if userFriction != 0.67 { args += ["--user-friction", String(format: "%.2f", userFriction)] }
        if maxUserSpeed != 500 { args += ["--max-user-speed", "\(maxUserSpeed)"] }

        // Files
        if fileIdleTime != 0.0 { args += ["--file-idle-time", String(format: "%.1f", fileIdleTime)] }
        if fileIdleTimeAtEnd != 0.0 { args += ["--file-idle-time-at-end", String(format: "%.1f", fileIdleTimeAtEnd)] }
        if maxFiles > 0 { args += ["--max-files", "\(maxFiles)"] }
        if maxFileLag > 0 { args += ["--max-file-lag", String(format: "%.1f", maxFileLag)] }
        if fileExtensions { args.append("--file-extensions") }
        if fileExtensionFallback { args.append("--file-extension-fallback") }
        if filenameTime != 4.0 { args += ["--filename-time", String(format: "%.1f", filenameTime)] }

        // Fonts
        if useFontFile && !fontFile.isEmpty { args += ["--font-file", fontFile] }
        if fontScale != 1.0 { args += ["--font-scale", String(format: "%.2f", fontScale)] }
        if fontSize != 16 { args += ["--font-size", "\(fontSize)"] }
        if fileFontSize != 12 { args += ["--file-font-size", "\(fileFontSize)"] }
        if dirFontSize != 12 { args += ["--dir-font-size", "\(dirFontSize)"] }
        if userFontSize != 12 { args += ["--user-font-size", "\(userFontSize)"] }
        let fontHex = colorToHex(fontColor)
        if fontHex != "FFFFFF" { args += ["--font-colour", fontHex] }

        // Colours
        if useHighlightColour { args += ["--highlight-colour", colorToHex(highlightColour)] }
        if useSelectionColour { args += ["--selection-colour", colorToHex(selectionColour)] }
        if useFilenameColour { args += ["--filename-colour", colorToHex(filenameColour)] }
        if useDirColour { args += ["--dir-colour", colorToHex(dirColour)] }

        // Hide
        var hideItems: [String] = []
        if hideBloom { hideItems.append("bloom") }
        if hideDate { hideItems.append("date") }
        if hideDirnames { hideItems.append("dirnames") }
        if hideFiles { hideItems.append("files") }
        if hideFilenames { hideItems.append("filenames") }
        if hideMouse { hideItems.append("mouse") }
        if hideProgress { hideItems.append("progress") }
        if hideRoot { hideItems.append("root") }
        if hideTree { hideItems.append("tree") }
        if hideUsers { hideItems.append("users") }
        if hideUsernames { hideItems.append("usernames") }
        if !hideItems.isEmpty { args += ["--hide", hideItems.joined(separator: ",")] }

        // Highlighting
        if highlightDirs { args.append("--highlight-dirs") }
        if highlightUsers { args.append("--highlight-users") }
        if useFollowUser && !followUser.isEmpty { args += ["--follow-user", followUser] }
        if useHighlightUser && !highlightUser.isEmpty { args += ["--highlight-user", highlightUser] }

        // Filters
        if useUserFilter && !userFilter.isEmpty { args += ["--user-filter", userFilter] }
        if useUserShowFilter && !userShowFilter.isEmpty { args += ["--user-show-filter", userShowFilter] }
        if useFileFilter && !fileFilter.isEmpty { args += ["--file-filter", fileFilter] }
        if useFileShowFilter && !fileShowFilter.isEmpty { args += ["--file-show-filter", fileShowFilter] }

        // Dir names
        if useDirNameDepth { args += ["--dir-name-depth", "\(dirNameDepth)"] }
        if dirNamePosition != 0.5 { args += ["--dir-name-position", String(format: "%.2f", dirNamePosition)] }

        // Logo
        if useLogo && !logo.isEmpty {
            args += ["--logo", logo]
            if logoOffsetX != 0 || logoOffsetY != 0 { args += ["--logo-offset", "\(logoOffsetX)x\(logoOffsetY)"] }
        }

        // Captions
        if useCaptionFile && !captionFile.isEmpty {
            args += ["--caption-file", captionFile]
            if captionSize != 24 { args += ["--caption-size", "\(captionSize)"] }
            args += ["--caption-colour", colorToHex(captionColour)]
            if captionDuration != 10.0 { args += ["--caption-duration", String(format: "%.1f", captionDuration)] }
            if captionOffset != 0 { args += ["--caption-offset", "\(captionOffset)"] }
        }

        // Date format
        if useDateFormat && !dateFormat.isEmpty { args += ["--date-format", dateFormat] }

        // Git
        if useGitBranch && !gitBranch.isEmpty { args += ["--git-branch", gitBranch] }

        // Log format
        if logFormat != "auto" { args += ["--log-format", logFormat] }

        // Output
        if useOutputPPM && !outputPPMFile.isEmpty {
            args += ["--output-ppm-stream", outputPPMFile]
            args += ["--output-framerate", "\(outputFramerate)"]
        }

        // Advanced
        if disableInput { args.append("--disable-input") }
        if useHashSeed { args += ["--hash-seed", "\(hashSeed)"] }

        // Path
        if !repoPath.isEmpty { args.append(repoPath) }

        return args
    }

    func commandString() -> String {
        buildCommand().map { arg in
            if arg.contains(" ") || arg.contains("(") || arg.contains(")") {
                return "'\(arg)'"
            }
            return arg
        }.joined(separator: " ")
    }
}
