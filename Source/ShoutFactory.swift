import UIKit

let shoutView = ShoutView()

public class ShoutView: UIView {

  public struct Dimensions {
    public static var indicatorHeight: CGFloat = 0
    public static var indicatorWidth: CGFloat = 0
    public static var imageSize: CGFloat = 20
    public static var imageOffset: CGFloat = 16
    public static var height: CGFloat = UIApplication.sharedApplication().statusBarHidden ? 47 : 57
    public static var textOffset: CGFloat = 53
  }

  public private(set) lazy var backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.background
    view.alpha = 0.98
    view.clipsToBounds = true
    view.layer.cornerRadius = 10

    return view
    }()

  public private(set) lazy var gestureContainer: UIView = {
    let view = UIView()
    view.userInteractionEnabled = true

    return view
    }()

  public private(set) lazy var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.dragIndicator
    view.layer.cornerRadius = Dimensions.indicatorHeight / 2
    view.userInteractionEnabled = true

    return view
    }()
    
    public private(set) lazy var wrapperView: UIView = {
        let wrapperView = UIView()
        return wrapperView
    }()

  public private(set) lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.clipsToBounds = true
    imageView.contentMode = .ScaleAspectFit

    return imageView
    }()

  public private(set) lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.title
    label.textColor = ColorList.Shout.title
    label.numberOfLines = 2

    return label
    }()

  public private(set) lazy var subtitleLabel: UILabel = {
    let label = UILabel()
    label.font = FontList.Shout.subtitle
    label.textColor = ColorList.Shout.subtitle
    label.numberOfLines = 2

    return label
    }()

  public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))

    return gesture
    }()

  public private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
    let gesture = UIPanGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handlePanGestureRecognizer))

    return gesture
    }()

  public private(set) var announcement: Announcement?
  public private(set) var displayTimer = NSTimer()
  public private(set) var panGestureActive = false
  public private(set) var shouldSilent = false
  public private(set) var completion: (() -> ())?

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundView)
    [indicatorView, wrapperView, gestureContainer].forEach {
      backgroundView.addSubview($0) }
    
    [imageView, titleLabel, subtitleLabel].forEach {
        wrapperView.addSubview($0)
    }

    clipsToBounds = false
    userInteractionEnabled = true
    layer.shadowColor = UIColor.blackColor().CGColor
    layer.shadowOffset = CGSize(width: 0, height: 0.5)
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 0.5

    addGestureRecognizer(tapGestureRecognizer)
    gestureContainer.addGestureRecognizer(panGestureRecognizer)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ShoutView.orientationDidChange), name: UIDeviceOrientationDidChangeNotification, object: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: nil)
  }

  // MARK: - Configuration

  public func craft(announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
    Dimensions.height = UIApplication.sharedApplication().statusBarHidden ? 47 : 57

    panGestureActive = false
    shouldSilent = false
    configureView(announcement)
    shout(to: to)

    self.completion = completion
  }

  public func configureView(announcement: Announcement) {
    self.announcement = announcement
    imageView.image = announcement.image
    titleLabel.text = announcement.title
    subtitleLabel.text = announcement.subtitle

    displayTimer.invalidate()
    displayTimer = NSTimer.scheduledTimerWithTimeInterval(announcement.duration,
      target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)

    setupFrames()
  }

  public func shout(to controller: UIViewController) {
    let width = UIScreen.mainScreen().bounds.width - 20
    controller.view.addSubview(self)
    
    backgroundView.alpha = 0
    
    frame = CGRect(x: 5, y: 0, width: width, height: Dimensions.height)
    backgroundView.frame = CGRect(x: 5, y: 0, width: width, height: Dimensions.height)

    UIView.animateWithDuration(0.35, animations: {
      self.backgroundView.alpha = 1
    })
  }

  // MARK: - Setup

  public func setupFrames() {
    let totalWidth = UIScreen.mainScreen().bounds.width - 20
    let offset: CGFloat = UIApplication.sharedApplication().statusBarHidden ? 2.5 : 5
//    let textOffsetX: CGFloat = imageView.image != nil ? Dimensions.textOffset : 18
    let imageSize: CGFloat = imageView.image != nil ? Dimensions.imageSize : 0
    let distanceFromImageToText: CGFloat = 10

    backgroundView.frame.size = CGSize(width: totalWidth, height: Dimensions.height)
    gestureContainer.frame = CGRect(x: 0, y: Dimensions.height - 20, width: totalWidth, height: 20)
    indicatorView.frame = CGRect(x: (totalWidth - Dimensions.indicatorWidth) / 2,
      y: Dimensions.height - Dimensions.indicatorHeight - 5, width: Dimensions.indicatorWidth, height: Dimensions.indicatorHeight)
    
    [titleLabel, subtitleLabel].forEach {
        $0.frame.size.width = totalWidth - distanceFromImageToText - imageSize
        $0.sizeToFit()
    }

    let textOffsetX: CGFloat = imageSize + distanceFromImageToText
    let wrapperViewWidth: CGFloat = titleLabel.frame.size.width + imageSize + distanceFromImageToText
    wrapperView.frame = CGRect(x: (totalWidth - wrapperViewWidth) / 2, y: (Dimensions.height - imageSize) / 2, width: wrapperViewWidth, height: imageSize)
    
    imageView.frame = CGRect(x: 0, y: 0, width: imageSize, height: imageSize)

    titleLabel.frame.origin = CGPoint(x: textOffsetX, y: 0)
    subtitleLabel.frame.origin = CGPoint(x: textOffsetX, y: CGRectGetMaxY(titleLabel.frame) + 2.5)

    if subtitleLabel.text?.isEmpty ?? true {
      titleLabel.center.y = imageView.center.y
    }
  }

  // MARK: - Actions

  public func silent() {
    UIView.animateWithDuration(0.35, animations: {
        self.backgroundView.alpha = 0
      }, completion: { finished in
        self.completion?()
        self.displayTimer.invalidate()
        self.removeFromSuperview()
    })
  }

  // MARK: - Timer methods

  public func displayTimerDidFire() {
    shouldSilent = true

    if panGestureActive { return }
    silent()
  }

  // MARK: - Gesture methods

  @objc private func handleTapGestureRecognizer() {
    guard let announcement = announcement else { return }
    announcement.action?()
    silent()
  }

  @objc private func handlePanGestureRecognizer() {
    let translation = panGestureRecognizer.translationInView(self)
    var duration: NSTimeInterval = 0

    if panGestureRecognizer.state == .Changed || panGestureRecognizer.state == .Began {
      panGestureActive = true
      if translation.y >= 12 {
        frame.size.height = Dimensions.height + 12 + (translation.y) / 25
      } else {
        frame.size.height = Dimensions.height + translation.y
      }
    } else {
      panGestureActive = false
      let height = translation.y < -5 || shouldSilent ? 0 : Dimensions.height

      duration = 0.2
      UIView.animateWithDuration(duration, animations: {
        self.frame.size.height = height
        }, completion: { _ in if translation.y < -5 { self.completion?(); self.removeFromSuperview() }})
    }

    UIView.animateWithDuration(duration, animations: {
      self.backgroundView.frame.size.height = self.frame.height
      self.gestureContainer.frame.origin.y = self.frame.height - 20
      self.indicatorView.frame.origin.y = self.frame.height - Dimensions.indicatorHeight - 5
    })
  }


  // MARK: - Handling screen orientation

  func orientationDidChange() {
    setupFrames()
  }
}
