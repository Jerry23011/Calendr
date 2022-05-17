//
//  EventView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import Cocoa
import RxSwift
import RxCocoa
import CoreImage.CIFilterBuiltins

class EventView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventViewModel

    private let icon = NSImageView()
    private let title = Label()
    private let subtitle = Label()
    private let duration = Label()
    private let progress = NSView()
    private let linkBtn = NSButton()
    private let hoverLayer = CALayer()

    private lazy var progressTop = progress.top(equalTo: self)

    init(viewModel: EventViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()

        setData()
    }

    private func setData() {

        switch viewModel.type {

        case .birthday:
            icon.image = Icons.Event.birthday.with(scale: .small)
            icon.contentTintColor = .systemRed

        case .reminder:
            icon.image = Icons.Event.reminder.with(scale: .small).with(size: 9)
            icon.contentTintColor = .headerTextColor

        case .event:
            icon.isHidden = true
        }

        title.stringValue = viewModel.title

        subtitle.stringValue = viewModel.subtitle
        subtitle.isHidden = subtitle.isEmpty

        duration.stringValue = viewModel.duration
        duration.isHidden = duration.isEmpty

        linkBtn.isHidden = viewModel.linkURL == nil

        if viewModel.isPending {
            layer?.backgroundColor = Self.pendingBackground
        }
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        layer?.cornerRadius = 2

        hoverLayer.isHidden = true
        hoverLayer.backgroundColor = NSColor.gray.cgColor.copy(alpha: 0.2)
        layer?.addSublayer(hoverLayer)

        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)

        title.forceVibrancy = false
        title.lineBreakMode = .byWordWrapping
        title.textColor = .headerTextColor
        title.font = .systemFont(ofSize: 12)

        duration.lineBreakMode = .byWordWrapping
        duration.textColor = .secondaryLabelColor
        duration.font = .systemFont(ofSize: 11)

        subtitle.lineBreakMode = .byTruncatingTail
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 11)

        let colorBar = NSView()
        colorBar.wantsLayer = true
        colorBar.layer?.backgroundColor = viewModel.color.cgColor
        colorBar.layer?.cornerRadius = 2
        colorBar.width(equalTo: 4)

        linkBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        linkBtn.refusesFirstResponder = true
        linkBtn.bezelStyle = .roundRect
        linkBtn.isBordered = false
        linkBtn.width(equalTo: 22)

        let titleStackView = NSStackView(views: [icon, title]).with(spacing: 4).with(alignment: .firstBaseline)

        let subtitleStackView = NSStackView(views: [subtitle, linkBtn]).with(spacing: 0)

        subtitleStackView.rx.isContentHidden
            .bind(to: subtitleStackView.rx.isHidden)
            .disposed(by: disposeBag)

        let eventStackView = NSStackView(views: [titleStackView, subtitleStackView, duration])
            .with(orientation: .vertical)
            .with(spacing: 2)
            .with(insets: .init(vertical: 1))

        let contentStackView = NSStackView(views: [colorBar, eventStackView])
        addSubview(contentStackView)
        contentStackView.edges(to: self)

        addSubview(progress, positioned: .below, relativeTo: nil)

        progress.isHidden = true
        progress.wantsLayer = true
        progress.layer?.backgroundColor = NSColor.red.cgColor.copy(alpha: 0.7)
        progress.height(equalTo: 1)
        progress.width(equalTo: self)
    }

    private func setUpBindings() {

        rx.isHovered
            .map(!)
            .bind(to: hoverLayer.rx.isHidden)
            .disposed(by: disposeBag)

        if let url = viewModel.linkURL {
            (
                viewModel.isMeeting
                    ? viewModel.isInProgress.map { $0 ? Icons.Event.video_fill : Icons.Event.video }
                    : .just(Icons.Event.link)
            )
            .map { $0.with(scale: .small) }
            .bind(to: linkBtn.rx.image)
            .disposed(by: disposeBag)

            viewModel.isInProgress.map { $0 ? .controlAccentColor : .secondaryLabelColor }
                .bind(to: linkBtn.rx.contentTintColor)
                .disposed(by: disposeBag)

            linkBtn.rx.tap
                .bind { [viewModel] in viewModel.workspace.open(url) }
                .disposed(by: disposeBag)
        }

        if viewModel.type.isEvent {

            viewModel.isFaded
                .map { $0 ? 0.5 : 1 }
                .bind(to: rx.alpha)
                .disposed(by: disposeBag)

            Observable.combineLatest(
                viewModel.progress, rx.observe(\.frame)
            )
            .compactMap { progress, frame in
                progress.map { max(1, $0 * frame.height - 0.5) }
            }
            .bind(to: progressTop.rx.constant)
            .disposed(by: disposeBag)

            viewModel.isInProgress
                .map(!)
                .bind(to: progress.rx.isHidden)
                .disposed(by: disposeBag)
        }

        viewModel.backgroundColor
            .map(\.cgColor)
            .bind(to: layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        rx.click {
            // do not delay other click events
            $0.delaysPrimaryMouseButtonEvents = false
        }
        .map(viewModel.makeDetails)
        .withUnretained(self)
        .flatMapFirst { view, viewModel -> Observable<Void> in
            let vc = EventDetailsViewController(viewModel: viewModel)
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentViewController = vc
            popover.delegate = vc
            popover.show(relativeTo: .zero, of: view, preferredEdge: .minX)
            return popover.rx.deallocated
        }
        .bind { [weak self] in
            // 🔨 Allow clicking outside to dismiss the main view after dismissing the event details
            self?.window?.makeKey()
        }
        .disposed(by: disposeBag)

        rx.observe(\.frame)
            .bind { [weak self] _ in self?.updateLayer() }
            .disposed(by: disposeBag)
    }

    override func updateLayer() {
        super.updateLayer()
        hoverLayer.frame = bounds
    }

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea(_:))
        addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)

        // 🔨 Fix unhover not detected when scrolling
        guard let mouseLocation = window?.mouseLocationOutsideOfEventStream,
              isMousePoint(convert(mouseLocation, from: nil), in: bounds)
        else {
            return hoverLayer.isHidden = true
        }
    }

    private static let pendingBackground: CGColor = {

        let stripes = CIFilter.stripesGenerator()
        stripes.color0 = CIColor(color: NSColor.gray.withAlphaComponent(0.25))!
        stripes.color1 = .clear
        stripes.width = 2.5
        stripes.sharpness = 0

        let rotated = CIFilter.affineClamp()
        rotated.inputImage = stripes.outputImage!
        rotated.transform = CGAffineTransform(rotationAngle: -.pi / 4)

        let ciImage = rotated.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return NSColor(patternImage: nsImage).cgColor
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
