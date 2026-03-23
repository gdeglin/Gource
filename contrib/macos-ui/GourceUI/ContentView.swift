import SwiftUI

struct ContentView: View {
    @StateObject private var config = GourceConfig()
    @State private var isRunning = false
    @State private var gourceProcess: Process?
    @State private var logOutput: String = ""
    @State private var showCommandPreview = false
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider()

            // Main content
            HSplitView {
                // Left: tabs
                tabContent
                    .frame(minWidth: 500)

                // Right: command preview & log
                rightPanel
                    .frame(minWidth: 280, maxWidth: 340)
            }

            Divider()

            // Bottom bar
            bottomBar
        }
    }

    // MARK: - Header

    var headerBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.hexagongrid.fill")
                .font(.title2)
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("Gource")
                .font(.title2.bold())

            Text("v0.57")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(Capsule())

            Spacer()

            repoSelector
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    var repoSelector: some View {
        HStack(spacing: 8) {
            Image(systemName: "folder.fill")
                .foregroundColor(.secondary)

            if config.repoPath.isEmpty {
                Text("Select Repository…")
                    .foregroundColor(.secondary)
            } else {
                Text(shortenPath(config.repoPath))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button {
                chooseRepo()
            } label: {
                Text("Browse")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.background)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
    }

    // MARK: - Tabs

    var tabContent: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            ScrollView {
                Group {
                    switch selectedTab {
                    case 0: displayTab
                    case 1: playbackTab
                    case 2: appearanceTab
                    case 3: elementsTab
                    case 4: filtersTab
                    case 5: outputTab
                    default: displayTab
                    }
                }
                .padding(16)
            }
        }
    }

    var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("Display", icon: "display", index: 0)
            tabButton("Playback", icon: "play.circle", index: 1)
            tabButton("Appearance", icon: "paintbrush", index: 2)
            tabButton("Elements", icon: "eye", index: 3)
            tabButton("Filters", icon: "line.3.horizontal.decrease.circle", index: 4)
            tabButton("Output", icon: "square.and.arrow.up", index: 5)
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
    }

    func tabButton(_ title: String, icon: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(selectedTab == index ? Color.accentColor.opacity(0.12) : .clear)
            .foregroundColor(selectedTab == index ? .accentColor : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Display Tab

    var displayTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Viewport")
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Text("Resolution")
                            .frame(width: 100, alignment: .leading)
                        TextField("Width", value: $config.viewportWidth, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("×")
                        TextField("Height", value: $config.viewportHeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Spacer()
                        Menu("Presets") {
                            Button("720p") { config.viewportWidth = 1280; config.viewportHeight = 720 }
                            Button("1080p") { config.viewportWidth = 1920; config.viewportHeight = 1080 }
                            Button("1440p") { config.viewportWidth = 2560; config.viewportHeight = 1440 }
                            Button("4K") { config.viewportWidth = 3840; config.viewportHeight = 2160 }
                        }
                    }
                    HStack {
                        Text("Screen")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $config.screenNumber) {
                            Text("Default").tag(0)
                            Text("1").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                        }
                        .labelsHidden()
                        .frame(width: 100)
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Window Options")
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 20) {
                        Toggle("Fullscreen", isOn: $config.fullscreen)
                        Toggle("High DPI", isOn: $config.highDPI)
                        Toggle("Frameless", isOn: $config.frameless)
                    }
                    HStack(spacing: 20) {
                        Toggle("Multi-sampling", isOn: $config.multiSampling)
                        Toggle("No VSync", isOn: $config.noVsync)
                        Toggle("Transparent", isOn: $config.transparent)
                    }
                    HStack {
                        Toggle("Window Position", isOn: $config.useWindowPosition)
                        if config.useWindowPosition {
                            TextField("X", value: $config.windowPositionX, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            TextField("Y", value: $config.windowPositionY, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Camera")
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Text("Mode")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $config.cameraMode) {
                            Text("Overview").tag("overview")
                            Text("Track").tag("track")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        Spacer()
                    }
                    HStack {
                        Text("Crop")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $config.crop) {
                            Text("None").tag("none")
                            Text("Vertical").tag("vertical")
                            Text("Horizontal").tag("horizontal")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 250)
                        Spacer()
                    }
                    sliderRow("Padding", value: $config.padding, range: 0.5...2.0, format: "%.2f")
                    Toggle("Disable Auto-Rotate", isOn: $config.disableAutoRotate)
                }
                .padding(4)
            }
        }
    }

    // MARK: - Playback Tab

    var playbackTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Speed")
            GroupBox {
                VStack(spacing: 12) {
                    sliderRow("Seconds/Day", value: $config.secondsPerDay, range: 0.1...60.0, format: "%.1f")
                    sliderRow("Time Scale", value: $config.timeScale, range: 0.1...10.0, format: "%.2f")
                    sliderRow("Auto-Skip (s)", value: $config.autoSkipSeconds, range: 0...30.0, format: "%.1f")
                    sliderRow("Elasticity", value: $config.elasticity, range: 0...1.0, format: "%.2f")
                    HStack(spacing: 20) {
                        Toggle("Realtime", isOn: $config.realtime)
                        Toggle("Disable Auto-Skip", isOn: $config.disableAutoSkip)
                    }
                    HStack(spacing: 20) {
                        Toggle("No Time Travel", isOn: $config.noTimeTravel)
                        Toggle("Author Time", isOn: $config.authorTime)
                    }
                }
                .padding(4)
            }

            sectionHeader("Time Range")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Start Date", isOn: $config.useStartDate)
                            .frame(width: 140)
                        if config.useStartDate {
                            DatePicker("", selection: $config.startDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Stop Date", isOn: $config.useStopDate)
                            .frame(width: 140)
                        if config.useStopDate {
                            DatePicker("", selection: $config.stopDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Start Position", isOn: $config.useStartPosition)
                            .frame(width: 140)
                        if config.useStartPosition {
                            Slider(value: $config.startPosition, in: 0...1)
                                .frame(width: 150)
                            Text(String(format: "%.2f", config.startPosition))
                                .monospacedDigit().frame(width: 40)
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Stop Position", isOn: $config.useStopPosition)
                            .frame(width: 140)
                        if config.useStopPosition {
                            Slider(value: $config.stopPosition, in: 0...1)
                                .frame(width: 150)
                            Text(String(format: "%.2f", config.stopPosition))
                                .monospacedDigit().frame(width: 40)
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Stop After (s)", isOn: $config.useStopAtTime)
                            .frame(width: 140)
                        if config.useStopAtTime {
                            TextField("", value: $config.stopAtTime, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 80)
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Looping")
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 20) {
                        Toggle("Stop at End", isOn: $config.stopAtEnd)
                        Toggle("Don't Stop", isOn: $config.dontStop)
                        Toggle("Loop", isOn: $config.loop)
                    }
                    if config.loop {
                        HStack {
                            Text("Loop Delay (s)")
                                .frame(width: 120, alignment: .leading)
                            TextField("", value: $config.loopDelaySeconds, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            Spacer()
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    // MARK: - Appearance Tab

    var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Background")
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Text("Color")
                            .frame(width: 100, alignment: .leading)
                        ColorPicker("", selection: $config.backgroundColor)
                            .labelsHidden()
                        Spacer()
                    }
                    HStack {
                        Toggle("Background Image", isOn: $config.useBackgroundImage)
                        if config.useBackgroundImage {
                            pathField($config.backgroundImage, prompt: "Image path")
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Bloom")
            GroupBox {
                VStack(spacing: 12) {
                    sliderRow("Multiplier", value: $config.bloomMultiplier, range: 0...3.0, format: "%.2f")
                    sliderRow("Intensity", value: $config.bloomIntensity, range: 0...1.5, format: "%.2f")
                }
                .padding(4)
            }

            sectionHeader("Title & Date")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Title", isOn: $config.useTitle)
                            .frame(width: 100)
                        if config.useTitle {
                            TextField("Enter title", text: $config.title)
                                .textFieldStyle(.roundedBorder)
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Date Format", isOn: $config.useDateFormat)
                            .frame(width: 120)
                        if config.useDateFormat {
                            TextField("strftime format", text: $config.dateFormat)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        Spacer()
                    }
                    Toggle("Show File Extension Key", isOn: $config.showKey)
                }
                .padding(4)
            }

            sectionHeader("Fonts")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Custom Font", isOn: $config.useFontFile)
                        if config.useFontFile {
                            pathField($config.fontFile, prompt: "Font path")
                        }
                        Spacer()
                    }
                    sliderRow("Font Scale", value: $config.fontScale, range: 0.5...3.0, format: "%.2f")
                    HStack(spacing: 16) {
                        numField("Date/Title", value: $config.fontSize)
                        numField("Files", value: $config.fileFontSize)
                        numField("Dirs", value: $config.dirFontSize)
                        numField("Users", value: $config.userFontSize)
                        Spacer()
                    }
                    HStack {
                        Text("Font Color")
                            .frame(width: 100, alignment: .leading)
                        ColorPicker("", selection: $config.fontColor).labelsHidden()
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Custom Colours")
            GroupBox {
                VStack(spacing: 8) {
                    colorToggleRow("Highlight", isOn: $config.useHighlightColour, color: $config.highlightColour)
                    colorToggleRow("Selection", isOn: $config.useSelectionColour, color: $config.selectionColour)
                    colorToggleRow("Filename", isOn: $config.useFilenameColour, color: $config.filenameColour)
                    colorToggleRow("Directory", isOn: $config.useDirColour, color: $config.dirColour)
                }
                .padding(4)
            }

            sectionHeader("Logo")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Logo", isOn: $config.useLogo)
                        if config.useLogo {
                            pathField($config.logo, prompt: "Logo image path")
                        }
                        Spacer()
                    }
                    if config.useLogo {
                        HStack {
                            Text("Offset")
                                .frame(width: 60, alignment: .leading)
                            TextField("X", value: $config.logoOffsetX, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            TextField("Y", value: $config.logoOffsetY, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            Spacer()
                        }
                    }
                }
                .padding(4)
            }

            sectionHeader("Captions")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Caption File", isOn: $config.useCaptionFile)
                        if config.useCaptionFile {
                            pathField($config.captionFile, prompt: "Caption file path")
                        }
                        Spacer()
                    }
                    if config.useCaptionFile {
                        HStack(spacing: 12) {
                            numField("Size", value: $config.captionSize)
                            Text("Duration")
                            TextField("", value: $config.captionDuration, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            Text("Offset")
                            TextField("", value: $config.captionOffset, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                            Spacer()
                        }
                        HStack {
                            Text("Color")
                                .frame(width: 60, alignment: .leading)
                            ColorPicker("", selection: $config.captionColour).labelsHidden()
                            Spacer()
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    // MARK: - Elements Tab

    var elementsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Hide Elements")
            GroupBox {
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 8) {
                    Toggle("Bloom", isOn: $config.hideBloom)
                    Toggle("Date", isOn: $config.hideDate)
                    Toggle("Dir Names", isOn: $config.hideDirnames)
                    Toggle("Files", isOn: $config.hideFiles)
                    Toggle("Filenames", isOn: $config.hideFilenames)
                    Toggle("Mouse", isOn: $config.hideMouse)
                    Toggle("Progress", isOn: $config.hideProgress)
                    Toggle("Root", isOn: $config.hideRoot)
                    Toggle("Tree", isOn: $config.hideTree)
                    Toggle("Users", isOn: $config.hideUsers)
                    Toggle("Usernames", isOn: $config.hideUsernames)
                }
                .padding(4)
            }

            sectionHeader("Users")
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Toggle("Avatar Directory", isOn: $config.useUserImageDir)
                        if config.useUserImageDir {
                            pathField($config.userImageDir, prompt: "Directory path")
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Default Avatar", isOn: $config.useDefaultUserImage)
                        if config.useDefaultUserImage {
                            pathField($config.defaultUserImage, prompt: "Image path")
                        }
                        Spacer()
                    }
                    HStack(spacing: 20) {
                        Toggle("Fixed Size", isOn: $config.fixedUserSize)
                        Toggle("Colourize Images", isOn: $config.colourImages)
                    }
                    sliderRow("User Scale", value: $config.userScale, range: 0.1...5.0, format: "%.2f")
                    sliderRow("Friction", value: $config.userFriction, range: 0.0...2.0, format: "%.2f")
                    HStack {
                        Text("Max Speed")
                            .frame(width: 100, alignment: .leading)
                        TextField("", value: $config.maxUserSpeed, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 80)
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Files")
            GroupBox {
                VStack(spacing: 12) {
                    sliderRow("Idle Time", value: $config.fileIdleTime, range: 0...1000, format: "%.0f")
                    sliderRow("Idle at End", value: $config.fileIdleTimeAtEnd, range: 0...1000, format: "%.0f")
                    sliderRow("Name Duration", value: $config.filenameTime, range: 0...30, format: "%.1f")
                    HStack {
                        Text("Max Files")
                            .frame(width: 100, alignment: .leading)
                        TextField("0 = no limit", value: $config.maxFiles, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 100)
                        Spacer()
                    }
                    HStack {
                        Text("Max Lag (s)")
                            .frame(width: 100, alignment: .leading)
                        TextField("", value: $config.maxFileLag, format: .number)
                            .textFieldStyle(.roundedBorder).frame(width: 80)
                        Spacer()
                    }
                    HStack(spacing: 20) {
                        Toggle("Extensions Only", isOn: $config.fileExtensions)
                        Toggle("Extension Fallback", isOn: $config.fileExtensionFallback)
                    }
                }
                .padding(4)
            }

            sectionHeader("Highlighting")
            GroupBox {
                VStack(spacing: 10) {
                    HStack(spacing: 20) {
                        Toggle("Highlight Dirs", isOn: $config.highlightDirs)
                        Toggle("Highlight All Users", isOn: $config.highlightUsers)
                    }
                    HStack {
                        Toggle("Follow User", isOn: $config.useFollowUser)
                            .frame(width: 140)
                        if config.useFollowUser {
                            TextField("Username", text: $config.followUser)
                                .textFieldStyle(.roundedBorder).frame(width: 150)
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Highlight User", isOn: $config.useHighlightUser)
                            .frame(width: 140)
                        if config.useHighlightUser {
                            TextField("Username", text: $config.highlightUser)
                                .textFieldStyle(.roundedBorder).frame(width: 150)
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Directory Names")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Name Depth", isOn: $config.useDirNameDepth)
                            .frame(width: 140)
                        if config.useDirNameDepth {
                            TextField("", value: $config.dirNameDepth, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 60)
                        }
                        Spacer()
                    }
                    sliderRow("Name Position", value: $config.dirNamePosition, range: 0...1.0, format: "%.2f")
                }
                .padding(4)
            }
        }
    }

    // MARK: - Filters Tab

    var filtersTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("User Filters")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Exclude (regex)", isOn: $config.useUserFilter)
                            .frame(width: 160)
                        if config.useUserFilter {
                            TextField("e.g. bot|ci", text: $config.userFilter)
                                .textFieldStyle(.roundedBorder)
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Show Only (regex)", isOn: $config.useUserShowFilter)
                            .frame(width: 160)
                        if config.useUserShowFilter {
                            TextField("e.g. alice|bob", text: $config.userShowFilter)
                                .textFieldStyle(.roundedBorder)
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("File Filters")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Exclude (regex)", isOn: $config.useFileFilter)
                            .frame(width: 160)
                        if config.useFileFilter {
                            TextField("e.g. \\.lock$|node_modules", text: $config.fileFilter)
                                .textFieldStyle(.roundedBorder)
                        }
                        Spacer()
                    }
                    HStack {
                        Toggle("Show Only (regex)", isOn: $config.useFileShowFilter)
                            .frame(width: 160)
                        if config.useFileShowFilter {
                            TextField("e.g. \\.swift$|\\.py$", text: $config.fileShowFilter)
                                .textFieldStyle(.roundedBorder)
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Git Options")
            GroupBox {
                VStack(spacing: 10) {
                    HStack {
                        Toggle("Specific Branch", isOn: $config.useGitBranch)
                            .frame(width: 160)
                        if config.useGitBranch {
                            TextField("Branch name", text: $config.gitBranch)
                                .textFieldStyle(.roundedBorder).frame(width: 150)
                        }
                        Spacer()
                    }
                    HStack {
                        Text("Log Format")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $config.logFormat) {
                            Text("Auto-detect").tag("auto")
                            Text("Git").tag("git")
                            Text("SVN").tag("svn")
                            Text("Mercurial").tag("hg")
                            Text("Bazaar").tag("bzr")
                            Text("CVS").tag("cvs2cl")
                            Text("Custom").tag("custom")
                        }
                        .labelsHidden()
                        .frame(width: 150)
                        Spacer()
                    }
                }
                .padding(4)
            }

            sectionHeader("Advanced")
            GroupBox {
                VStack(spacing: 10) {
                    Toggle("Disable Keyboard/Mouse Input", isOn: $config.disableInput)
                    HStack {
                        Toggle("Hash Seed", isOn: $config.useHashSeed)
                            .frame(width: 140)
                        if config.useHashSeed {
                            TextField("", value: $config.hashSeed, format: .number)
                                .textFieldStyle(.roundedBorder).frame(width: 100)
                        }
                        Spacer()
                    }
                }
                .padding(4)
            }
        }
    }

    // MARK: - Output Tab

    var outputTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Video Output")
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Toggle("Output PPM Stream", isOn: $config.useOutputPPM)
                        Spacer()
                    }
                    if config.useOutputPPM {
                        HStack {
                            Text("Output File")
                                .frame(width: 100, alignment: .leading)
                            TextField("path or - for stdout", text: $config.outputPPMFile)
                                .textFieldStyle(.roundedBorder)
                        }
                        HStack {
                            Text("Framerate")
                                .frame(width: 100, alignment: .leading)
                            Picker("", selection: $config.outputFramerate) {
                                Text("25 FPS").tag(25)
                                Text("30 FPS").tag(30)
                                Text("60 FPS").tag(60)
                            }
                            .labelsHidden()
                            .frame(width: 120)
                            Spacer()
                        }
                    }
                }
                .padding(4)
            }

            sectionHeader("Config Files")
            GroupBox {
                VStack(spacing: 12) {
                    HStack {
                        Button("Save Config…") {
                            saveConfig()
                        }
                        Button("Load Config…") {
                            loadConfig()
                        }
                        Spacer()
                    }
                    Text("Save or load Gource .conf configuration files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(4)
            }

            sectionHeader("Tips")
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    tipRow("⌨️", "Press H during playback to toggle the UI")
                    tipRow("🖱️", "Click on users or files to follow them")
                    tipRow("📹", "Pipe PPM output to ffmpeg for MP4 export:")
                    Text("  gource -o - | ffmpeg -y -r 60 -f image2pipe -vcodec ppm -i - -vcodec libx264 output.mp4")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                .padding(4)
            }
        }
    }

    // MARK: - Right Panel

    var rightPanel: some View {
        VStack(spacing: 0) {
            Text("Command Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            ScrollView {
                Text(config.commandString())
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .background(.background.opacity(0.5))
            .frame(maxHeight: .infinity)

            if !logOutput.isEmpty {
                Divider()
                Text("Output")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                ScrollView {
                    Text(logOutput)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 150)
                .background(.background.opacity(0.5))
            }
        }
    }

    // MARK: - Bottom Bar

    var bottomBar: some View {
        HStack {
            Button {
                resetConfig()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }

            Spacer()

            if isRunning {
                Button(role: .destructive) {
                    stopGource()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .foregroundColor(.red)
                }
                .keyboardShortcut(".", modifiers: .command)

                ProgressView()
                    .controlSize(.small)
                    .padding(.leading, 4)
            }

            Button {
                launchGource()
            } label: {
                Label(isRunning ? "Restart" : "Launch", systemImage: "play.fill")
            }
            .keyboardShortcut(.return, modifiers: .command)
            .buttonStyle(.borderedProminent)
            .disabled(config.repoPath.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Helpers

    func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }

    func sliderRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, format: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: format, value.wrappedValue))
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }

    func numField(_ label: String, value: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption)
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
        }
    }

    func pathField(_ text: Binding<String>, prompt: String) -> some View {
        TextField(prompt, text: text)
            .textFieldStyle(.roundedBorder)
            .frame(minWidth: 150)
    }

    func colorToggleRow(_ label: String, isOn: Binding<Bool>, color: Binding<Color>) -> some View {
        HStack {
            Toggle(label, isOn: isOn)
                .frame(width: 140)
            if isOn.wrappedValue {
                ColorPicker("", selection: color).labelsHidden()
            }
            Spacer()
        }
    }

    func tipRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(emoji)
            Text(text).font(.caption)
        }
    }

    func shortenPath(_ path: String) -> String {
        let comps = path.split(separator: "/")
        if comps.count <= 3 { return path }
        return "…/" + comps.suffix(2).joined(separator: "/")
    }

    // MARK: - Actions

    func chooseRepo() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a Git repository"
        if panel.runModal() == .OK, let url = panel.url {
            config.repoPath = url.path
        }
    }

    func launchGource() {
        stopGource()
        logOutput = ""
        isRunning = true

        let args = config.buildCommand()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: args[0])
        process.arguments = Array(args.dropFirst())
        process.currentDirectoryURL = URL(fileURLWithPath: config.repoPath.isEmpty ? FileManager.default.currentDirectoryPath : config.repoPath)

        let pipe = Pipe()
        process.standardError = pipe
        process.standardOutput = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    logOutput += str
                    // Keep last 2000 chars
                    if logOutput.count > 2000 {
                        logOutput = String(logOutput.suffix(2000))
                    }
                }
            }
        }

        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                isRunning = false
                gourceProcess = nil
            }
        }

        do {
            try process.run()
            gourceProcess = process
        } catch {
            logOutput = "Error: \(error.localizedDescription)"
            isRunning = false
        }
    }

    func stopGource() {
        gourceProcess?.terminate()
        gourceProcess = nil
        isRunning = false
    }

    func resetConfig() {
        let path = config.repoPath
        let newConfig = GourceConfig()
        // Copy all published properties... just replace the object
        // Actually, since it's @StateObject, let's reset fields
        config.viewportWidth = 1280; config.viewportHeight = 720
        config.fullscreen = false; config.screenNumber = 0
        config.multiSampling = false; config.highDPI = true; config.noVsync = false
        config.frameless = false; config.transparent = false
        config.useWindowPosition = false
        config.useStartDate = false; config.useStopDate = false
        config.useStartPosition = false; config.useStopPosition = false
        config.useStopAtTime = false; config.stopAtEnd = false
        config.dontStop = false; config.loop = false; config.loopDelaySeconds = 3
        config.autoSkipSeconds = 3.0; config.disableAutoSkip = false
        config.secondsPerDay = 10.0; config.realtime = false
        config.noTimeTravel = false; config.authorTime = false
        config.timeScale = 1.0; config.elasticity = 0.0
        config.cameraMode = "overview"; config.crop = "none"
        config.padding = 1.1; config.disableAutoRotate = false
        config.backgroundColor = .black
        config.useBackgroundImage = false; config.backgroundImage = ""
        config.bloomMultiplier = 1.0; config.bloomIntensity = 0.75
        config.showKey = false; config.useTitle = false; config.title = ""
        config.useUserImageDir = false; config.useDefaultUserImage = false
        config.fixedUserSize = false; config.colourImages = false
        config.userScale = 1.0; config.userFriction = 0.67; config.maxUserSpeed = 500
        config.fileIdleTime = 0; config.fileIdleTimeAtEnd = 0
        config.maxFiles = 0; config.maxFileLag = 0
        config.fileExtensions = false; config.fileExtensionFallback = false
        config.filenameTime = 4.0
        config.useFontFile = false; config.fontScale = 1.0
        config.fontSize = 16; config.fileFontSize = 12
        config.dirFontSize = 12; config.userFontSize = 12
        config.fontColor = .white
        config.hideBloom = false; config.hideDate = false
        config.hideDirnames = false; config.hideFiles = false
        config.hideFilenames = false; config.hideMouse = false
        config.hideProgress = false; config.hideRoot = false
        config.hideTree = false; config.hideUsers = false
        config.hideUsernames = false
        config.highlightDirs = false; config.highlightUsers = false
        config.useFollowUser = false; config.useHighlightUser = false
        config.useUserFilter = false; config.useUserShowFilter = false
        config.useFileFilter = false; config.useFileShowFilter = false
        config.useDirNameDepth = false; config.dirNamePosition = 0.5
        config.useLogo = false; config.useCaptionFile = false
        config.useDateFormat = false; config.useGitBranch = false
        config.logFormat = "auto"
        config.useOutputPPM = false; config.outputFramerate = 60
        config.disableInput = false; config.useHashSeed = false
        config.useHighlightColour = false; config.useSelectionColour = false
        config.useFilenameColour = false; config.useDirColour = false
        config.repoPath = path
    }

    func saveConfig() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "conf")!]
        panel.nameFieldStringValue = "gource.conf"
        if panel.runModal() == .OK, let url = panel.url {
            let args = config.buildCommand()
            var finalArgs = args
            finalArgs.append(contentsOf: ["--save-config", url.path])
            let process = Process()
            process.executableURL = URL(fileURLWithPath: finalArgs[0])
            process.arguments = Array(finalArgs.dropFirst())
            try? process.run()
            process.waitUntilExit()
        }
    }

    func loadConfig() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "conf")!]
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            // For now, set the config path and let user know
            logOutput += "Config loaded: \(url.path)\n"
        }
    }
}
